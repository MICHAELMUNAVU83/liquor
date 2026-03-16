defmodule Liquor.Cart do
  @moduledoc """
  Cart context.

  The cart is primarily localStorage-driven on the client.
  This module provides server-side helpers:
    - resolving variant details from IDs (for cart page rendering)
    - DB persistence for logged-in users
  """

  import Ecto.Query
  alias Liquor.Repo
  alias Liquor.Cart.{Cart, CartItem}
  alias Liquor.Catalog.ProductVariant

  # ---------------------------------------------------------------------------
  # Resolve localStorage items against DB
  # ---------------------------------------------------------------------------

  @doc """
  Given a list of maps with "variant_id" and "quantity" keys
  (as sent from the client via the CartSync hook), loads full
  product details from the DB and returns a list of cart item maps.

  Items whose variant_id no longer exists are silently dropped.
  """
  def resolve_items(raw_items) when is_list(raw_items) do
    ids = raw_items |> Enum.map(&(&1["variant_id"])) |> Enum.reject(&is_nil/1)

    variants =
      from(v in ProductVariant,
        where: v.id in ^ids,
        preload: [product: :variants]
      )
      |> Repo.all()

    variant_map = Map.new(variants, &{&1.id, &1})

    raw_items
    |> Enum.flat_map(fn raw ->
      vid = raw["variant_id"]
      qty = max(raw["quantity"] || 1, 1)

      case Map.get(variant_map, vid) do
        nil -> []
        v ->
          # Build sibling variant list for the size switcher on the cart page
          all_variants =
            v.product.variants
            |> Enum.sort_by(& &1.size)
            |> Enum.map(&%{id: &1.id, size: &1.size, price: &1.price, in_stock: &1.stock_quantity > 0})

          [%{
            variant_id:   v.id,
            product_id:   v.product.id,
            quantity:     qty,
            product_name: v.product.name,
            image_url:    v.product.image_url,
            size:         v.size,
            sku:          v.sku,
            price:        v.price,
            compare_price: v.compare_price,
            stock_qty:    v.stock_quantity,
            in_stock:     v.stock_quantity > 0,
            all_variants: all_variants
          }]
      end
    end)
  end

  def resolve_items(_), do: []

  # ---------------------------------------------------------------------------
  # Totals
  # ---------------------------------------------------------------------------

  def subtotal(items) do
    Enum.reduce(items, Decimal.new("0"), fn item, acc ->
      Decimal.add(acc, Decimal.mult(item.price, Decimal.new(item.quantity)))
    end)
  end

  def shipping_cost(subtotal) do
    threshold = Decimal.new(Liquor.StoreConfig.free_ship_threshold())
    cost      = Decimal.new(Liquor.StoreConfig.shipping_cost())
    if Decimal.compare(subtotal, threshold) in [:gt, :eq], do: Decimal.new("0"), else: cost
  end

  def total(items) do
    sub = subtotal(items)
    ship = shipping_cost(sub)
    Decimal.add(sub, ship)
  end

  # ---------------------------------------------------------------------------
  # DB persistence (for logged-in users)
  # ---------------------------------------------------------------------------

  def get_or_create_cart(session_id) do
    case Repo.get_by(Cart, session_id: session_id) do
      nil ->
        %Cart{} |> Cart.changeset(%{session_id: session_id}) |> Repo.insert!()
      cart ->
        cart
    end
  end

  def sync_to_db(session_id, raw_items) do
    cart  = get_or_create_cart(session_id)
    Repo.delete_all(from ci in CartItem, where: ci.cart_id == ^cart.id)

    for item <- raw_items, not is_nil(item["variant_id"]) do
      %CartItem{}
      |> CartItem.changeset(%{
        cart_id:            cart.id,
        product_variant_id: item["variant_id"],
        quantity:           max(item["quantity"] || 1, 1)
      })
      |> Repo.insert(on_conflict: :replace_all, conflict_target: [:cart_id, :product_variant_id])
    end

    :ok
  end
end

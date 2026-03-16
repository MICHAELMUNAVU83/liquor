defmodule Liquor.Catalog do
  @moduledoc "Catalog context – products, categories, brands, variants."

  import Ecto.Query
  alias Liquor.Repo
  alias Liquor.Catalog.{Category, Brand, Product, ProductVariant}

  # ---------------------------------------------------------------------------
  # Categories
  # ---------------------------------------------------------------------------

  def list_categories, do: Repo.all(from c in Category, order_by: [asc: c.position, asc: c.name])

  def get_category!(id), do: Repo.get!(Category, id)
  def get_category_by_slug!(slug), do: Repo.get_by!(Category, slug: slug)

  def create_category(attrs), do: %Category{} |> Category.changeset(attrs) |> Repo.insert()
  def update_category(%Category{} = c, attrs), do: c |> Category.changeset(attrs) |> Repo.update()
  def delete_category(%Category{} = c), do: Repo.delete(c)
  def change_category(%Category{} = c, attrs \\ %{}), do: Category.changeset(c, attrs)

  # ---------------------------------------------------------------------------
  # Brands
  # ---------------------------------------------------------------------------

  def list_brands, do: Repo.all(from b in Brand, order_by: b.name)

  def get_brand!(id), do: Repo.get!(Brand, id)

  def create_brand(attrs), do: %Brand{} |> Brand.changeset(attrs) |> Repo.insert()
  def update_brand(%Brand{} = b, attrs), do: b |> Brand.changeset(attrs) |> Repo.update()
  def delete_brand(%Brand{} = b), do: Repo.delete(b)
  def change_brand(%Brand{} = b, attrs \\ %{}), do: Brand.changeset(b, attrs)

  # ---------------------------------------------------------------------------
  # Products
  # ---------------------------------------------------------------------------

  def list_products(opts \\ []) do
    base_query =
      from p in Product,
        preload: [:category, :brand, :variants],
        order_by: [desc: p.inserted_at]

    base_query
    |> maybe_filter_category(opts[:category_id])
    |> maybe_filter_active(opts[:active])
    |> maybe_filter_featured(opts[:featured])
    |> maybe_search(opts[:search])
    |> Repo.all()
  end

  defp maybe_filter_category(q, nil), do: q
  defp maybe_filter_category(q, id),  do: where(q, [p], p.category_id == ^id)

  defp maybe_filter_active(q, nil),   do: q
  defp maybe_filter_active(q, val),   do: where(q, [p], p.is_active == ^val)

  defp maybe_filter_featured(q, nil), do: q
  defp maybe_filter_featured(q, val), do: where(q, [p], p.is_featured == ^val)

  defp maybe_search(q, nil),    do: q
  defp maybe_search(q, ""),     do: q
  defp maybe_search(q, search) do
    term = "%#{search}%"
    where(q, [p], ilike(p.name, ^term) or ilike(p.description, ^term))
  end

  def get_product!(id), do: Repo.get!(Product, id) |> Repo.preload([:category, :brand, :variants])
  def get_product_by_slug!(slug) do
    Repo.get_by!(Product, slug: slug) |> Repo.preload([:category, :brand, :variants, :reviews])
  end

  def create_product(attrs) do
    %Product{} |> Product.changeset(attrs) |> Repo.insert()
  end

  def update_product(%Product{} = p, attrs), do: p |> Product.changeset(attrs) |> Repo.update()
  def delete_product(%Product{} = p), do: Repo.delete(p)
  def change_product(%Product{} = p, attrs \\ %{}), do: Product.changeset(p, attrs)

  # ---------------------------------------------------------------------------
  # Product Variants
  # ---------------------------------------------------------------------------

  def list_variants_for(product_id) do
    Repo.all(from v in ProductVariant, where: v.product_id == ^product_id, order_by: v.price)
  end

  def get_variant!(id), do: Repo.get!(ProductVariant, id)

  def list_default_variants_for_products do
    Repo.all(
      from v in ProductVariant,
        where: v.is_default == true,
        join: p in assoc(v, :product),
        where: p.is_active == true,
        preload: [product: p],
        order_by: [asc: p.name]
    )
  end

  def create_variant(attrs), do: %ProductVariant{} |> ProductVariant.changeset(attrs) |> Repo.insert()
  def update_variant(%ProductVariant{} = v, attrs), do: v |> ProductVariant.changeset(attrs) |> Repo.update()
  def delete_variant(%ProductVariant{} = v), do: Repo.delete(v)
  def change_variant(%ProductVariant{} = v, attrs \\ %{}), do: ProductVariant.changeset(v, attrs)

  def decrement_stock(%ProductVariant{} = v, qty) do
    Repo.update_all(
      from(pv in ProductVariant, where: pv.id == ^v.id and pv.stock_quantity >= ^qty),
      inc: [stock_quantity: -qty]
    )
  end

  # ---------------------------------------------------------------------------
  # Stats helpers used by admin dashboard
  # ---------------------------------------------------------------------------

  def list_unique_sizes do
    Repo.all(from v in ProductVariant, select: v.size, distinct: true, order_by: v.size)
    |> Enum.reject(&is_nil/1)
  end

  def count_products, do: Repo.aggregate(Product, :count)
  def count_categories, do: Repo.aggregate(Category, :count)
  def count_brands, do: Repo.aggregate(Brand, :count)

  def low_stock_variants(threshold \\ 5) do
    Repo.all(
      from v in ProductVariant,
        where: v.stock_quantity <= ^threshold,
        preload: :product,
        order_by: v.stock_quantity
    )
  end

  def list_all_variants(opts \\ []) do
    base =
      from v in ProductVariant,
        join: p in assoc(v, :product),
        preload: [product: p],
        order_by: [asc: p.name, asc: v.size]

    base
    |> maybe_inventory_search(opts[:search])
    |> maybe_low_stock_only(opts[:low_stock])
    |> Repo.all()
  end

  defp maybe_inventory_search(q, nil), do: q
  defp maybe_inventory_search(q, ""),  do: q
  defp maybe_inventory_search(q, term) do
    t = "%#{term}%"
    where(q, [v, p], ilike(p.name, ^t) or ilike(v.sku, ^t))
  end

  defp maybe_low_stock_only(q, true),  do: where(q, [v], v.stock_quantity <= 5)
  defp maybe_low_stock_only(q, _),     do: q

  def adjust_stock(%ProductVariant{} = v, qty) do
    new_qty = max(0, v.stock_quantity + qty)
    update_variant(v, %{stock_quantity: new_qty})
  end

  def total_stock_value do
    Repo.one(
      from v in ProductVariant,
        select: coalesce(sum(fragment("? * ?", v.stock_quantity, v.price)), ^Decimal.new("0"))
    )
  end
end

defmodule Liquor.Orders do
  @moduledoc "Orders context – orders, order items, reviews."

  import Ecto.Query
  alias Liquor.Repo
  alias Liquor.Orders.{Order, OrderItem, Review}

  # ---------------------------------------------------------------------------
  # Orders
  # ---------------------------------------------------------------------------

  def list_orders(opts \\ []) do
    from(o in Order,
      preload: [:user, :items],
      order_by: [desc: o.inserted_at]
    )
    |> maybe_filter_status(opts[:status])
    |> Repo.all()
  end

  defp maybe_filter_status(q, nil), do: q
  defp maybe_filter_status(q, ""),  do: q
  defp maybe_filter_status(q, s),   do: where(q, [o], o.status == ^s)

  def get_order!(id) do
    Repo.get!(Order, id) |> Repo.preload([:user, items: :product_variant])
  end

  def create_order(attrs) do
    %Order{} |> Order.changeset(attrs) |> Repo.insert()
  end

  def update_order(%Order{} = o, attrs), do: o |> Order.changeset(attrs) |> Repo.update()

  def count_orders, do: Repo.aggregate(Order, :count)

  def total_revenue do
    Repo.one(
      from o in Order,
        where: o.payment_status == "paid",
        select: coalesce(sum(o.total_amount), ^Decimal.new("0"))
    )
  end

  def recent_orders(limit \\ 10) do
    Repo.all(
      from o in Order,
        preload: [:user],
        order_by: [desc: o.inserted_at],
        limit: ^limit
    )
  end

  def orders_by_status do
    Repo.all(
      from o in Order,
        group_by: o.status,
        select: {o.status, count(o.id)}
    )
    |> Map.new()
  end

  def count_paid_orders do
    Repo.aggregate(from(o in Order, where: o.payment_status == "paid"), :count)
  end

  def revenue_this_month do
    start = Date.beginning_of_month(Date.utc_today()) |> DateTime.new!(~T[00:00:00], "Etc/UTC")
    Repo.one(
      from o in Order,
        where: o.payment_status == "paid" and o.inserted_at >= ^start,
        select: coalesce(sum(o.total_amount), ^Decimal.new("0"))
    )
  end

  def revenue_today do
    start = Date.utc_today() |> DateTime.new!(~T[00:00:00], "Etc/UTC")
    Repo.one(
      from o in Order,
        where: o.payment_status == "paid" and o.inserted_at >= ^start,
        select: coalesce(sum(o.total_amount), ^Decimal.new("0"))
    )
  end

  def monthly_revenue_last_6 do
    today = Date.utc_today()
    six_months_ago =
      Date.add(Date.beginning_of_month(today), -150)
      |> DateTime.new!(~T[00:00:00], "Etc/UTC")

    rows =
      Repo.all(
        from o in Order,
          where: o.payment_status == "paid" and o.inserted_at >= ^six_months_ago,
          group_by: [fragment("date_trunc('month', ?)", o.inserted_at)],
          select: {fragment("date_trunc('month', ?)", o.inserted_at), sum(o.total_amount)},
          order_by: [asc: fragment("date_trunc('month', ?)", o.inserted_at)]
      )

    Enum.map(rows, fn {dt, total} ->
      %{month: Calendar.strftime(dt, "%b %Y"), revenue: total || Decimal.new("0")}
    end)
  end

  def top_products(limit \\ 5) do
    Repo.all(
      from i in OrderItem,
        join: o in assoc(i, :order),
        where: o.payment_status == "paid",
        group_by: i.product_name,
        select: {i.product_name, sum(i.quantity), sum(i.subtotal)},
        order_by: [desc: sum(i.subtotal)],
        limit: ^limit
    )
    |> Enum.map(fn {name, qty, revenue} ->
      %{name: name, qty: qty, revenue: revenue || Decimal.new("0")}
    end)
  end

  def create_sale(attrs) do
    Repo.transaction(fn ->
      with {:ok, order} <- create_order(Map.merge(attrs, %{payment_status: "paid", status: "delivered"})) do
        order
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  # ---------------------------------------------------------------------------
  # Order Items
  # ---------------------------------------------------------------------------

  def get_order_by_reference(reference) do
    case Repo.get_by(Order, payment_reference: reference) do
      nil   -> nil
      order -> Repo.preload(order, [:items])
    end
  end

  def create_order_with_items(order_attrs, cart_items) do
    Repo.transaction(fn ->
      case create_order(order_attrs) do
        {:ok, order} ->
          Enum.each(cart_items, fn item ->
            subtotal = Decimal.mult(item.price, Decimal.new(item.quantity))
            case create_order_item(%{
              order_id:           order.id,
              product_variant_id: item.variant_id,
              product_name:       item.product_name,
              variant_sku:        item.sku,
              variant_size:       item.size,
              quantity:           item.quantity,
              unit_price:         item.price,
              subtotal:           subtotal
            }) do
              {:ok, _}     -> :ok
              {:error, cs} -> Repo.rollback(cs)
            end
          end)
          Repo.preload(order, [:items])
        {:error, cs} ->
          Repo.rollback(cs)
      end
    end)
  end

  def create_order_item(attrs) do
    %OrderItem{} |> OrderItem.changeset(attrs) |> Repo.insert()
  end

  # ---------------------------------------------------------------------------
  # Reviews
  # ---------------------------------------------------------------------------

  def list_reviews_for(product_id) do
    Repo.all(
      from r in Review,
        where: r.product_id == ^product_id,
        preload: :user,
        order_by: [desc: r.inserted_at]
    )
  end

  def create_review(attrs), do: %Review{} |> Review.changeset(attrs) |> Repo.insert()

  def avg_rating(product_id) do
    Repo.one(
      from r in Review,
        where: r.product_id == ^product_id,
        select: avg(r.rating)
    )
  end
end

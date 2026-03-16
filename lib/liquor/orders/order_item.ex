defmodule Liquor.Orders.OrderItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "order_items" do
    field :product_name,  :string
    field :variant_sku,   :string
    field :variant_size,  :string
    field :quantity,      :integer
    field :unit_price,    :decimal
    field :subtotal,      :decimal

    belongs_to :order,           Liquor.Orders.Order
    belongs_to :product_variant, Liquor.Catalog.ProductVariant

    timestamps()
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:order_id, :product_variant_id, :product_name,
                    :variant_sku, :variant_size, :quantity, :unit_price, :subtotal])
    |> validate_required([:product_name, :quantity, :unit_price, :subtotal])
    |> validate_number(:quantity, greater_than: 0)
  end
end

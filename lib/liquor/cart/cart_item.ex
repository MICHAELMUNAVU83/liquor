defmodule Liquor.Cart.CartItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cart_items" do
    field :quantity, :integer, default: 1

    belongs_to :cart,            Liquor.Cart.Cart
    belongs_to :product_variant, Liquor.Catalog.ProductVariant

    timestamps()
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:cart_id, :product_variant_id, :quantity])
    |> validate_required([:cart_id, :product_variant_id, :quantity])
    |> validate_number(:quantity, greater_than: 0)
    |> unique_constraint([:cart_id, :product_variant_id])
  end
end

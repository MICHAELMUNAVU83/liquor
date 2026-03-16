defmodule Liquor.Catalog.ProductVariant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "product_variants" do
    field :sku,            :string
    field :size,           :string
    field :abv,            :decimal
    field :price,          :decimal
    field :compare_price,  :decimal
    field :stock_quantity, :integer, default: 0
    field :is_default,     :boolean, default: false

    belongs_to :product, Liquor.Catalog.Product

    timestamps()
  end

  def changeset(variant, attrs) do
    variant
    |> cast(attrs, [:sku, :size, :abv, :price, :compare_price,
                    :stock_quantity, :is_default, :product_id])
    |> validate_required([:size, :price, :product_id])
    |> maybe_generate_sku()
    |> validate_required([:sku])
    |> unique_constraint(:sku)
    |> validate_number(:price,          greater_than: 0)
    |> validate_number(:stock_quantity, greater_than_or_equal_to: 0)
    |> assoc_constraint(:product)
  end

  defp maybe_generate_sku(cs) do
    if get_field(cs, :sku) do
      cs
    else
      product_id = get_field(cs, :product_id) || "0"
      size       = get_field(cs, :size) || "STD"
      sku        = "PRD-#{product_id}-#{String.upcase(size)}-#{:rand.uniform(9999)}"
      put_change(cs, :sku, sku)
    end
  end
end

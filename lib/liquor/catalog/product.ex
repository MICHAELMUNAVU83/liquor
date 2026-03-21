defmodule Liquor.Catalog.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :name,        :string
    field :slug,        :string
    field :description, :string
    field :badge,       :string   # "best_seller" | "limited_edition" | nil
    field :image_url,   :string
    field :is_featured, :boolean, default: false
    field :is_active,   :boolean, default: true
    field :year,        :integer

    belongs_to :category, Liquor.Catalog.Category
    belongs_to :brand,    Liquor.Catalog.Brand
    has_many   :variants, Liquor.Catalog.ProductVariant, on_delete: :delete_all
    has_many   :reviews,  Liquor.Orders.Review

    timestamps()
  end

  @valid_badges ~w(best_seller limited_edition)

  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :slug, :description, :badge, :image_url,
                    :is_featured, :is_active, :year, :category_id, :brand_id])
    |> validate_required([:name, :category_id])
    |> maybe_generate_slug()
    |> validate_required([:slug])
    |> unique_constraint(:slug)
    |> validate_inclusion(:badge, @valid_badges ++ [nil])
    |> assoc_constraint(:category)
    |> assoc_constraint(:brand)
  end

  defp maybe_generate_slug(%Ecto.Changeset{} = cs) do
    existing = get_field(cs, :slug)
    if existing && existing != "" do
      cs
    else
      case get_change(cs, :name) do
        nil  -> cs
        name -> put_change(cs, :slug, slugify(name))
      end
    end
  end

  defp slugify(str) do
    str
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.trim("-")
  end
end

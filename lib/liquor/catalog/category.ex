defmodule Liquor.Catalog.Category do
  use Ecto.Schema
  import Ecto.Changeset

  schema "categories" do
    field :name,        :string
    field :slug,        :string
    field :description, :string
    field :image_url,   :string
    field :position,    :integer, default: 0

    has_many :products, Liquor.Catalog.Product

    timestamps()
  end

  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :slug, :description, :image_url, :position])
    |> validate_required([:name])
    |> maybe_generate_slug()
    |> validate_required([:slug])
    |> unique_constraint(:slug)
  end

  defp maybe_generate_slug(%Ecto.Changeset{} = cs) do
    if get_field(cs, :slug) do
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

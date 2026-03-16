defmodule Liquor.Catalog.Brand do
  use Ecto.Schema
  import Ecto.Changeset

  schema "brands" do
    field :name,        :string
    field :slug,        :string
    field :description, :string
    field :logo_url,    :string
    field :country,     :string

    has_many :products, Liquor.Catalog.Product

    timestamps()
  end

  def changeset(brand, attrs) do
    brand
    |> cast(attrs, [:name, :slug, :description, :logo_url, :country])
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

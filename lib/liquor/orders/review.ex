defmodule Liquor.Orders.Review do
  use Ecto.Schema
  import Ecto.Changeset

  schema "reviews" do
    field :rating,      :integer
    field :title,       :string
    field :body,        :string
    field :is_verified, :boolean, default: false

    belongs_to :product, Liquor.Catalog.Product
    belongs_to :user,    Liquor.Accounts.User

    timestamps()
  end

  def changeset(review, attrs) do
    review
    |> cast(attrs, [:product_id, :user_id, :rating, :title, :body, :is_verified])
    |> validate_required([:product_id, :rating])
    |> validate_inclusion(:rating, 1..5)
    |> unique_constraint([:product_id, :user_id])
  end
end

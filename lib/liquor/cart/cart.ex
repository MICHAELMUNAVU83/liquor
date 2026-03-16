defmodule Liquor.Cart.Cart do
  use Ecto.Schema
  import Ecto.Changeset

  schema "carts" do
    field :session_id, :string

    belongs_to :user, Liquor.Accounts.User
    has_many   :cart_items, Liquor.Cart.CartItem

    timestamps()
  end

  def changeset(cart, attrs) do
    cart
    |> cast(attrs, [:user_id, :session_id])
  end
end

defmodule Liquor.Accounts.Address do
  use Ecto.Schema
  import Ecto.Changeset

  schema "addresses" do
    field :label,      :string, default: "Home"
    field :line1,      :string
    field :line2,      :string
    field :city,       :string
    field :state,      :string
    field :zip,        :string
    field :country,    :string, default: "US"
    field :is_default, :boolean, default: false

    belongs_to :user, Liquor.Accounts.User

    timestamps()
  end

  def changeset(address, attrs) do
    address
    |> cast(attrs, [:label, :line1, :line2, :city, :state, :zip, :country, :is_default, :user_id])
    |> validate_required([:line1, :city, :country, :user_id])
  end
end

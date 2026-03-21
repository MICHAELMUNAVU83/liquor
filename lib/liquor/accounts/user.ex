defmodule Liquor.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :first_name, :string
    field :last_name, :string
    field :phone, :string
    field :is_admin, :boolean, default: false
    field :is_active, :boolean, default: true

    has_many :addresses, Liquor.Accounts.Address
    has_many :orders, Liquor.Orders.Order
    has_many :reviews, Liquor.Orders.Review

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :first_name, :last_name, :phone, :is_admin, :is_active])
    |> validate_required([:email, :password])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/)
    |> unique_constraint(:email)
    |> validate_length(:password, min: 6)
    |> hash_password()
  end

  def admin_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :first_name, :last_name, :phone, :is_admin, :is_active])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/)
    |> unique_constraint(:email)
  end

  def customer_changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :email, :phone])
    |> validate_required([:first_name, :last_name])
    |> then(fn cs ->
      if get_field(cs, :email) in [nil, ""],
        do: cs,
        else:
          cs |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/) |> unique_constraint(:email)
    end)
  end

  defp hash_password(%Ecto.Changeset{valid?: true, changes: %{password: pw}} = cs) do
    put_change(cs, :password_hash, :crypto.hash(:sha256, pw) |> Base.encode16(case: :lower))
  end

  defp hash_password(cs), do: cs

  def full_name(%__MODULE__{first_name: f, last_name: l}), do: "#{f} #{l}" |> String.trim()
end

defmodule Liquor.Cash.CashRegister do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cash_registers" do
    field :open_amount,  :decimal
    field :close_amount, :decimal
    field :status,       :string, default: "open"
    field :notes,        :string
    field :opened_at,    :utc_datetime
    field :closed_at,    :utc_datetime

    belongs_to :opened_by, Liquor.Accounts.User, foreign_key: :opened_by_id
    has_many   :expenses,  Liquor.Cash.CashRegisterExpense
    has_many   :orders,    Liquor.Orders.Order

    timestamps()
  end

  def open_changeset(register, attrs) do
    register
    |> cast(attrs, [:open_amount, :notes, :opened_by_id, :opened_at])
    |> validate_required([:open_amount, :opened_at])
    |> validate_number(:open_amount, greater_than_or_equal_to: Decimal.new("0"))
    |> put_change(:status, "open")
  end

  def close_changeset(register, attrs) do
    register
    |> cast(attrs, [:close_amount, :notes, :closed_at])
    |> validate_required([:close_amount, :closed_at])
    |> validate_number(:close_amount, greater_than_or_equal_to: Decimal.new("0"))
    |> put_change(:status, "closed")
  end
end

defmodule Liquor.Cash.CashRegisterExpense do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cash_register_expenses" do
    field :description, :string
    field :amount,      :decimal
    field :notes,       :string

    belongs_to :cash_register, Liquor.Cash.CashRegister

    timestamps()
  end

  def changeset(expense, attrs) do
    expense
    |> cast(attrs, [:cash_register_id, :description, :amount, :notes])
    |> validate_required([:cash_register_id, :description, :amount])
    |> validate_number(:amount, greater_than: Decimal.new("0"))
  end
end

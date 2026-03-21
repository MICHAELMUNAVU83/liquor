defmodule Liquor.Expenses.Expense do
  use Ecto.Schema
  import Ecto.Changeset

  schema "expenses" do
    field :description,  :string
    field :category,     :string, default: "other"
    field :amount,       :decimal
    field :expense_date, :date

    # stock-restock details
    field :product_name, :string
    field :variant_sku,  :string
    field :quantity,     :integer
    field :unit_cost,    :decimal

    field :notes, :string

    timestamps()
  end

  @categories ~w(stock_restock utilities wages rent maintenance other)

  def categories, do: @categories

  def changeset(expense, attrs) do
    expense
    |> cast(attrs, [:description, :category, :amount, :expense_date, :notes,
                    :product_name, :variant_sku, :quantity, :unit_cost])
    |> validate_required([:description, :category, :amount, :expense_date])
    |> validate_inclusion(:category, @categories)
    |> validate_number(:amount, greater_than: Decimal.new("0"))
  end
end

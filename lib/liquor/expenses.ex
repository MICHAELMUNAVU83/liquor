defmodule Liquor.Expenses do
  import Ecto.Query
  alias Liquor.Repo
  alias Liquor.Expenses.Expense

  def list_expenses(opts \\ []) do
    category = Keyword.get(opts, :category, "")
    search   = Keyword.get(opts, :search, "")

    Expense
    |> filter_category(category)
    |> filter_search(search)
    |> order_by([e], desc: e.expense_date, desc: e.inserted_at)
    |> Repo.all()
  end

  defp filter_category(q, ""), do: q
  defp filter_category(q, cat), do: where(q, [e], e.category == ^cat)

  defp filter_search(q, ""), do: q
  defp filter_search(q, term) do
    like = "%#{term}%"
    where(q, [e], ilike(e.description, ^like) or ilike(e.product_name, ^like))
  end

  def get_expense!(id), do: Repo.get!(Expense, id)

  def create_expense(attrs \\ %{}) do
    %Expense{}
    |> Expense.changeset(attrs)
    |> Repo.insert()
  end

  def delete_expense(%Expense{} = expense), do: Repo.delete(expense)

  def total_expenses do
    Repo.aggregate(Expense, :sum, :amount) || Decimal.new("0")
  end

  def expenses_this_month do
    today = Date.utc_today()
    start = Date.beginning_of_month(today)

    Expense
    |> where([e], e.expense_date >= ^start)
    |> Repo.aggregate(:sum, :amount) || Decimal.new("0")
  end

  def total_by_category do
    Expense
    |> group_by([e], e.category)
    |> select([e], {e.category, sum(e.amount)})
    |> Repo.all()
    |> Map.new()
  end
end

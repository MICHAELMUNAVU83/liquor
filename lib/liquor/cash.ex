defmodule Liquor.Cash do
  @moduledoc "Cash register context – daily opening/closing and cash expenses."

  import Ecto.Query
  alias Liquor.Repo
  alias Liquor.Cash.{CashRegister, CashRegisterExpense}

  # ---------------------------------------------------------------------------
  # Registers
  # ---------------------------------------------------------------------------

  def list_registers do
    from(r in CashRegister,
      order_by: [desc: r.opened_at],
      preload: [:opened_by, :expenses]
    )
    |> Repo.all()
    |> Enum.map(&put_sales_total/1)
  end

  def get_register!(id) do
    alias Liquor.Orders.Order

    CashRegister
    |> Repo.get!(id)
    |> Repo.preload([
      :opened_by,
      :expenses,
      orders: from(o in Order, where: o.payment_status == "paid", order_by: [asc: o.inserted_at])
    ])
    |> put_sales_total()
  end

  def get_active_register do
    Repo.get_by(CashRegister, status: "open")
  end

  def open_register(attrs, user_id) do
    if get_active_register() do
      {:error, :already_open}
    else
      %CashRegister{}
      |> CashRegister.open_changeset(
        Map.merge(attrs, %{
          "opened_by_id" => user_id,
          "opened_at"    => DateTime.utc_now() |> DateTime.truncate(:second)
        })
      )
      |> Repo.insert()
    end
  end

  def close_register(%CashRegister{} = register, close_amount, notes \\ nil) do
    register
    |> CashRegister.close_changeset(%{
      "close_amount" => close_amount,
      "notes"        => notes,
      "closed_at"    => DateTime.utc_now() |> DateTime.truncate(:second)
    })
    |> Repo.update()
  end

  # ---------------------------------------------------------------------------
  # Cash register expenses
  # ---------------------------------------------------------------------------

  def add_expense(%CashRegister{} = register, attrs) do
    %CashRegisterExpense{}
    |> CashRegisterExpense.changeset(Map.put(attrs, "cash_register_id", register.id))
    |> Repo.insert()
  end

  def delete_expense(%CashRegisterExpense{} = expense), do: Repo.delete(expense)

  def get_expense!(id), do: Repo.get!(CashRegisterExpense, id)

  # ---------------------------------------------------------------------------
  # Summary helpers
  # ---------------------------------------------------------------------------

  defp put_sales_total(%CashRegister{} = register) do
    alias Liquor.Orders.Order

    total =
      from(o in Order,
        where:
          o.cash_register_id == ^register.id and
          o.payment_status == "paid",
        select: coalesce(sum(o.total_amount), ^Decimal.new("0"))
      )
      |> Repo.one()
      |> Kernel.||(Decimal.new("0"))

    Map.put(register, :cash_sales_total, total)
  end

  def summary(%CashRegister{} = r) do
    sales     = Map.get(r, :cash_sales_total, Decimal.new("0"))
    expenses  = r.expenses |> Enum.map(& &1.amount) |> Enum.reduce(Decimal.new("0"), &Decimal.add/2)
    expected  = Decimal.add(r.open_amount, sales) |> Decimal.sub(expenses)

    %{
      open_amount:    r.open_amount,
      cash_sales:     sales,
      total_expenses: expenses,
      expected_close: expected,
      close_amount:   r.close_amount
    }
  end
end

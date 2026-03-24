defmodule LiquorWeb.Admin.ReportController do
  use LiquorWeb, :controller

  alias Liquor.{Orders, Expenses, Catalog, Cash}

  defp format_money(nil), do: "0.00"
  defp format_money(d), do: Decimal.to_string(Decimal.round(d, 2))

  # ── Shared date parsing ────────────────────────────────────────────────────

  defp parse_range(params) do
    today = Date.utc_today()
    from  = parse_date(params["from"], Date.beginning_of_month(today))
    to    = parse_date(params["to"],   today)
    {from, to}
  end

  defp parse_date(str, default) do
    case Date.from_iso8601(str || "") do
      {:ok, d} -> d
      _        -> default
    end
  end

  # ── Sales CSV ──────────────────────────────────────────────────────────────

  def sales(conn, params) do
    {from, to} = parse_range(params)
    orders     = Orders.list_orders_in_range(from, to)

    rows =
      [["Receipt #", "Date", "Time", "Customer", "Payment Method", "Items", "Total (KSh)"]] ++
      Enum.map(orders, fn o ->
        customer = if o.user, do: "#{o.user.first_name} #{o.user.last_name}" |> String.trim(), else: o.shipping_name || "Walk-in"
        items    = o.items |> Enum.map(&"#{&1.quantity}× #{&1.product_name} #{&1.variant_size}") |> Enum.join("; ")
        [
          "##{o.id}",
          Calendar.strftime(o.inserted_at, "%Y-%m-%d"),
          Calendar.strftime(o.inserted_at, "%H:%M"),
          customer,
          o.payment_method || "—",
          items,
          Decimal.to_string(o.total_amount)
        ]
      end)

    csv = to_csv(rows)

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", ~s(attachment; filename="sales_#{from}_#{to}.csv"))
    |> send_resp(200, csv)
  end

  # ── Expenses CSV ───────────────────────────────────────────────────────────

  def expenses(conn, params) do
    {from, to} = parse_range(params)
    expenses   = Expenses.list_expenses_in_range(from, to)

    rows =
      [["Date", "Category", "Description", "Amount (KSh)", "Notes"]] ++
      Enum.map(expenses, fn e ->
        [
          Date.to_string(e.expense_date),
          e.category || "other",
          e.description,
          Decimal.to_string(e.amount),
          e.notes || ""
        ]
      end)

    csv = to_csv(rows)

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", ~s(attachment; filename="expenses_#{from}_#{to}.csv"))
    |> send_resp(200, csv)
  end

  # ── Cash Registry CSV ──────────────────────────────────────────────────────

  def cash(conn, _params) do
    registers = Cash.list_registers()

    rows =
      [["Date Opened", "Date Closed", "Status", "Opened By", "Opening Amount (KSh)", "Cash Sales (KSh)", "Expenses (KSh)", "Expected Close (KSh)", "Actual Close (KSh)"]] ++
      Enum.map(registers, fn r ->
        s = Cash.summary(r)
        [
          Calendar.strftime(r.opened_at, "%Y-%m-%d %H:%M"),
          if(r.closed_at, do: Calendar.strftime(r.closed_at, "%Y-%m-%d %H:%M"), else: "Open"),
          r.status,
          if(r.opened_by, do: "#{r.opened_by.first_name} #{r.opened_by.last_name}", else: "—"),
          Decimal.to_string(s.open_amount),
          Decimal.to_string(s.cash_sales),
          Decimal.to_string(s.total_expenses),
          Decimal.to_string(s.expected_close),
          if(s.close_amount, do: Decimal.to_string(s.close_amount), else: "—")
        ]
      end)

    csv = to_csv(rows)

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", ~s(attachment; filename="cash_registry.csv"))
    |> send_resp(200, csv)
  end

  # ── Stock CSV ──────────────────────────────────────────────────────────────

  def stock(conn, _params) do
    variants = Catalog.list_all_variants()

    rows =
      [["Product", "SKU", "Size", "Stock Qty", "Buying Price (KSh)", "Selling Price (KSh)", "Margin (KSh)", "Margin %", "Stock Value (KSh)", "Stock Cost (KSh)", "Status"]] ++
      Enum.map(variants, fn v ->
        sell_value = Decimal.mult(v.price, Decimal.new(v.stock_quantity))
        {buy_price_str, margin_str, margin_pct_str, cost_value_str} =
          if v.buying_price do
            margin     = Decimal.sub(v.price, v.buying_price)
            margin_pct = Decimal.mult(Decimal.div(margin, v.buying_price), Decimal.new(100))
            cost_val   = Decimal.mult(v.buying_price, Decimal.new(v.stock_quantity))
            {format_money(v.buying_price), format_money(margin), "#{Decimal.round(margin_pct, 1)}%", format_money(cost_val)}
          else
            {"—", "—", "—", "—"}
          end
        status = cond do
          v.stock_quantity == 0   -> "Out of Stock"
          v.stock_quantity <= 5   -> "Low Stock"
          true                    -> "OK"
        end
        [
          v.product.name,
          v.sku || "—",
          v.size || "—",
          v.stock_quantity,
          buy_price_str,
          format_money(v.price),
          margin_str,
          margin_pct_str,
          format_money(sell_value),
          cost_value_str,
          status
        ]
      end)

    csv = to_csv(rows)

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", ~s(attachment; filename="stock_report.csv"))
    |> send_resp(200, csv)
  end

  # ── Purchases CSV ──────────────────────────────────────────────────────────

  def purchases(conn, params) do
    {from, to} = parse_range(params)
    purchases   = Expenses.list_stock_purchases_in_range(from, to)
    total_cost  = Expenses.total_stock_purchases_in_range(from, to)
    total_rev   = Orders.revenue_in_range(from, to)
    gross_profit = Decimal.sub(total_rev, total_cost)

    rows =
      [["Date", "Product", "SKU", "Qty", "Unit Cost (KSh)", "Total Cost (KSh)", "Notes"]] ++
      Enum.map(purchases, fn p ->
        [
          Date.to_string(p.expense_date),
          p.product_name || p.description,
          p.variant_sku || "—",
          p.quantity || "—",
          if(p.unit_cost, do: format_money(p.unit_cost), else: "—"),
          format_money(p.amount),
          p.notes || ""
        ]
      end) ++
      [
        [],
        ["", "TOTAL PURCHASE COST", "", "", "", format_money(total_cost), ""],
        ["", "TOTAL SALES REVENUE", "", "", "", format_money(total_rev), ""],
        ["", "GROSS PROFIT", "", "", "", format_money(gross_profit), ""]
      ]

    csv = to_csv(rows)

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", ~s(attachment; filename="purchases_#{from}_#{to}.csv"))
    |> send_resp(200, csv)
  end

  # ── CSV helper ─────────────────────────────────────────────────────────────

  defp to_csv(rows) do
    rows
    |> Enum.map(fn cols ->
      cols
      |> Enum.map(fn cell ->
        str = to_string(cell)
        if String.contains?(str, [",", "\"", "\n"]),
          do: ~s("#{String.replace(str, "\"", "\"\"")}"),
          else: str
      end)
      |> Enum.join(",")
    end)
    |> Enum.join("\r\n")
  end
end

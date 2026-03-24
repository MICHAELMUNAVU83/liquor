defmodule LiquorWeb.Admin.ReportsLive do
  use LiquorWeb, :live_view

  alias Liquor.{Orders, Expenses, Catalog, Cash}

  @impl true
  def mount(_params, _session, socket) do
    today = Date.utc_today()
    from  = Date.beginning_of_month(today)
    to    = today

    {:ok,
     socket
     |> assign(
       page_title:        "Admin – Reports",
       active_tab:        "reports",
       report_tab:        "sales",
       date_from:         Date.to_iso8601(from),
       date_to:           Date.to_iso8601(to),
       stock_search:      "",
       stock_filter:      "all",
       selected_register: nil,
       selected_sale:     nil
     )
     |> load_tab("sales", from, to),
     layout: {LiquorWeb.Layouts, :admin}}
  end

  # ── Events ────────────────────────────────────────────────────────────────

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {from, to} = current_range(socket)
    {:noreply, socket |> assign(report_tab: tab) |> load_tab(tab, from, to)}
  end

  def handle_event("apply_dates", params, socket) do
    from_str = params["date_from"] || socket.assigns.date_from
    to_str   = params["date_to"]   || socket.assigns.date_to
    {from, to} = parse_range(from_str, to_str)
    tab = socket.assigns.report_tab
    {:noreply, socket |> assign(date_from: Date.to_iso8601(from), date_to: Date.to_iso8601(to)) |> load_tab(tab, from, to)}
  end

  def handle_event("set_stock_filter", %{"filter" => f}, socket) do
    {:noreply, assign(socket, stock_filter: f)}
  end

  def handle_event("search_stock", %{"q" => q}, socket) do
    {:noreply, assign(socket, stock_search: q)}
  end

  def handle_event("show_register_detail", %{"id" => id}, socket) do
    register = Cash.get_register!(id)
    {:noreply, assign(socket, selected_register: register)}
  end

  def handle_event("close_register_detail", _params, socket) do
    {:noreply, assign(socket, selected_register: nil)}
  end

  def handle_event("show_sale_detail", %{"id" => id}, socket) do
    sales = socket.assigns[:sales_orders] || []
    sale  = Enum.find(sales, &(to_string(&1.id) == id))
    {:noreply, assign(socket, selected_sale: sale)}
  end

  def handle_event("close_sale_detail", _params, socket) do
    {:noreply, assign(socket, selected_sale: nil)}
  end

  # ── Data loading ──────────────────────────────────────────────────────────

  defp load_tab(socket, "sales", from, to) do
    orders       = Orders.list_orders_in_range(from, to)
    daily        = Orders.daily_revenue_in_range(from, to)
    by_payment   = Orders.revenue_by_payment_in_range(from, to)
    revenue      = Enum.reduce(by_payment, Decimal.new("0"), &Decimal.add(&1.total, &2))
    count        = length(orders)
    avg          = if count > 0, do: Decimal.div(revenue, Decimal.new(count)), else: Decimal.new("0")

    assign(socket,
      sales_orders:     orders,
      sales_revenue:    revenue,
      sales_count:      count,
      sales_avg:        avg,
      sales_daily:      daily,
      sales_by_payment: by_payment
    )
  end

  defp load_tab(socket, "expenses", from, to) do
    expenses     = Expenses.list_expenses_in_range(from, to)
    total        = Expenses.total_expenses_in_range(from, to)
    by_category  = Expenses.expenses_by_category_in_range(from, to)
    monthly      = Expenses.monthly_expenses_last_6()

    assign(socket,
      exp_list:        expenses,
      exp_total:       total,
      exp_count:       length(expenses),
      exp_by_category: by_category,
      exp_monthly:     monthly
    )
  end

  defp load_tab(socket, "cash", _from, _to) do
    registers = Cash.list_registers()
    assign(socket, cash_registers: registers)
  end

  defp load_tab(socket, "stock", _from, _to) do
    all_variants     = Catalog.list_all_variants()
    depleted         = Catalog.zero_stock_variants()
    low_stock        = Catalog.low_stock_variants(5)
    stock_value      = Catalog.total_stock_value()

    assign(socket,
      stock_variants: all_variants,
      stock_depleted: depleted,
      stock_low:      low_stock,
      stock_value:    stock_value
    )
  end

  defp load_tab(socket, _, from, to), do: load_tab(socket, "sales", from, to)

  # ── Helpers ───────────────────────────────────────────────────────────────

  defp current_range(socket) do
    parse_range(socket.assigns.date_from, socket.assigns.date_to)
  end

  defp parse_range(from_str, to_str) do
    today = Date.utc_today()
    from  = case Date.from_iso8601(from_str || "") do {:ok, d} -> d; _ -> Date.beginning_of_month(today) end
    to    = case Date.from_iso8601(to_str || "")   do {:ok, d} -> d; _ -> today end
    {from, to}
  end

  defp bar_pct(value, max) when is_struct(value, Decimal) and is_struct(max, Decimal) do
    if Decimal.compare(max, Decimal.new("0")) == :eq,
      do: 0,
      else: round(Decimal.to_float(value) / Decimal.to_float(max) * 100)
  end
  defp bar_pct(_, _), do: 0

  defp category_label("stock_restock"), do: "Stock Restock"
  defp category_label("utilities"),     do: "Utilities"
  defp category_label("wages"),         do: "Wages"
  defp category_label("rent"),          do: "Rent"
  defp category_label("maintenance"),   do: "Maintenance"
  defp category_label("other"),         do: "Other"
  defp category_label(c),               do: String.capitalize(c || "Other")

  defp category_color("stock_restock"), do: "bg-blue-500"
  defp category_color("utilities"),     do: "bg-purple-500"
  defp category_color("wages"),         do: "bg-green-500"
  defp category_color("rent"),          do: "bg-rose-500"
  defp category_color("maintenance"),   do: "bg-orange-500"
  defp category_color(_),               do: "bg-gray-500"

  defp payment_color("cash"),  do: "bg-emerald-500"
  defp payment_color("mpesa"), do: "bg-blue-500"
  defp payment_color("card"),  do: "bg-violet-500"
  defp payment_color(_),       do: "bg-gray-400"

  defp filter_stock(variants, search, filter) do
    variants
    |> filter_stock_search(search)
    |> filter_stock_level(filter)
  end

  defp filter_stock_search(v, ""), do: v
  defp filter_stock_search(v, q) do
    t = String.downcase(q)
    Enum.filter(v, fn item ->
      String.contains?(String.downcase(item.product.name), t) ||
      String.contains?(String.downcase(item.sku || ""), t)
    end)
  end

  defp filter_stock_level(v, "all"),      do: v
  defp filter_stock_level(v, "low"),      do: Enum.filter(v, &(&1.stock_quantity > 0 && &1.stock_quantity <= 5))
  defp filter_stock_level(v, "depleted"), do: Enum.filter(v, &(&1.stock_quantity == 0))
  defp filter_stock_level(v, _),          do: v

  # ── Render ────────────────────────────────────────────────────────────────

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-screen-xl mx-auto px-4 py-6">

      <!-- ── Page header ─────────────────────────────────────────────────── -->
      <div class="flex flex-wrap items-center justify-between gap-4 mb-6">
        <div>
          <h1 class="text-xl font-black text-gray-900">Reports & Analytics</h1>
          <p class="text-xs text-gray-400 mt-0.5">Business overview, trends & exports</p>
        </div>

        <!-- Date range -->
        <form phx-submit="apply_dates" class="flex flex-wrap items-end gap-2">
          <div>
            <label class="block text-xs font-semibold text-gray-500 mb-1">From</label>
            <input type="date" name="date_from" value={@date_from}
              class="border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400" />
          </div>
          <div>
            <label class="block text-xs font-semibold text-gray-500 mb-1">To</label>
            <input type="date" name="date_to" value={@date_to}
              class="border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400" />
          </div>
          <button type="submit"
            class="bg-amber-500 hover:bg-amber-600 text-white font-bold text-sm px-4 py-2 rounded-lg transition">
            Apply
          </button>
        </form>
      </div>

      <!-- ── Tab navigation ──────────────────────────────────────────────── -->
      <div class="flex gap-1 mb-6 bg-gray-100 rounded-xl p-1 w-fit">
        <%= for {label, key, icon} <- [
          {"Sales",         "sales",    "M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"},
          {"Expenses",      "expenses", "M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"},
          {"Cash Registry", "cash",     "M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"},
          {"Stock",         "stock",    "M20 7l-8-4-8 4m16 0v10l-8 4m0-14v14m0 0l-8-4V7"}
        ] do %>
          <button
            phx-click="switch_tab"
            phx-value-tab={key}
            class={[
              "flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-semibold transition",
              if(@report_tab == key,
                do: "bg-white text-gray-900 shadow-sm",
                else: "text-gray-500 hover:text-gray-700")
            ]}
          >
            <svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" d={icon}/>
            </svg>
            <%= label %>
          </button>
        <% end %>
      </div>

      <!-- ════════════════════════════════════════════════════════════════
           SALES TAB
      ════════════════════════════════════════════════════════════════ -->
      <%= if @report_tab == "sales" do %>
        <!-- KPIs -->
        <div class="grid grid-cols-2 md:grid-cols-3 gap-4 mb-6">
          <div class="bg-white border border-gray-200 rounded-xl p-5">
            <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-1">Revenue</p>
            <p class="text-2xl font-black text-amber-600">KSh <%= format_money(@sales_revenue) %></p>
            <p class="text-xs text-gray-400 mt-1"><%= @date_from %> → <%= @date_to %></p>
          </div>
          <div class="bg-white border border-gray-200 rounded-xl p-5">
            <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-1">Sales Count</p>
            <p class="text-2xl font-black text-gray-900"><%= @sales_count %></p>
            <p class="text-xs text-gray-400 mt-1">transactions</p>
          </div>
          <div class="bg-white border border-gray-200 rounded-xl p-5 col-span-2 md:col-span-1">
            <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-1">Avg Order</p>
            <p class="text-2xl font-black text-gray-900">KSh <%= format_money(@sales_avg) %></p>
            <p class="text-xs text-gray-400 mt-1">per transaction</p>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">

          <!-- Daily revenue chart -->
          <div class="lg:col-span-2 bg-white border border-gray-200 rounded-xl p-5">
            <div class="flex items-center justify-between mb-4">
              <h2 class="font-bold text-gray-900 text-sm">Daily Revenue</h2>
              <a
                href={"/admin/reports/download/sales?from=#{@date_from}&to=#{@date_to}"}
                target="_blank"
                class="flex items-center gap-1 text-xs font-semibold text-gray-500 hover:text-gray-700 border border-gray-200 rounded-lg px-2.5 py-1.5 transition"
              >
                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/>
                </svg>
                Download CSV
              </a>
            </div>
            <%= if @sales_daily == [] do %>
              <div class="h-44 flex items-center justify-center text-sm text-gray-400">No sales in this period</div>
            <% else %>
              <%
                max_rev = @sales_daily |> Enum.map(& &1.revenue) |> Enum.max_by(&Decimal.to_float/1)
                max_rev = if Decimal.compare(max_rev, Decimal.new("0")) == :eq, do: Decimal.new("1"), else: max_rev
              %>
              <div class="flex items-end gap-1.5 h-44 overflow-x-auto pb-1">
                <%= for row <- @sales_daily do %>
                  <% pct = bar_pct(row.revenue, max_rev) %>
                  <div class="flex-1 min-w-[24px] flex flex-col items-center gap-1 group">
                    <div class="relative w-full">
                      <div
                        class="w-full bg-amber-400 hover:bg-amber-500 rounded-t-sm transition-all cursor-default"
                        style={"height: #{max(4, round(pct * 1.6))}px;"}
                        title={"KSh #{Decimal.to_string(row.revenue)}"}
                      ></div>
                    </div>
                    <span class="text-[9px] text-gray-400 whitespace-nowrap"><%= row.label %></span>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>

          <!-- Payment method breakdown -->
          <div class="bg-white border border-gray-200 rounded-xl p-5">
            <h2 class="font-bold text-gray-900 text-sm mb-4">By Payment Method</h2>
            <%= if @sales_by_payment == [] do %>
              <p class="text-sm text-gray-400 py-8 text-center">No data</p>
            <% else %>
              <%
                max_pay = @sales_by_payment |> Enum.map(& &1.total) |> Enum.max_by(&Decimal.to_float/1)
                max_pay = if Decimal.compare(max_pay, Decimal.new("0")) == :eq, do: Decimal.new("1"), else: max_pay
              %>
              <div class="space-y-4">
                <%= for p <- @sales_by_payment do %>
                  <% pct = bar_pct(p.total, max_pay) %>
                  <div>
                    <div class="flex justify-between text-xs mb-1.5">
                      <span class="font-semibold text-gray-700 capitalize"><%= p.method %></span>
                      <span class="text-gray-400"><%= p.count %> · KSh <%= format_money(p.total) %></span>
                    </div>
                    <div class="h-2 bg-gray-100 rounded-full overflow-hidden">
                      <div class={"h-full rounded-full transition-all #{payment_color(p.method)}"} style={"width: #{pct}%"}></div>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>

        <!-- Sales table -->
        <div class="bg-white border border-gray-200 rounded-xl overflow-hidden">
          <div class="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
            <h2 class="font-bold text-gray-900 text-sm">Sales Detail</h2>
            <span class="text-xs text-gray-400"><%= length(@sales_orders) %> records</span>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead class="bg-gray-50 border-b border-gray-100">
                <tr>
                  <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">#</th>
                  <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Customer</th>
                  <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide hidden md:table-cell">Items</th>
                  <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Date</th>
                  <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Payment</th>
                  <th class="text-right px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Total</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <%= if @sales_orders == [] do %>
                  <tr><td colspan="6" class="px-5 py-10 text-center text-sm text-gray-400">No sales in this period</td></tr>
                <% end %>
                <%= for o <- @sales_orders do %>
                  <tr
                    class="hover:bg-amber-50 cursor-pointer transition"
                    phx-click="show_sale_detail"
                    phx-value-id={o.id}
                  >
                    <td class="px-5 py-3 font-mono text-xs text-gray-400">#<%= o.id %></td>
                    <td class="px-5 py-3 text-gray-700 font-medium">
                      <%= if o.user, do: "#{o.user.first_name} #{o.user.last_name}", else: o.shipping_name || "Walk-in" %>
                    </td>
                    <td class="px-5 py-3 text-gray-400 text-xs hidden md:table-cell"><%= length(o.items) %> item(s)</td>
                    <td class="px-5 py-3 text-gray-400 text-xs"><%= Calendar.strftime(o.inserted_at, "%b %d, %Y %H:%M") %></td>
                    <td class="px-5 py-3">
                      <span class="text-xs bg-gray-100 text-gray-600 font-semibold px-2 py-0.5 rounded capitalize"><%= o.payment_method %></span>
                    </td>
                    <td class="px-5 py-3 text-right font-bold text-gray-900">KSh <%= format_money(o.total_amount) %></td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>

      <!-- ════════════════════════════════════════════════════════════════
           EXPENSES TAB
      ════════════════════════════════════════════════════════════════ -->
      <% end %>
      <%= if @report_tab == "expenses" do %>
        <!-- KPIs -->
        <div class="grid grid-cols-2 gap-4 mb-6">
          <div class="bg-white border border-gray-200 rounded-xl p-5">
            <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-1">Total Expenses</p>
            <p class="text-2xl font-black text-rose-600">KSh <%= format_money(@exp_total) %></p>
            <p class="text-xs text-gray-400 mt-1"><%= @date_from %> → <%= @date_to %></p>
          </div>
          <div class="bg-white border border-gray-200 rounded-xl p-5">
            <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-1">Transactions</p>
            <p class="text-2xl font-black text-gray-900"><%= @exp_count %></p>
            <p class="text-xs text-gray-400 mt-1">expense entries</p>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">

          <!-- Monthly expenses chart -->
          <div class="lg:col-span-2 bg-white border border-gray-200 rounded-xl p-5">
            <div class="flex items-center justify-between mb-4">
              <h2 class="font-bold text-gray-900 text-sm">Monthly Expenses (Last 6 Months)</h2>
              <a
                href={"/admin/reports/download/expenses?from=#{@date_from}&to=#{@date_to}"}
                target="_blank"
                class="flex items-center gap-1 text-xs font-semibold text-gray-500 hover:text-gray-700 border border-gray-200 rounded-lg px-2.5 py-1.5 transition"
              >
                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/>
                </svg>
                Download CSV
              </a>
            </div>
            <%= if @exp_monthly == [] do %>
              <div class="h-44 flex items-center justify-center text-sm text-gray-400">No expense data yet</div>
            <% else %>
              <%
                max_exp = @exp_monthly |> Enum.map(& &1.total) |> Enum.max_by(&Decimal.to_float/1)
                max_exp = if Decimal.compare(max_exp, Decimal.new("0")) == :eq, do: Decimal.new("1"), else: max_exp
              %>
              <div class="flex items-end gap-3 h-44">
                <%= for row <- @exp_monthly do %>
                  <% pct = bar_pct(row.total, max_exp) %>
                  <div class="flex-1 flex flex-col items-center gap-1">
                    <span class="text-[10px] font-semibold text-gray-500">KSh <%= format_money(row.total) %></span>
                    <div
                      class="w-full bg-rose-400 hover:bg-rose-500 rounded-t-sm transition-all"
                      style={"height: #{max(4, round(pct * 1.4))}px;"}
                    ></div>
                    <span class="text-[10px] text-gray-400 text-center"><%= row.month %></span>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>

          <!-- By category -->
          <div class="bg-white border border-gray-200 rounded-xl p-5">
            <h2 class="font-bold text-gray-900 text-sm mb-4">By Category</h2>
            <%= if @exp_by_category == [] do %>
              <p class="text-sm text-gray-400 py-8 text-center">No data</p>
            <% else %>
              <%
                max_cat = @exp_by_category |> Enum.map(& &1.total) |> Enum.max_by(&Decimal.to_float/1)
                max_cat = if Decimal.compare(max_cat, Decimal.new("0")) == :eq, do: Decimal.new("1"), else: max_cat
              %>
              <div class="space-y-3.5">
                <%= for c <- @exp_by_category do %>
                  <% pct = bar_pct(c.total, max_cat) %>
                  <div>
                    <div class="flex justify-between text-xs mb-1.5">
                      <span class="font-semibold text-gray-700"><%= category_label(c.category) %></span>
                      <span class="text-gray-400"><%= c.count %> · KSh <%= format_money(c.total) %></span>
                    </div>
                    <div class="h-2 bg-gray-100 rounded-full overflow-hidden">
                      <div class={"h-full rounded-full #{category_color(c.category)}"} style={"width: #{pct}%"}></div>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>

        <!-- Expenses table -->
        <div class="bg-white border border-gray-200 rounded-xl overflow-hidden">
          <div class="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
            <h2 class="font-bold text-gray-900 text-sm">Expense Detail</h2>
            <span class="text-xs text-gray-400"><%= @exp_count %> records</span>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead class="bg-gray-50 border-b border-gray-100">
                <tr>
                  <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Date</th>
                  <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Description</th>
                  <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Category</th>
                  <th class="text-right px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Amount</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <%= if @exp_list == [] do %>
                  <tr><td colspan="4" class="px-5 py-10 text-center text-sm text-gray-400">No expenses in this period</td></tr>
                <% end %>
                <%= for e <- @exp_list do %>
                  <tr class="hover:bg-rose-50 transition">
                    <td class="px-5 py-3 text-xs text-gray-400"><%= Date.to_string(e.expense_date) %></td>
                    <td class="px-5 py-3 text-gray-700">
                      <p class="font-medium"><%= e.description %></p>
                      <%= if e.notes && e.notes != "" do %>
                        <p class="text-xs text-gray-400 mt-0.5"><%= e.notes %></p>
                      <% end %>
                    </td>
                    <td class="px-5 py-3">
                      <span class={"text-xs font-semibold px-2 py-0.5 rounded text-white #{category_color(e.category)}"}>
                        <%= category_label(e.category) %>
                      </span>
                    </td>
                    <td class="px-5 py-3 text-right font-bold text-rose-600">KSh <%= format_money(e.amount) %></td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>

      <!-- ════════════════════════════════════════════════════════════════
           CASH REGISTRY TAB
      ════════════════════════════════════════════════════════════════ -->
      <% end %>
      <%= if @report_tab == "cash" do %>
        <!-- Summary cards -->
        <%
          open_count  = @cash_registers |> Enum.count(&(&1.status == "open"))
          total_sales = @cash_registers |> Enum.reduce(Decimal.new("0"), fn r, acc ->
            Decimal.add(acc, Map.get(r, :cash_sales_total, Decimal.new("0")))
          end)
        %>
        <div class="grid grid-cols-2 md:grid-cols-3 gap-4 mb-6">
          <div class="bg-white border border-gray-200 rounded-xl p-5">
            <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-1">Total Registers</p>
            <p class="text-2xl font-black text-gray-900"><%= length(@cash_registers) %></p>
          </div>
          <div class="bg-white border border-gray-200 rounded-xl p-5">
            <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-1">Currently Open</p>
            <p class={["text-2xl font-black", if(open_count > 0, do: "text-emerald-600", else: "text-gray-400")]}>
              <%= open_count %>
            </p>
          </div>
          <div class="bg-white border border-gray-200 rounded-xl p-5 col-span-2 md:col-span-1">
            <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-1">All-Time Cash Sales</p>
            <p class="text-2xl font-black text-emerald-600">KSh <%= format_money(total_sales) %></p>
          </div>
        </div>

        <!-- Cash registers table -->
        <div class="bg-white border border-gray-200 rounded-xl overflow-hidden">
          <div class="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
            <h2 class="font-bold text-gray-900 text-sm">Cash Register History</h2>
            <a
              href="/admin/reports/download/cash"
              target="_blank"
              class="flex items-center gap-1 text-xs font-semibold text-gray-500 hover:text-gray-700 border border-gray-200 rounded-lg px-2.5 py-1.5 transition"
            >
              <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/>
              </svg>
              Download CSV
            </a>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead class="bg-gray-50 border-b border-gray-100">
                <tr>
                  <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Opened</th>
                  <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Closed</th>
                  <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Opened By</th>
                  <th class="text-right px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Opening</th>
                  <th class="text-right px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Sales</th>
                  <th class="text-right px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Expenses</th>
                  <th class="text-right px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Expected</th>
                  <th class="text-right px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Actual</th>
                  <th class="text-center px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Status</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <%= if @cash_registers == [] do %>
                  <tr><td colspan="9" class="px-5 py-10 text-center text-sm text-gray-400">No cash registers yet</td></tr>
                <% end %>
                <%= for r <- @cash_registers do %>
                  <% s = Cash.summary(r) %>
                  <tr
                    class="hover:bg-amber-50 cursor-pointer transition"
                    phx-click="show_register_detail"
                    phx-value-id={r.id}
                  >
                    <td class="px-5 py-3 text-xs text-gray-500"><%= Calendar.strftime(r.opened_at, "%b %d, %Y %H:%M") %></td>
                    <td class="px-5 py-3 text-xs text-gray-400">
                      <%= if r.closed_at, do: Calendar.strftime(r.closed_at, "%b %d, %Y %H:%M"), else: "—" %>
                    </td>
                    <td class="px-5 py-3 text-gray-700 text-xs">
                      <%= if r.opened_by, do: "#{r.opened_by.first_name} #{r.opened_by.last_name}", else: "—" %>
                    </td>
                    <td class="px-5 py-3 text-right text-gray-600 text-xs">KSh <%= format_money(s.open_amount) %></td>
                    <td class="px-5 py-3 text-right text-emerald-600 font-semibold text-xs">KSh <%= format_money(s.cash_sales) %></td>
                    <td class="px-5 py-3 text-right text-rose-500 text-xs">KSh <%= format_money(s.total_expenses) %></td>
                    <td class="px-5 py-3 text-right font-semibold text-gray-800 text-xs">KSh <%= format_money(s.expected_close) %></td>
                    <td class="px-5 py-3 text-right font-bold text-gray-900 text-xs">
                      <%= if s.close_amount, do: "KSh #{format_money(s.close_amount)}", else: "—" %>
                    </td>
                    <td class="px-5 py-3 text-center">
                      <span class={[
                        "text-xs font-bold px-2 py-0.5 rounded",
                        if(r.status == "open", do: "bg-emerald-100 text-emerald-700", else: "bg-gray-100 text-gray-500")
                      ]}>
                        <%= String.capitalize(r.status) %>
                      </span>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>

      <!-- ════════════════════════════════════════════════════════════════
           STOCK TAB
      ════════════════════════════════════════════════════════════════ -->
      <% end %>
      <%= if @report_tab == "stock" do %>
        <!-- KPIs -->
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          <div class="bg-white border border-gray-200 rounded-xl p-5">
            <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-1">Stock Value</p>
            <p class="text-2xl font-black text-blue-600">KSh <%= format_money(@stock_value) %></p>
          </div>
          <div class="bg-white border border-gray-200 rounded-xl p-5">
            <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-1">Total SKUs</p>
            <p class="text-2xl font-black text-gray-900"><%= length(@stock_variants) %></p>
          </div>
          <div class="bg-amber-50 border border-amber-200 rounded-xl p-5">
            <p class="text-xs font-bold uppercase tracking-widest text-amber-500 mb-1">Low Stock</p>
            <p class="text-2xl font-black text-amber-600"><%= length(@stock_low) %></p>
            <p class="text-xs text-amber-400 mt-1">≤ 5 units</p>
          </div>
          <div class="bg-red-50 border border-red-200 rounded-xl p-5">
            <p class="text-xs font-bold uppercase tracking-widest text-red-400 mb-1">Depleted</p>
            <p class="text-2xl font-black text-red-600"><%= length(@stock_depleted) %></p>
            <p class="text-xs text-red-300 mt-1">out of stock</p>
          </div>
        </div>

        <!-- Stock bar chart (top 10 by value) -->
        <%
          top_10 =
            @stock_variants
            |> Enum.map(fn v -> Map.put(v, :value, Decimal.mult(v.price, Decimal.new(v.stock_quantity))) end)
            |> Enum.sort_by(&Decimal.to_float(&1.value), :desc)
            |> Enum.take(10)
          max_val = case top_10 do
            []   -> Decimal.new("1")
            rows ->
              m = Enum.max_by(rows, &Decimal.to_float(&1.value)).value
              if Decimal.compare(m, Decimal.new("0")) == :eq, do: Decimal.new("1"), else: m
          end
        %>
        <div class="bg-white border border-gray-200 rounded-xl p-5 mb-6">
          <div class="flex items-center justify-between mb-4">
            <h2 class="font-bold text-gray-900 text-sm">Top 10 Products by Stock Value</h2>
            <a
              href="/admin/reports/download/stock"
              target="_blank"
              class="flex items-center gap-1 text-xs font-semibold text-gray-500 hover:text-gray-700 border border-gray-200 rounded-lg px-2.5 py-1.5 transition"
            >
              <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/>
              </svg>
              Download CSV
            </a>
          </div>
          <%= if top_10 == [] do %>
            <div class="h-32 flex items-center justify-center text-sm text-gray-400">No stock data</div>
          <% else %>
            <div class="space-y-3">
              <%= for item <- top_10 do %>
                <% pct = bar_pct(item.value, max_val) %>
                <div class="flex items-center gap-3">
                  <div class="w-36 shrink-0 text-xs font-medium text-gray-700 truncate"><%= item.product.name %></div>
                  <div class="flex-1 h-5 bg-gray-100 rounded overflow-hidden">
                    <div
                      class={[
                        "h-full rounded transition-all flex items-center pl-2",
                        cond do
                          item.stock_quantity == 0 -> "bg-red-400"
                          item.stock_quantity <= 5 -> "bg-amber-400"
                          true -> "bg-blue-400"
                        end
                      ]}
                      style={"width: #{max(2, pct)}%"}
                    ></div>
                  </div>
                  <div class="w-28 shrink-0 text-right text-xs text-gray-500">
                    <%= item.stock_quantity %> u · KSh <%= format_money(item.value) %>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>

        <!-- Filter + search -->
        <div class="flex flex-wrap items-center gap-3 mb-4">
          <div class="relative">
            <svg class="absolute left-2.5 top-2.5 w-3.5 h-3.5 text-gray-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
              <circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/>
            </svg>
            <input
              type="text"
              placeholder="Search product or SKU…"
              value={@stock_search}
              phx-keyup="search_stock"
              name="q"
              phx-debounce="250"
              class="pl-8 pr-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
            />
          </div>
          <div class="flex gap-1">
            <%= for {label, val} <- [{"All", "all"}, {"Low Stock", "low"}, {"Depleted", "depleted"}] do %>
              <button
                phx-click="set_stock_filter"
                phx-value-filter={val}
                class={[
                  "text-xs font-semibold px-3 py-2 rounded-lg border transition",
                  if(@stock_filter == val,
                    do: "bg-gray-900 text-white border-gray-900",
                    else: "border-gray-200 text-gray-600 hover:border-gray-300")
                ]}
              >
                <%= label %>
              </button>
            <% end %>
          </div>
        </div>

        <!-- All variants table -->
        <div class="bg-white border border-gray-200 rounded-xl overflow-hidden">
          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead class="bg-gray-50 border-b border-gray-100">
                <tr>
                  <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Product</th>
                  <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">SKU</th>
                  <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Size</th>
                  <th class="text-right px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Unit Price</th>
                  <th class="text-right px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Qty</th>
                  <th class="text-right px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Stock Value</th>
                  <th class="text-center px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Status</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <%
                  visible = filter_stock(@stock_variants, @stock_search, @stock_filter)
                %>
                <%= if visible == [] do %>
                  <tr><td colspan="7" class="px-5 py-10 text-center text-sm text-gray-400">No variants match</td></tr>
                <% end %>
                <%= for v <- visible do %>
                  <% stock_val = Decimal.mult(v.price, Decimal.new(v.stock_quantity)) %>
                  <tr class={["transition", if(v.stock_quantity == 0, do: "bg-red-50", else: "hover:bg-gray-50")]}>
                    <td class="px-5 py-3 font-medium text-gray-800"><%= v.product.name %></td>
                    <td class="px-5 py-3 font-mono text-xs text-gray-400"><%= v.sku || "—" %></td>
                    <td class="px-5 py-3 text-gray-500 text-xs"><%= v.size || "—" %></td>
                    <td class="px-5 py-3 text-right text-gray-600">KSh <%= format_money(v.price) %></td>
                    <td class={[
                      "px-5 py-3 text-right font-bold",
                      cond do
                        v.stock_quantity == 0   -> "text-red-600"
                        v.stock_quantity <= 5   -> "text-amber-600"
                        true                    -> "text-gray-900"
                      end
                    ]}>
                      <%= v.stock_quantity %>
                    </td>
                    <td class="px-5 py-3 text-right text-gray-700 font-semibold">KSh <%= format_money(stock_val) %></td>
                    <td class="px-5 py-3 text-center">
                      <span class={[
                        "text-xs font-bold px-2 py-0.5 rounded",
                        cond do
                          v.stock_quantity == 0   -> "bg-red-100 text-red-700"
                          v.stock_quantity <= 5   -> "bg-amber-100 text-amber-700"
                          true                    -> "bg-emerald-100 text-emerald-700"
                        end
                      ]}>
                        <%= cond do
                          v.stock_quantity == 0   -> "Out of Stock"
                          v.stock_quantity <= 5   -> "Low Stock"
                          true                    -> "OK"
                        end %>
                      </span>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      <% end %>

    </div>

    <!-- ── Sale detail modal ──────────────────────────────────────────────── -->
    <%= if @selected_sale do %>
      <% s = @selected_sale %>
      <div
        class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4"
        phx-click="close_sale_detail"
      >
        <div class="bg-white rounded-xl shadow-xl w-full max-w-lg overflow-hidden" phx-click-away="close_sale_detail">
          <div class="flex items-center justify-between px-6 py-4 border-b border-gray-100 bg-gray-50">
            <div>
              <h3 class="text-base font-black text-gray-900">Sale #<%= s.id %></h3>
              <p class="text-xs text-gray-400 mt-0.5"><%= Calendar.strftime(s.inserted_at, "%B %d, %Y at %H:%M") %></p>
            </div>
            <button phx-click="close_sale_detail" class="text-gray-400 hover:text-gray-600">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
              </svg>
            </button>
          </div>
          <div class="px-6 py-4 space-y-4 max-h-[70vh] overflow-y-auto">
            <div class="grid grid-cols-2 gap-4">
              <div>
                <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-1">Customer</p>
                <p class="text-sm font-semibold text-gray-800">
                  <%= if s.user, do: "#{s.user.first_name} #{s.user.last_name}", else: s.shipping_name || "Walk-in" %>
                </p>
              </div>
              <div>
                <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-1">Payment</p>
                <span class="inline-block bg-emerald-100 text-emerald-700 text-xs font-bold px-2.5 py-1 rounded-full capitalize">
                  <%= s.payment_method || "—" %>
                </span>
              </div>
            </div>
            <%= if s.items != [] do %>
              <div class="border border-gray-100 rounded-lg overflow-hidden">
                <table class="w-full text-sm">
                  <thead class="bg-gray-50">
                    <tr>
                      <th class="text-left px-3 py-2 text-xs font-semibold text-gray-500">Product</th>
                      <th class="text-center px-3 py-2 text-xs font-semibold text-gray-500">Qty</th>
                      <th class="text-right px-3 py-2 text-xs font-semibold text-gray-500">Unit</th>
                      <th class="text-right px-3 py-2 text-xs font-semibold text-gray-500">Subtotal</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-100">
                    <%= for item <- s.items do %>
                      <tr>
                        <td class="px-3 py-2">
                          <p class="font-medium text-gray-800"><%= item.product_name %></p>
                          <p class="text-xs text-gray-400"><%= item.variant_size %></p>
                        </td>
                        <td class="px-3 py-2 text-center text-gray-700 font-semibold"><%= item.quantity %></td>
                        <td class="px-3 py-2 text-right text-gray-600">KSh <%= format_money(item.unit_price) %></td>
                        <td class="px-3 py-2 text-right font-bold text-gray-900">KSh <%= format_money(item.subtotal) %></td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            <% end %>
            <div class="flex justify-between text-base font-black pt-1 border-t border-gray-100">
              <span class="text-gray-900">Total</span>
              <span class="text-amber-600">KSh <%= format_money(s.total_amount) %></span>
            </div>
          </div>
          <div class="px-6 py-4 border-t border-gray-100 flex gap-3">
            <button phx-click="close_sale_detail" class="flex-1 border border-gray-200 text-gray-600 font-semibold py-2.5 rounded-lg hover:bg-gray-50 transition text-sm">
              Close
            </button>
            <a
              href={"/admin/receipt/#{s.id}"}
              target="_blank"
              class="flex-1 flex items-center justify-center gap-2 bg-gray-900 hover:bg-gray-700 text-white font-bold py-2.5 rounded-lg transition text-sm"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"/>
              </svg>
              Print Receipt
            </a>
          </div>
        </div>
      </div>
    <% end %>

    <!-- ── Cash register detail modal ────────────────────────────────────── -->
    <%= if @selected_register do %>
      <% r = @selected_register %>
      <% s = Cash.summary(r) %>
      <div
        class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4"
        phx-click="close_register_detail"
      >
        <div class="bg-white rounded-xl shadow-xl w-full max-w-xl overflow-hidden" phx-click-away="close_register_detail">

          <!-- Header -->
          <div class="flex items-center justify-between px-6 py-4 border-b border-gray-100 bg-gray-50">
            <div>
              <h3 class="text-base font-black text-gray-900">Cash Register #<%= r.id %></h3>
              <p class="text-xs text-gray-400 mt-0.5">
                Opened <%= Calendar.strftime(r.opened_at, "%B %d, %Y at %H:%M") %>
                <%= if r.opened_by do %> by <strong><%= r.opened_by.first_name %> <%= r.opened_by.last_name %></strong><% end %>
              </p>
            </div>
            <div class="flex items-center gap-3">
              <span class={[
                "text-xs font-bold px-2.5 py-1 rounded-full",
                if(r.status == "open", do: "bg-emerald-100 text-emerald-700", else: "bg-gray-100 text-gray-500")
              ]}>
                <%= String.capitalize(r.status) %>
              </span>
              <button phx-click="close_register_detail" class="text-gray-400 hover:text-gray-600">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
                </svg>
              </button>
            </div>
          </div>

          <div class="px-6 py-4 space-y-5 max-h-[75vh] overflow-y-auto">

            <!-- Summary grid -->
            <div class="grid grid-cols-2 gap-3">
              <%= for {label, value, color} <- [
                {"Opening Amount",  "KSh #{format_money(s.open_amount)}",    "text-gray-900"},
                {"Cash Sales",      "KSh #{format_money(s.cash_sales)}",     "text-emerald-600"},
                {"Expenses",        "KSh #{format_money(s.total_expenses)}", "text-rose-500"},
                {"Expected Close",  "KSh #{format_money(s.expected_close)}", "text-gray-900"}
              ] do %>
                <div class="bg-gray-50 rounded-lg px-4 py-3">
                  <p class="text-xs font-semibold text-gray-400 mb-1"><%= label %></p>
                  <p class={"text-base font-black #{color}"}><%= value %></p>
                </div>
              <% end %>
            </div>

            <%= if s.close_amount do %>
              <div class="bg-amber-50 border border-amber-200 rounded-lg px-4 py-3 flex justify-between items-center">
                <span class="text-sm font-semibold text-amber-700">Actual Close</span>
                <span class="text-lg font-black text-amber-700">KSh <%= format_money(s.close_amount) %></span>
              </div>
            <% end %>

            <!-- Cash transactions (orders) -->
            <%= if r.orders != [] do %>
              <div>
                <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-2">
                  Cash Transactions (<%= length(r.orders) %>)
                </p>
                <div class="border border-gray-100 rounded-lg overflow-hidden max-h-48 overflow-y-auto">
                  <table class="w-full text-xs">
                    <thead class="bg-gray-50 sticky top-0">
                      <tr>
                        <th class="text-left px-3 py-2 font-semibold text-gray-500">#</th>
                        <th class="text-left px-3 py-2 font-semibold text-gray-500">Time</th>
                        <th class="text-right px-3 py-2 font-semibold text-gray-500">Amount</th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100">
                      <%= for o <- r.orders do %>
                        <tr class="hover:bg-gray-50">
                          <td class="px-3 py-2 font-mono text-gray-400">#<%= o.id %></td>
                          <td class="px-3 py-2 text-gray-500"><%= Calendar.strftime(o.inserted_at, "%H:%M") %></td>
                          <td class="px-3 py-2 text-right font-bold text-gray-800">KSh <%= format_money(o.total_amount) %></td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>
              </div>
            <% end %>

            <!-- Cash expenses -->
            <%= if r.expenses != [] do %>
              <div>
                <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-2">
                  Cash Expenses (<%= length(r.expenses) %>)
                </p>
                <div class="border border-gray-100 rounded-lg overflow-hidden">
                  <table class="w-full text-xs">
                    <thead class="bg-gray-50">
                      <tr>
                        <th class="text-left px-3 py-2 font-semibold text-gray-500">Description</th>
                        <th class="text-right px-3 py-2 font-semibold text-gray-500">Amount</th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100">
                      <%= for e <- r.expenses do %>
                        <tr>
                          <td class="px-3 py-2 text-gray-700"><%= e.description %></td>
                          <td class="px-3 py-2 text-right font-bold text-rose-500">KSh <%= format_money(e.amount) %></td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>
              </div>
            <% end %>

            <!-- Notes -->
            <%= if r.notes && r.notes != "" do %>
              <div class="bg-amber-50 border border-amber-100 rounded-lg px-4 py-3">
                <p class="text-xs font-semibold text-amber-600 mb-1">Notes</p>
                <p class="text-sm text-gray-700"><%= r.notes %></p>
              </div>
            <% end %>

          </div>

          <div class="px-6 py-4 border-t border-gray-100">
            <button phx-click="close_register_detail" class="w-full border border-gray-200 text-gray-600 font-semibold py-2.5 rounded-lg hover:bg-gray-50 transition text-sm">
              Close
            </button>
          </div>
        </div>
      </div>
    <% end %>

    """
  end
end

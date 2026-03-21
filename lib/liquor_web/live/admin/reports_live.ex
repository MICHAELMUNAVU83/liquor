defmodule LiquorWeb.Admin.ReportsLive do
  use LiquorWeb, :live_view

  alias Liquor.{Orders, Catalog, Accounts}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Admin – Reports", active_tab: "reports")
     |> load_reports(),
     layout: {LiquorWeb.Layouts, :admin}}
  end

  defp load_reports(socket) do
    assign(socket,
      total_revenue:     Orders.total_revenue(),
      revenue_today:     Orders.revenue_today(),
      revenue_month:     Orders.revenue_this_month(),
      orders_by_status:  Orders.orders_by_status(),
      monthly_revenue:   Orders.monthly_revenue_last_6(),
      top_products:      Orders.top_products(8),
      total_orders:      Orders.count_orders(),
      paid_orders:       Orders.count_paid_orders(),
      total_customers:   Accounts.count_users(),
      total_products:    Catalog.count_products(),
      stock_value:       Catalog.total_stock_value(),
      low_stock:         Catalog.low_stock_variants(5)
    )
  end

  @impl true
  def render(assigns) do
    max_revenue =
      case assigns.monthly_revenue do
        [] -> Decimal.new("1")
        rows ->
          rows
          |> Enum.map(& &1.revenue)
          |> Enum.max_by(&Decimal.to_float/1)
          |> then(fn m -> if Decimal.compare(m, Decimal.new("0")) == :eq, do: Decimal.new("1"), else: m end)
      end

    assigns = assign(assigns, max_revenue: max_revenue)

    ~H"""
    <div class="max-w-screen-xl mx-auto px-4 py-8">

      <!-- Header -->
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-2xl font-black text-gray-900">Reports & Analytics</h1>
          <p class="text-sm text-gray-500 mt-0.5">Business overview and key metrics</p>
        </div>
        <p class="text-xs text-gray-400">Last updated: <%= Calendar.strftime(DateTime.utc_now(), "%b %d, %Y %H:%M UTC") %></p>
      </div>

      <!-- Top KPI row -->
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        <div class="bg-white border border-gray-200 rounded-xl p-5">
          <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-1">Revenue Today</p>
          <p class="text-2xl font-black text-gray-900">KSh <%= format_money(@revenue_today || Decimal.new("0")) %></p>
        </div>
        <div class="bg-white border border-gray-200 rounded-xl p-5">
          <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-1">This Month</p>
          <p class="text-2xl font-black text-amber-600">KSh <%= format_money(@revenue_month || Decimal.new("0")) %></p>
        </div>
        <div class="bg-white border border-gray-200 rounded-xl p-5">
          <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-1">Total Revenue</p>
          <p class="text-2xl font-black text-emerald-600">KSh <%= format_money(@total_revenue || Decimal.new("0")) %></p>
        </div>
        <div class="bg-white border border-gray-200 rounded-xl p-5">
          <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-1">Stock Value</p>
          <p class="text-2xl font-black text-blue-600">KSh <%= format_money(@stock_value || Decimal.new("0")) %></p>
        </div>
      </div>

      <!-- Second row: orders + customers -->
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        <div class="bg-white border border-gray-200 rounded-xl p-5">
          <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-1">Total Orders</p>
          <p class="text-2xl font-black text-gray-900"><%= @total_orders %></p>
        </div>
        <div class="bg-emerald-50 border border-emerald-200 rounded-xl p-5">
          <p class="text-xs font-bold uppercase tracking-widest text-emerald-500 mb-1">Paid Orders</p>
          <p class="text-2xl font-black text-emerald-700"><%= @paid_orders %></p>
        </div>
        <div class="bg-white border border-gray-200 rounded-xl p-5">
          <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-1">Customers</p>
          <p class="text-2xl font-black text-gray-900"><%= @total_customers %></p>
        </div>
        <div class="bg-white border border-gray-200 rounded-xl p-5">
          <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-1">Products</p>
          <p class="text-2xl font-black text-gray-900"><%= @total_products %></p>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">

        <!-- Monthly revenue chart (bar) -->
        <div class="lg:col-span-2 bg-white border border-gray-200 rounded-xl p-5">
          <h2 class="font-bold text-gray-900 mb-4">Monthly Revenue (Last 6 Months)</h2>
          <%= if @monthly_revenue == [] do %>
            <div class="h-40 flex items-center justify-center text-sm text-gray-400">No revenue data yet</div>
          <% else %>
            <div class="flex items-end gap-3 h-40">
              <%= for row <- @monthly_revenue do %>
                <%
                  pct = Decimal.to_float(row.revenue) / Decimal.to_float(@max_revenue) * 100
                  height = max(4, round(pct * 0.9))
                %>
                <div class="flex-1 flex flex-col items-center gap-1">
                  <span class="text-xs font-semibold text-gray-600">KSh <%= format_money(row.revenue) %></span>
                  <div
                    class="w-full bg-amber-400 rounded-t-md transition-all"
                    style={"height: #{height}%;"}
                  ></div>
                  <span class="text-[10px] text-gray-400 text-center leading-tight"><%= row.month %></span>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>

        <!-- Orders by status -->
        <div class="bg-white border border-gray-200 rounded-xl p-5">
          <h2 class="font-bold text-gray-900 mb-4">Orders by Status</h2>
          <div class="space-y-2.5">
            <%= for {status, count} <- Enum.sort_by(@orders_by_status, fn {_, c} -> c end, :desc) do %>
              <%
                total = Map.values(@orders_by_status) |> Enum.sum()
                pct = if total > 0, do: round(count / total * 100), else: 0
                bar_color = case status do
                  "delivered"  -> "bg-emerald-400"
                  "pending"    -> "bg-yellow-400"
                  "processing" -> "bg-blue-400"
                  "shipped"    -> "bg-indigo-400"
                  "cancelled"  -> "bg-red-400"
                  "refunded"   -> "bg-gray-400"
                  _            -> "bg-gray-300"
                end
              %>
              <div>
                <div class="flex justify-between text-xs mb-1">
                  <span class="font-semibold text-gray-700 capitalize"><%= status %></span>
                  <span class="text-gray-500"><%= count %> (<%= pct %>%)</span>
                </div>
                <div class="h-2 bg-gray-100 rounded-full overflow-hidden">
                  <div class={"h-full rounded-full #{bar_color}"} style={"width: #{pct}%"}></div>
                </div>
              </div>
            <% end %>
            <%= if map_size(@orders_by_status) == 0 do %>
              <p class="text-sm text-gray-400 py-4 text-center">No orders yet</p>
            <% end %>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">

        <!-- Top products -->
        <div class="bg-white border border-gray-200 rounded-xl overflow-hidden">
          <div class="px-5 py-4 border-b border-gray-100">
            <h2 class="font-bold text-gray-900">Top Products by Revenue</h2>
          </div>
          <table class="w-full text-sm">
            <thead class="bg-gray-50">
              <tr>
                <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Product</th>
                <th class="text-center px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Units Sold</th>
                <th class="text-right px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Revenue</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <%= for {product, idx} <- Enum.with_index(@top_products, 1) do %>
                <tr class="hover:bg-gray-50">
                  <td class="px-5 py-3 flex items-center gap-2">
                    <span class="w-5 h-5 rounded-full bg-amber-100 text-amber-700 text-[10px] font-black flex items-center justify-center shrink-0"><%= idx %></span>
                    <span class="font-semibold text-gray-800 truncate"><%= product.name %></span>
                  </td>
                  <td class="px-5 py-3 text-center text-gray-600"><%= product.qty %></td>
                  <td class="px-5 py-3 text-right font-bold text-gray-900">KSh <%= format_money(product.revenue) %></td>
                </tr>
              <% end %>
              <%= if @top_products == [] do %>
                <tr><td colspan="3" class="px-5 py-8 text-center text-sm text-gray-400">No sales data yet</td></tr>
              <% end %>
            </tbody>
          </table>
        </div>

        <!-- Low stock alert -->
        <div class="bg-white border border-gray-200 rounded-xl overflow-hidden">
          <div class="flex items-center justify-between px-5 py-4 border-b border-gray-100">
            <h2 class="font-bold text-gray-900">Low Stock Alerts</h2>
            <span class={[
              "text-xs font-bold px-2 py-0.5 rounded",
              if(length(@low_stock) > 0, do: "bg-red-100 text-red-600", else: "bg-emerald-100 text-emerald-600")
            ]}>
              <%= length(@low_stock) %> alerts
            </span>
          </div>
          <ul class="divide-y divide-gray-100">
            <%= for v <- @low_stock do %>
              <li class="px-5 py-3 flex items-center justify-between gap-3">
                <div class="min-w-0">
                  <p class="text-sm font-semibold text-gray-800 truncate"><%= v.product.name %></p>
                  <p class="text-xs text-gray-400"><%= v.size %> · <span class="font-mono"><%= v.sku %></span></p>
                </div>
                <span class={[
                  "text-xs font-bold px-2 py-0.5 rounded shrink-0",
                  if(v.stock_quantity == 0, do: "bg-red-100 text-red-700", else: "bg-amber-100 text-amber-700")
                ]}>
                  <%= if v.stock_quantity == 0, do: "Out of stock", else: "#{v.stock_quantity} left" %>
                </span>
              </li>
            <% end %>
            <%= if @low_stock == [] do %>
              <li class="px-5 py-8 text-center text-sm text-gray-400">
                <svg class="w-8 h-8 text-emerald-400 mx-auto mb-2" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                </svg>
                All products well stocked
              </li>
            <% end %>
          </ul>
          <%= if @low_stock != [] do %>
            <div class="px-5 py-3 border-t border-gray-100">
              <a href="/admin/inventory" class="text-xs font-semibold text-amber-600 hover:underline">
                Manage inventory →
              </a>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end

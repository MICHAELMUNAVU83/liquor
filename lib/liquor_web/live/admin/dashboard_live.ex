defmodule LiquorWeb.Admin.DashboardLive do
  use LiquorWeb, :live_view

  alias Liquor.{Catalog, Accounts, Orders}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Admin – Dashboard", current_page: "admin", active_tab: "dashboard")
     |> load_stats(),
     layout: {LiquorWeb.Layouts, :admin}}
  end

  defp load_stats(socket) do
    assign(socket,
      total_products:   Catalog.count_products(),
      total_categories: Catalog.count_categories(),
      total_brands:     Catalog.count_brands(),
      total_users:      Accounts.count_users(),
      total_orders:     Orders.count_orders(),
      total_revenue:    Orders.total_revenue(),
      revenue_today:    Orders.revenue_today(),
      revenue_month:    Orders.revenue_this_month(),
      paid_orders:      Orders.count_paid_orders(),
      recent_orders:    Orders.recent_orders(8),
      low_stock:        Catalog.low_stock_variants(5),
      orders_by_status: Orders.orders_by_status(),
      top_products:     Orders.top_products(5),
      stock_value:      Catalog.total_stock_value()
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-screen-xl mx-auto px-4 py-8">
      <!-- Page header -->
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-2xl font-black text-gray-900">Dashboard</h1>
          <p class="text-sm text-gray-500 mt-0.5">Welcome back, <%= if @current_user, do: @current_user.first_name, else: "Admin" %></p>
        </div>
        <div class="flex items-center gap-3">
          <a href="/admin/sales" class="bg-amber-500 hover:bg-amber-600 text-white font-bold text-sm px-5 py-2.5 rounded-lg transition uppercase tracking-widest">
            + Record Sale
          </a>
        </div>
      </div>

      <!-- Revenue highlights -->
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
        <div class="bg-gradient-to-br from-amber-50 to-orange-50 border border-amber-200 rounded-xl p-5">
          <p class="text-xs font-bold uppercase tracking-widest text-amber-500 mb-1">Today's Revenue</p>
          <p class="text-3xl font-black text-amber-700">KSh <%= Decimal.round(@revenue_today || Decimal.new("0"), 2) %></p>
        </div>
        <div class="bg-gradient-to-br from-blue-50 to-indigo-50 border border-blue-200 rounded-xl p-5">
          <p class="text-xs font-bold uppercase tracking-widest text-blue-500 mb-1">This Month</p>
          <p class="text-3xl font-black text-blue-700">KSh <%= Decimal.round(@revenue_month || Decimal.new("0"), 2) %></p>
        </div>
        <div class="bg-gradient-to-br from-emerald-50 to-teal-50 border border-emerald-200 rounded-xl p-5">
          <p class="text-xs font-bold uppercase tracking-widest text-emerald-500 mb-1">Total Revenue</p>
          <p class="text-3xl font-black text-emerald-700">KSh <%= Decimal.round(@total_revenue || Decimal.new("0"), 2) %></p>
        </div>
      </div>

      <!-- KPI cards -->
      <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4 mb-8">
        <.stat_card label="Products"   value={@total_products}   href="/admin/products"   color="amber" />
        <.stat_card label="Categories" value={@total_categories} href="/admin/categories" color="blue" />
        <.stat_card label="Brands"     value={@total_brands}     href="/admin/brands"     color="violet" />
        <.stat_card label="Customers"  value={@total_users}      href="/admin/customers"  color="emerald" />
        <.stat_card label="Orders"     value={@total_orders}     href="/admin/orders"     color="rose" />
        <.stat_card label="Paid"       value={@paid_orders}      href="/admin/invoices"   color="teal" />
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
        <!-- Recent orders -->
        <div class="lg:col-span-2 bg-white border border-gray-200 rounded-xl overflow-hidden">
          <div class="flex items-center justify-between px-5 py-4 border-b border-gray-100">
            <h2 class="font-bold text-gray-900">Recent Orders</h2>
            <a href="/admin/orders" class="text-xs font-semibold text-amber-600 hover:underline">View all</a>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead class="bg-gray-50">
                <tr>
                  <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Order</th>
                  <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Customer</th>
                  <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Status</th>
                  <th class="text-right px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Total</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <%= for order <- @recent_orders do %>
                  <tr class="hover:bg-gray-50 transition">
                    <td class="px-5 py-3 font-mono text-xs text-gray-400">#<%= order.id %></td>
                    <td class="px-5 py-3 text-gray-700">
                      <%= if order.user, do: "#{order.user.first_name} #{order.user.last_name}", else: "Guest" %>
                    </td>
                    <td class="px-5 py-3">
                      <span class={["text-[10px] font-bold uppercase tracking-wide px-2 py-0.5 rounded", Liquor.Orders.Order.status_color(order.status)]}>
                        <%= order.status %>
                      </span>
                    </td>
                    <td class="px-5 py-3 text-right font-semibold text-gray-900">
                      KSh <%= Decimal.round(order.total_amount, 2) %>
                    </td>
                  </tr>
                <% end %>
                <%= if @recent_orders == [] do %>
                  <tr><td colspan="4" class="px-5 py-8 text-center text-sm text-gray-400">No orders yet</td></tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>

        <!-- Low stock alert -->
        <div class="bg-white border border-gray-200 rounded-xl overflow-hidden">
          <div class="flex items-center justify-between px-5 py-4 border-b border-gray-100">
            <h2 class="font-bold text-gray-900">Low Stock</h2>
            <span class={[
              "text-xs font-bold px-2 py-0.5 rounded",
              if(length(@low_stock) > 0, do: "bg-red-100 text-red-600", else: "bg-emerald-100 text-emerald-600")
            ]}>
              <%= length(@low_stock) %> alerts
            </span>
          </div>
          <ul class="divide-y divide-gray-100">
            <%= for v <- @low_stock do %>
              <li class="px-5 py-3 flex items-center justify-between gap-2">
                <div>
                  <p class="text-sm font-semibold text-gray-800 truncate max-w-[140px]"><%= v.product.name %></p>
                  <p class="text-xs text-gray-400"><%= v.size %> · <%= v.sku %></p>
                </div>
                <span class={[
                  "text-xs font-bold px-2 py-0.5 rounded",
                  if(v.stock_quantity == 0, do: "bg-red-100 text-red-600", else: "bg-amber-100 text-amber-700")
                ]}>
                  <%= v.stock_quantity %> left
                </span>
              </li>
            <% end %>
            <%= if @low_stock == [] do %>
              <li class="px-5 py-8 text-center text-sm text-gray-400">All products well stocked</li>
            <% end %>
          </ul>
          <div class="px-5 py-3 border-t border-gray-100">
            <a href="/admin/inventory" class="text-xs font-semibold text-amber-600 hover:underline">Manage inventory →</a>
          </div>
        </div>
      </div>

      <!-- Top products + quick actions -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Top products -->
        <div class="lg:col-span-2 bg-white border border-gray-200 rounded-xl overflow-hidden">
          <div class="flex items-center justify-between px-5 py-4 border-b border-gray-100">
            <h2 class="font-bold text-gray-900">Top Products</h2>
            <a href="/admin/reports" class="text-xs font-semibold text-amber-600 hover:underline">Full report</a>
          </div>
          <table class="w-full text-sm">
            <thead class="bg-gray-50">
              <tr>
                <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Product</th>
                <th class="text-center px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Units</th>
                <th class="text-right px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Revenue</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <%= for {product, idx} <- Enum.with_index(@top_products, 1) do %>
                <tr class="hover:bg-gray-50">
                  <td class="px-5 py-3 flex items-center gap-2">
                    <span class="w-5 h-5 rounded-full bg-amber-100 text-amber-700 text-[10px] font-black flex items-center justify-center"><%= idx %></span>
                    <span class="font-semibold text-gray-800 truncate"><%= product.name %></span>
                  </td>
                  <td class="px-5 py-3 text-center text-gray-500"><%= product.qty %></td>
                  <td class="px-5 py-3 text-right font-bold text-gray-900">KSh <%= Decimal.round(product.revenue, 2) %></td>
                </tr>
              <% end %>
              <%= if @top_products == [] do %>
                <tr><td colspan="3" class="px-5 py-8 text-center text-sm text-gray-400">No sales data yet</td></tr>
              <% end %>
            </tbody>
          </table>
        </div>

        <!-- Quick actions -->
        <div class="bg-white border border-gray-200 rounded-xl p-5">
          <h2 class="font-bold text-gray-900 mb-4">Quick Actions</h2>
          <div class="space-y-2">
            <a href="/admin/sales" class="flex items-center gap-3 px-4 py-3 rounded-lg bg-amber-50 hover:bg-amber-100 border border-amber-200 text-amber-800 font-semibold text-sm transition">
              <svg class="w-4 h-4 text-amber-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
              Record a Sale
            </a>
            <a href="/admin/invoices" class="flex items-center gap-3 px-4 py-3 rounded-lg bg-blue-50 hover:bg-blue-100 border border-blue-200 text-blue-800 font-semibold text-sm transition">
              <svg class="w-4 h-4 text-blue-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z"/></svg>
              View Invoices
            </a>
            <a href="/admin/inventory" class="flex items-center gap-3 px-4 py-3 rounded-lg bg-gray-50 hover:bg-gray-100 border border-gray-200 text-gray-800 font-semibold text-sm transition">
              <svg class="w-4 h-4 text-gray-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4"/></svg>
              Manage Inventory
            </a>
            <a href="/admin/customers" class="flex items-center gap-3 px-4 py-3 rounded-lg bg-gray-50 hover:bg-gray-100 border border-gray-200 text-gray-800 font-semibold text-sm transition">
              <svg class="w-4 h-4 text-gray-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/></svg>
              View Customers
            </a>
            <a href="/admin/reports" class="flex items-center gap-3 px-4 py-3 rounded-lg bg-gray-50 hover:bg-gray-100 border border-gray-200 text-gray-800 font-semibold text-sm transition">
              <svg class="w-4 h-4 text-gray-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/></svg>
              View Reports
            </a>
          </div>

          <div class="mt-5 pt-4 border-t border-gray-100">
            <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-2">Stock Value</p>
            <p class="text-xl font-black text-gray-900">KSh <%= Decimal.round(@stock_value || Decimal.new("0"), 2) %></p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp stat_card(assigns) do
    color_classes = %{
      "amber"   => "bg-amber-50 text-amber-700 border-amber-200",
      "blue"    => "bg-blue-50 text-blue-700 border-blue-200",
      "violet"  => "bg-violet-50 text-violet-700 border-violet-200",
      "emerald" => "bg-emerald-50 text-emerald-700 border-emerald-200",
      "rose"    => "bg-rose-50 text-rose-700 border-rose-200",
      "zinc"    => "bg-zinc-50 text-zinc-700 border-zinc-200",
      "teal"    => "bg-teal-50 text-teal-700 border-teal-200"
    }
    assigns = assign(assigns, :color_class, color_classes[assigns.color] || color_classes["zinc"])

    ~H"""
    <a href={@href} class={["border rounded-xl p-5 flex flex-col gap-1 hover:shadow-md transition", @color_class]}>
      <span class="text-2xl font-black"><%= @value %></span>
      <span class="text-xs font-semibold uppercase tracking-wide opacity-70"><%= @label %></span>
    </a>
    """
  end
end

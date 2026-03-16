defmodule LiquorWeb.Admin.CustomersLive do
  use LiquorWeb, :live_view

  alias Liquor.{Accounts, Orders}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title:       "Admin – Customers",
       active_tab:       "customers",
       search:           "",
       selected_customer: nil,
       customer_orders:  []
     )
     |> load_customers(),
     layout: {LiquorWeb.Layouts, :admin}}
  end

  defp load_customers(socket) do
    customers = Accounts.list_users_with_stats(search: socket.assigns.search)
    assign(socket, customers: customers)
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, socket |> assign(search: q) |> load_customers()}
  end

  def handle_event("view_customer", %{"id" => id}, socket) do
    id_int = String.to_integer(id)
    customer = Accounts.get_user!(id_int)
    orders   = Orders.list_orders() |> Enum.filter(&(&1.user_id == id_int))
    {:noreply, assign(socket, selected_customer: customer, customer_orders: orders)}
  end

  def handle_event("close_customer", _params, socket) do
    {:noreply, assign(socket, selected_customer: nil, customer_orders: [])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-screen-xl mx-auto px-4 py-8">

      <!-- Header -->
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-2xl font-black text-gray-900">Customers</h1>
          <p class="text-sm text-gray-500 mt-0.5"><%= length(@customers) %> registered customers</p>
        </div>
      </div>

      <!-- Stats summary -->
      <div class="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-6">
        <div class="bg-white border border-gray-200 rounded-xl p-4">
          <p class="text-2xl font-black text-gray-900"><%= length(@customers) %></p>
          <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide mt-0.5">Total Customers</p>
        </div>
        <div class="bg-emerald-50 border border-emerald-200 rounded-xl p-4">
          <p class="text-2xl font-black text-emerald-700">
            <%= Enum.count(@customers, fn c -> c.order_count > 0 end) %>
          </p>
          <p class="text-xs font-semibold text-emerald-600 uppercase tracking-wide mt-0.5">With Orders</p>
        </div>
        <div class="bg-amber-50 border border-amber-200 rounded-xl p-4">
          <p class="text-2xl font-black text-amber-700">
            <%= Enum.count(@customers, fn c -> c.is_active end) %>
          </p>
          <p class="text-xs font-semibold text-amber-600 uppercase tracking-wide mt-0.5">Active</p>
        </div>
        <div class="bg-blue-50 border border-blue-200 rounded-xl p-4">
          <p class="text-xl font-black text-blue-700">
            KSh <%= Enum.reduce(@customers, Decimal.new("0"), fn c, acc -> Decimal.add(acc, c.lifetime_value) end) |> Decimal.round(0) %>
          </p>
          <p class="text-xs font-semibold text-blue-600 uppercase tracking-wide mt-0.5">Total LTV</p>
        </div>
      </div>

      <!-- Search -->
      <div class="mb-4">
        <input
          type="text"
          placeholder="Search by name or email…"
          value={@search}
          phx-keyup="search"
          name="q"
          class="border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400 w-72"
        />
      </div>

      <!-- Table -->
      <div class="bg-white border border-gray-200 rounded-xl overflow-hidden">
        <table class="w-full text-sm">
          <thead class="bg-gray-50 border-b border-gray-200">
            <tr>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Customer</th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Email</th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Phone</th>
              <th class="text-center px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Orders</th>
              <th class="text-right px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Lifetime Value</th>
              <th class="text-center px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Status</th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Joined</th>
              <th class="px-5 py-3"></th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <%= for customer <- @customers do %>
              <tr class="hover:bg-gray-50 transition">
                <td class="px-5 py-3">
                  <div class="flex items-center gap-3">
                    <div class="w-8 h-8 rounded-full bg-amber-100 flex items-center justify-center text-amber-700 font-black text-sm shrink-0">
                      <%= String.first(customer.first_name || "?") %>
                    </div>
                    <span class="font-semibold text-gray-800">
                      <%= customer.first_name %> <%= customer.last_name %>
                    </span>
                  </div>
                </td>
                <td class="px-5 py-3 text-gray-500"><%= customer.email %></td>
                <td class="px-5 py-3 text-gray-500"><%= customer.phone || "—" %></td>
                <td class="px-5 py-3 text-center">
                  <span class={[
                    "text-xs font-bold px-2 py-0.5 rounded",
                    if(customer.order_count > 0, do: "bg-blue-100 text-blue-700", else: "bg-gray-100 text-gray-500")
                  ]}>
                    <%= customer.order_count %>
                  </span>
                </td>
                <td class="px-5 py-3 text-right font-semibold text-gray-900">
                  KSh <%= Decimal.round(customer.lifetime_value, 2) %>
                </td>
                <td class="px-5 py-3 text-center">
                  <span class={[
                    "text-[10px] font-bold uppercase tracking-wide px-2 py-0.5 rounded",
                    if(customer.is_active, do: "bg-emerald-100 text-emerald-700", else: "bg-red-100 text-red-600")
                  ]}>
                    <%= if customer.is_active, do: "Active", else: "Inactive" %>
                  </span>
                </td>
                <td class="px-5 py-3 text-gray-400 text-xs">
                  <%= Calendar.strftime(customer.inserted_at, "%b %d, %Y") %>
                </td>
                <td class="px-5 py-3 text-right">
                  <button
                    phx-click="view_customer"
                    phx-value-id={customer.id}
                    class="text-xs font-semibold text-amber-600 hover:underline"
                  >
                    View
                  </button>
                </td>
              </tr>
            <% end %>
            <%= if @customers == [] do %>
              <tr><td colspan="8" class="px-5 py-12 text-center text-sm text-gray-400">No customers found</td></tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Customer detail panel -->
    <%= if @selected_customer do %>
      <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
        <div
          class="bg-white rounded-xl shadow-2xl w-full max-w-2xl max-h-[90vh] overflow-y-auto"
          phx-window-keydown="close_customer"
          phx-key="Escape"
        >
          <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200 sticky top-0 bg-white">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-full bg-amber-500 flex items-center justify-center text-white font-black">
                <%= String.first(@selected_customer.first_name || "?") %>
              </div>
              <div>
                <h2 class="text-lg font-black text-gray-900">
                  <%= @selected_customer.first_name %> <%= @selected_customer.last_name %>
                </h2>
                <p class="text-xs text-gray-400"><%= @selected_customer.email %></p>
              </div>
            </div>
            <button phx-click="close_customer" class="text-gray-400 hover:text-gray-700">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
              </svg>
            </button>
          </div>

          <div class="p-6 space-y-6">
            <!-- Customer info -->
            <div class="grid grid-cols-2 gap-4">
              <div class="bg-gray-50 rounded-xl p-4">
                <p class="text-[10px] font-bold uppercase tracking-widest text-gray-400 mb-2">Contact</p>
                <p class="text-sm text-gray-700"><%= @selected_customer.email %></p>
                <p class="text-sm text-gray-500"><%= @selected_customer.phone || "No phone" %></p>
              </div>
              <div class="bg-gray-50 rounded-xl p-4">
                <p class="text-[10px] font-bold uppercase tracking-widest text-gray-400 mb-2">Account</p>
                <p class="text-sm text-gray-700">
                  Status:
                  <span class={["font-semibold", if(@selected_customer.is_active, do: "text-emerald-600", else: "text-red-500")]}>
                    <%= if @selected_customer.is_active, do: "Active", else: "Inactive" %>
                  </span>
                </p>
                <p class="text-xs text-gray-400 mt-1">
                  Joined <%= Calendar.strftime(@selected_customer.inserted_at, "%B %d, %Y") %>
                </p>
              </div>
            </div>

            <!-- Order history -->
            <div>
              <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-3">
                Order History (<%= length(@customer_orders) %>)
              </p>
              <%= if @customer_orders == [] do %>
                <p class="text-sm text-gray-400 py-4 text-center border border-gray-200 rounded-xl">No orders yet</p>
              <% else %>
                <table class="w-full text-sm border border-gray-200 rounded-xl overflow-hidden">
                  <thead class="bg-gray-50">
                    <tr>
                      <th class="text-left px-4 py-2.5 text-xs font-semibold text-gray-500">Order</th>
                      <th class="text-left px-4 py-2.5 text-xs font-semibold text-gray-500">Date</th>
                      <th class="text-left px-4 py-2.5 text-xs font-semibold text-gray-500">Status</th>
                      <th class="text-right px-4 py-2.5 text-xs font-semibold text-gray-500">Total</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-100">
                    <%= for order <- @customer_orders do %>
                      <tr>
                        <td class="px-4 py-3 font-mono text-xs text-gray-500">#<%= order.id %></td>
                        <td class="px-4 py-3 text-gray-400 text-xs"><%= Calendar.strftime(order.inserted_at, "%b %d, %Y") %></td>
                        <td class="px-4 py-3">
                          <span class={["text-[10px] font-bold uppercase tracking-wide px-2 py-0.5 rounded", Liquor.Orders.Order.status_color(order.status)]}>
                            <%= order.status %>
                          </span>
                        </td>
                        <td class="px-4 py-3 text-right font-semibold text-gray-900">
                          KSh <%= Decimal.round(order.total_amount, 2) %>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                  <tfoot class="border-t-2 border-gray-200 bg-gray-50">
                    <tr>
                      <td colspan="3" class="px-4 py-2.5 text-sm font-bold text-gray-600 text-right">Total Spent (paid)</td>
                      <td class="px-4 py-2.5 text-right font-black text-amber-600">
                        KSh <%= @customer_orders
                             |> Enum.filter(&(&1.payment_status == "paid"))
                             |> Enum.reduce(Decimal.new("0"), &Decimal.add(&2, &1.total_amount))
                             |> Decimal.round(2) %>
                      </td>
                    </tr>
                  </tfoot>
                </table>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end
end

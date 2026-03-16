defmodule LiquorWeb.Admin.OrdersLive do
  use LiquorWeb, :live_view

  alias Liquor.Orders
  alias Liquor.Orders.Order

  @statuses ["", "pending", "processing", "shipped", "delivered", "cancelled", "refunded"]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Admin – Orders", current_page: "admin", active_tab: "orders",
                status_filter: "", selected_order: nil)
     |> load_orders(),
     layout: {LiquorWeb.Layouts, :admin}}
  end

  defp load_orders(socket) do
    assign(socket, orders: Orders.list_orders(status: socket.assigns.status_filter))
  end

  @impl true
  def handle_event("filter_status", %{"status" => s}, socket) do
    {:noreply, socket |> assign(status_filter: s) |> load_orders()}
  end

  def handle_event("view_order", %{"id" => id}, socket) do
    order = Orders.get_order!(id)
    {:noreply, assign(socket, selected_order: order)}
  end

  def handle_event("close_order", _params, socket) do
    {:noreply, assign(socket, selected_order: nil)}
  end

  def handle_event("update_status", %{"status" => status}, socket) do
    order = socket.assigns.selected_order
    {:ok, updated} = Orders.update_order(order, %{status: status})
    {:noreply,
     socket
     |> put_flash(:info, "Order status updated to #{status}.")
     |> assign(selected_order: Orders.get_order!(updated.id))
     |> load_orders()}
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :statuses, @statuses)

    ~H"""
    <div class="max-w-screen-xl mx-auto px-4 py-8">
      <div class="flex items-center justify-between mb-6 flex-wrap gap-3">
        <h1 class="text-2xl font-black text-zinc-900">Orders</h1>
        <!-- Status filter tabs -->
        <div class="flex gap-1 flex-wrap">
          <%= for s <- @statuses do %>
            <button
              phx-click="filter_status"
              phx-value-status={s}
              class={[
                "text-xs font-semibold px-3 py-1.5 rounded border transition",
                if(@status_filter == s,
                  do: "bg-zinc-900 text-white border-zinc-900",
                  else: "border-zinc-200 text-zinc-600 hover:border-zinc-400")
              ]}
            >
              <%= if s == "", do: "All", else: String.capitalize(s) %>
            </button>
          <% end %>
        </div>
      </div>

      <div class="border border-zinc-200 rounded-lg overflow-hidden">
        <table class="w-full text-sm">
          <thead class="bg-zinc-50 border-b border-zinc-200">
            <tr>
              <th class="text-left px-5 py-3 text-xs font-semibold text-zinc-500 uppercase tracking-wide">#</th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-zinc-500 uppercase tracking-wide">Customer</th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-zinc-500 uppercase tracking-wide">Date</th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-zinc-500 uppercase tracking-wide">Status</th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-zinc-500 uppercase tracking-wide">Payment</th>
              <th class="text-right px-5 py-3 text-xs font-semibold text-zinc-500 uppercase tracking-wide">Total</th>
              <th class="text-right px-5 py-3 text-xs font-semibold text-zinc-500 uppercase tracking-wide"></th>
            </tr>
          </thead>
          <tbody class="divide-y divide-zinc-100">
            <%= for order <- @orders do %>
              <tr class="hover:bg-zinc-50 transition">
                <td class="px-5 py-3 font-mono text-xs text-zinc-500">#<%= order.id %></td>
                <td class="px-5 py-3 text-zinc-700">
                  <%= if order.user, do: "#{order.user.first_name} #{order.user.last_name}", else: order.shipping_name || "Guest" %>
                </td>
                <td class="px-5 py-3 text-zinc-500 text-xs">
                  <%= Calendar.strftime(order.inserted_at, "%b %d, %Y") %>
                </td>
                <td class="px-5 py-3">
                  <span class={["text-[10px] font-bold uppercase tracking-wide px-2 py-0.5 rounded", Order.status_color(order.status)]}>
                    <%= order.status %>
                  </span>
                </td>
                <td class="px-5 py-3">
                  <span class={[
                    "text-[10px] font-bold uppercase tracking-wide px-2 py-0.5 rounded",
                    case order.payment_status do
                      "paid"     -> "bg-emerald-100 text-emerald-700"
                      "refunded" -> "bg-zinc-100 text-zinc-600"
                      _          -> "bg-yellow-100 text-yellow-700"
                    end
                  ]}>
                    <%= order.payment_status %>
                  </span>
                </td>
                <td class="px-5 py-3 text-right font-semibold text-zinc-900">
                  KSh <%= Decimal.round(order.total_amount, 2) %>
                </td>
                <td class="px-5 py-3 text-right">
                  <button phx-click="view_order" phx-value-id={order.id} class="text-xs font-semibold text-amber-600 hover:underline">
                    View
                  </button>
                </td>
              </tr>
            <% end %>
            <%= if @orders == [] do %>
              <tr><td colspan="7" class="px-5 py-12 text-center text-sm text-zinc-400">No orders found</td></tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Order detail panel -->
    <%= if @selected_order do %>
      <div class="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/50 px-4">
        <div class="bg-white rounded-t-xl sm:rounded-xl shadow-xl w-full max-w-2xl max-h-[90vh] overflow-y-auto" phx-window-keydown="close_order" phx-key="Escape">
          <div class="flex items-center justify-between px-6 py-4 border-b border-zinc-200 sticky top-0 bg-white">
            <h2 class="text-lg font-black text-zinc-900">Order #<%= @selected_order.id %></h2>
            <button phx-click="close_order" class="text-zinc-400 hover:text-zinc-700">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
            </button>
          </div>
          <div class="p-6 space-y-6">
            <!-- Status update -->
            <div class="flex items-center gap-3 flex-wrap">
              <span class="text-sm font-semibold text-zinc-700">Status:</span>
              <span class={["text-xs font-bold uppercase tracking-wide px-2 py-0.5 rounded", Order.status_color(@selected_order.status)]}>
                <%= @selected_order.status %>
              </span>
              <form phx-change="update_status" class="ml-auto">
                <select name="status" class="text-sm border border-zinc-200 rounded px-3 py-1.5 bg-white focus:outline-none focus:ring-1 focus:ring-amber-400">
                  <%= for s <- tl(@statuses) do %>
                    <option value={s} selected={@selected_order.status == s}><%= String.capitalize(s) %></option>
                  <% end %>
                </select>
              </form>
            </div>

            <!-- Customer + shipping -->
            <div class="grid grid-cols-2 gap-4 text-sm">
              <div>
                <p class="text-xs font-bold uppercase tracking-wide text-zinc-400 mb-1">Customer</p>
                <%= if @selected_order.user do %>
                  <p class="font-semibold text-zinc-800"><%= @selected_order.user.first_name %> <%= @selected_order.user.last_name %></p>
                  <p class="text-zinc-500"><%= @selected_order.user.email %></p>
                <% else %>
                  <p class="text-zinc-500">Guest</p>
                <% end %>
              </div>
              <div>
                <p class="text-xs font-bold uppercase tracking-wide text-zinc-400 mb-1">Ship To</p>
                <p class="text-zinc-700"><%= @selected_order.shipping_name %></p>
                <p class="text-zinc-500"><%= @selected_order.shipping_line1 %></p>
                <p class="text-zinc-500"><%= @selected_order.shipping_city %>, <%= @selected_order.shipping_state %> <%= @selected_order.shipping_zip %></p>
              </div>
            </div>

            <!-- Items -->
            <div>
              <p class="text-xs font-bold uppercase tracking-wide text-zinc-400 mb-3">Items</p>
              <table class="w-full text-sm border border-zinc-200 rounded overflow-hidden">
                <thead class="bg-zinc-50">
                  <tr>
                    <th class="text-left px-4 py-2 text-xs font-semibold text-zinc-500">Product</th>
                    <th class="text-center px-4 py-2 text-xs font-semibold text-zinc-500">Qty</th>
                    <th class="text-right px-4 py-2 text-xs font-semibold text-zinc-500">Subtotal</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-zinc-100">
                  <%= for item <- @selected_order.items do %>
                    <tr>
                      <td class="px-4 py-2">
                        <p class="font-semibold text-zinc-800"><%= item.product_name %></p>
                        <p class="text-xs text-zinc-400"><%= item.variant_size %> · <%= item.variant_sku %></p>
                      </td>
                      <td class="px-4 py-2 text-center text-zinc-600"><%= item.quantity %></td>
                      <td class="px-4 py-2 text-right font-semibold text-zinc-900">KSh <%= Decimal.round(item.subtotal, 2) %></td>
                    </tr>
                  <% end %>
                </tbody>
                <tfoot class="border-t-2 border-zinc-200 bg-zinc-50">
                  <tr>
                    <td colspan="2" class="px-4 py-2 text-sm font-bold text-zinc-700 text-right">Total</td>
                    <td class="px-4 py-2 text-right font-black text-zinc-900">KSh <%= Decimal.round(@selected_order.total_amount, 2) %></td>
                  </tr>
                </tfoot>
              </table>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end
end

defmodule LiquorWeb.Admin.InvoicesLive do
  use LiquorWeb, :live_view

  alias Liquor.Orders
  alias Liquor.Orders.Order

  @statuses ["", "pending", "processing", "shipped", "delivered", "cancelled", "refunded"]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title:      "Admin – Invoices",
       active_tab:      "invoices",
       status_filter:   "",
       selected_order:  nil,
       search:          ""
     )
     |> load_invoices(),
     layout: {LiquorWeb.Layouts, :admin}}
  end

  defp load_invoices(socket) do
    orders = Orders.list_orders(status: socket.assigns.status_filter)

    orders =
      if socket.assigns.search != "" do
        term = String.downcase(socket.assigns.search)
        Enum.filter(orders, fn o ->
          inv = invoice_number(o.id)
          customer = customer_name(o)
          String.contains?(String.downcase(inv), term) ||
          String.contains?(String.downcase(customer), term)
        end)
      else
        orders
      end

    assign(socket, invoices: orders)
  end

  defp invoice_number(id), do: "INV-#{String.pad_leading(to_string(id), 5, "0")}"

  defp customer_name(order) do
    if order.user do
      "#{order.user.first_name} #{order.user.last_name}"
    else
      order.shipping_name || "Guest"
    end
  end

  defp invoice_status(order) do
    case {order.payment_status, order.status} do
      {"paid", _}           -> "paid"
      {"refunded", _}       -> "refunded"
      {_, "cancelled"}      -> "void"
      {_, "delivered"}      -> "sent"
      {_, "shipped"}        -> "sent"
      _                     -> "draft"
    end
  end

  defp status_color(status) do
    case status do
      "paid"     -> "bg-emerald-100 text-emerald-700"
      "sent"     -> "bg-blue-100 text-blue-700"
      "draft"    -> "bg-gray-100 text-gray-600"
      "void"     -> "bg-red-100 text-red-600"
      "refunded" -> "bg-amber-100 text-amber-700"
      _          -> "bg-gray-100 text-gray-600"
    end
  end

  @impl true
  def handle_event("filter_status", %{"status" => s}, socket) do
    {:noreply, socket |> assign(status_filter: s) |> load_invoices()}
  end

  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, socket |> assign(search: q) |> load_invoices()}
  end

  def handle_event("view_invoice", %{"id" => id}, socket) do
    order = Orders.get_order!(id)
    {:noreply, assign(socket, selected_order: order)}
  end

  def handle_event("close_invoice", _params, socket) do
    {:noreply, assign(socket, selected_order: nil)}
  end

  def handle_event("mark_paid", %{"id" => id}, socket) do
    order = Orders.get_order!(id)
    {:ok, _} = Orders.update_order(order, %{payment_status: "paid", status: "delivered"})
    {:noreply,
     socket
     |> put_flash(:info, "Invoice #{invoice_number(order.id)} marked as paid.")
     |> assign(selected_order: nil)
     |> load_invoices()}
  end

  def handle_event("update_status", %{"status" => status}, socket) do
    order = socket.assigns.selected_order
    {:ok, updated} = Orders.update_order(order, %{status: status})
    {:noreply,
     socket
     |> put_flash(:info, "Invoice updated.")
     |> assign(selected_order: Orders.get_order!(updated.id))
     |> load_invoices()}
  end

  @impl true
  def render(assigns) do
    statuses = @statuses
    assigns = assign(assigns, :statuses, statuses)

    ~H"""
    <div class="max-w-screen-xl mx-auto px-4 py-8">

      <!-- Header -->
      <div class="flex items-center justify-between mb-6 flex-wrap gap-3">
        <div>
          <h1 class="text-2xl font-black text-gray-900">Invoices</h1>
          <p class="text-sm text-gray-500 mt-0.5">Track and manage all invoices</p>
        </div>
        <a
          href="/admin/sales"
          class="bg-amber-500 hover:bg-amber-600 text-white font-bold text-sm px-5 py-2.5 rounded-lg transition uppercase tracking-widest"
        >
          + New Sale
        </a>
      </div>

      <!-- Summary cards -->
      <div class="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-6">
        <div class="bg-white border border-gray-200 rounded-xl p-4">
          <p class="text-2xl font-black text-gray-900"><%= length(@invoices) %></p>
          <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide mt-0.5">Total</p>
        </div>
        <div class="bg-emerald-50 border border-emerald-200 rounded-xl p-4">
          <p class="text-2xl font-black text-emerald-700">
            <%= Enum.count(@invoices, fn o -> invoice_status(o) == "paid" end) %>
          </p>
          <p class="text-xs font-semibold text-emerald-600 uppercase tracking-wide mt-0.5">Paid</p>
        </div>
        <div class="bg-blue-50 border border-blue-200 rounded-xl p-4">
          <p class="text-2xl font-black text-blue-700">
            <%= Enum.count(@invoices, fn o -> invoice_status(o) == "draft" end) %>
          </p>
          <p class="text-xs font-semibold text-blue-600 uppercase tracking-wide mt-0.5">Draft</p>
        </div>
        <div class="bg-red-50 border border-red-200 rounded-xl p-4">
          <p class="text-2xl font-black text-red-700">
            <%= Enum.count(@invoices, fn o -> invoice_status(o) == "void" end) %>
          </p>
          <p class="text-xs font-semibold text-red-600 uppercase tracking-wide mt-0.5">Void</p>
        </div>
      </div>

      <!-- Filters -->
      <div class="flex flex-wrap items-center gap-3 mb-4">
        <input
          type="text"
          placeholder="Search invoices or customers…"
          value={@search}
          phx-keyup="search"
          name="q"
          class="border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400 w-64"
        />
        <div class="flex gap-1 flex-wrap">
          <%= for s <- @statuses do %>
            <button
              phx-click="filter_status"
              phx-value-status={s}
              class={[
                "text-xs font-semibold px-3 py-1.5 rounded-lg border transition",
                if(@status_filter == s,
                  do: "bg-amber-500 text-white border-amber-500",
                  else: "border-gray-200 text-gray-600 hover:border-gray-300 bg-white")
              ]}
            >
              <%= if s == "", do: "All", else: String.capitalize(s) %>
            </button>
          <% end %>
        </div>
      </div>

      <!-- Table -->
      <div class="bg-white border border-gray-200 rounded-xl overflow-hidden">
        <table class="w-full text-sm">
          <thead class="bg-gray-50 border-b border-gray-200">
            <tr>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Invoice</th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Customer</th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Date</th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Order Status</th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Invoice Status</th>
              <th class="text-right px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Amount</th>
              <th class="px-5 py-3"></th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <%= for order <- @invoices do %>
              <tr class="hover:bg-gray-50 transition">
                <td class="px-5 py-3 font-mono text-sm font-bold text-gray-700"><%= invoice_number(order.id) %></td>
                <td class="px-5 py-3 text-gray-700"><%= customer_name(order) %></td>
                <td class="px-5 py-3 text-gray-400 text-xs"><%= Calendar.strftime(order.inserted_at, "%b %d, %Y") %></td>
                <td class="px-5 py-3">
                  <span class={["text-[10px] font-bold uppercase tracking-wide px-2 py-0.5 rounded", Order.status_color(order.status)]}>
                    <%= order.status %>
                  </span>
                </td>
                <td class="px-5 py-3">
                  <span class={["text-[10px] font-bold uppercase tracking-wide px-2 py-0.5 rounded", status_color(invoice_status(order))]}>
                    <%= invoice_status(order) %>
                  </span>
                </td>
                <td class="px-5 py-3 text-right font-bold text-gray-900">
                  KSh <%= Decimal.round(order.total_amount, 2) %>
                </td>
                <td class="px-5 py-3 text-right">
                  <button
                    phx-click="view_invoice"
                    phx-value-id={order.id}
                    class="text-xs font-semibold text-amber-600 hover:underline"
                  >
                    View
                  </button>
                </td>
              </tr>
            <% end %>
            <%= if @invoices == [] do %>
              <tr><td colspan="7" class="px-5 py-12 text-center text-sm text-gray-400">No invoices found</td></tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Invoice detail modal -->
    <%= if @selected_order do %>
      <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
        <div
          class="bg-white rounded-xl shadow-2xl w-full max-w-2xl max-h-[90vh] overflow-y-auto"
          phx-window-keydown="close_invoice"
          phx-key="Escape"
        >
          <!-- Invoice header -->
          <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200 sticky top-0 bg-white">
            <div>
              <h2 class="text-lg font-black text-gray-900"><%= invoice_number(@selected_order.id) %></h2>
              <p class="text-xs text-gray-400"><%= Calendar.strftime(@selected_order.inserted_at, "%B %d, %Y") %></p>
            </div>
            <div class="flex items-center gap-3">
              <%= if invoice_status(@selected_order) != "paid" do %>
                <button
                  phx-click="mark_paid"
                  phx-value-id={@selected_order.id}
                  class="bg-emerald-500 hover:bg-emerald-600 text-white text-sm font-bold px-4 py-2 rounded-lg transition"
                >
                  Mark as Paid
                </button>
              <% end %>
              <button phx-click="close_invoice" class="text-gray-400 hover:text-gray-700">
                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
                </svg>
              </button>
            </div>
          </div>

          <div class="p-6 space-y-6">
            <!-- Status badges -->
            <div class="flex items-center gap-3 flex-wrap">
              <span class={["text-xs font-bold uppercase tracking-wide px-3 py-1 rounded-full", Order.status_color(@selected_order.status)]}>
                Order: <%= @selected_order.status %>
              </span>
              <span class={["text-xs font-bold uppercase tracking-wide px-3 py-1 rounded-full", status_color(invoice_status(@selected_order))]}>
                Invoice: <%= invoice_status(@selected_order) %>
              </span>
              <span class={[
                "text-xs font-bold uppercase tracking-wide px-3 py-1 rounded-full",
                case @selected_order.payment_status do
                  "paid"     -> "bg-emerald-100 text-emerald-700"
                  "refunded" -> "bg-gray-100 text-gray-600"
                  _          -> "bg-yellow-100 text-yellow-700"
                end
              ]}>
                Payment: <%= @selected_order.payment_status %>
              </span>
            </div>

            <!-- Update order status -->
            <div class="flex items-center gap-3">
              <span class="text-sm font-semibold text-gray-600">Update Order Status:</span>
              <form phx-change="update_status">
                <select name="status" class="text-sm border border-gray-200 rounded-lg px-3 py-1.5 bg-white focus:outline-none focus:ring-1 focus:ring-amber-400">
                  <%= for s <- tl(@statuses) do %>
                    <option value={s} selected={@selected_order.status == s}><%= String.capitalize(s) %></option>
                  <% end %>
                </select>
              </form>
            </div>

            <!-- Bill To / From -->
            <div class="grid grid-cols-2 gap-6">
              <div class="bg-gray-50 rounded-xl p-4">
                <p class="text-[10px] font-bold uppercase tracking-widest text-gray-400 mb-2">Bill From</p>
                <p class="font-bold text-gray-900"><%= Liquor.StoreConfig.short_name() %></p>
                <p class="text-sm text-gray-500"><%= Liquor.StoreConfig.email() %></p>
              </div>
              <div class="bg-gray-50 rounded-xl p-4">
                <p class="text-[10px] font-bold uppercase tracking-widest text-gray-400 mb-2">Bill To</p>
                <%= if @selected_order.user do %>
                  <p class="font-bold text-gray-900"><%= @selected_order.user.first_name %> <%= @selected_order.user.last_name %></p>
                  <p class="text-sm text-gray-500"><%= @selected_order.user.email %></p>
                <% else %>
                  <p class="font-bold text-gray-900"><%= @selected_order.shipping_name || "Guest" %></p>
                <% end %>
                <p class="text-sm text-gray-500 mt-1">
                  <%= @selected_order.shipping_line1 %><br/>
                  <%= @selected_order.shipping_city %>, <%= @selected_order.shipping_state %> <%= @selected_order.shipping_zip %>
                </p>
              </div>
            </div>

            <!-- Line items -->
            <div>
              <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-3">Items</p>
              <table class="w-full text-sm border border-gray-200 rounded-xl overflow-hidden">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="text-left px-4 py-2.5 text-xs font-semibold text-gray-500">Description</th>
                    <th class="text-center px-4 py-2.5 text-xs font-semibold text-gray-500">Qty</th>
                    <th class="text-right px-4 py-2.5 text-xs font-semibold text-gray-500">Unit Price</th>
                    <th class="text-right px-4 py-2.5 text-xs font-semibold text-gray-500">Subtotal</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                  <%= for item <- @selected_order.items do %>
                    <tr>
                      <td class="px-4 py-3">
                        <p class="font-semibold text-gray-800"><%= item.product_name %></p>
                        <p class="text-xs text-gray-400"><%= item.variant_size %> · <%= item.variant_sku %></p>
                      </td>
                      <td class="px-4 py-3 text-center text-gray-600"><%= item.quantity %></td>
                      <td class="px-4 py-3 text-right text-gray-600">KSh <%= Decimal.round(item.unit_price, 2) %></td>
                      <td class="px-4 py-3 text-right font-semibold text-gray-900">KSh <%= Decimal.round(item.subtotal, 2) %></td>
                    </tr>
                  <% end %>
                </tbody>
                <tfoot class="border-t-2 border-gray-200 bg-gray-50">
                  <%= if Decimal.compare(@selected_order.discount_amount || Decimal.new("0"), Decimal.new("0")) == :gt do %>
                    <tr>
                      <td colspan="3" class="px-4 py-2 text-sm text-gray-500 text-right">Discount</td>
                      <td class="px-4 py-2 text-right text-red-600">-KSh <%= Decimal.round(@selected_order.discount_amount, 2) %></td>
                    </tr>
                  <% end %>
                  <%= if Decimal.compare(@selected_order.shipping_amount || Decimal.new("0"), Decimal.new("0")) == :gt do %>
                    <tr>
                      <td colspan="3" class="px-4 py-2 text-sm text-gray-500 text-right">Shipping</td>
                      <td class="px-4 py-2 text-right text-gray-600">KSh <%= Decimal.round(@selected_order.shipping_amount, 2) %></td>
                    </tr>
                  <% end %>
                  <tr>
                    <td colspan="3" class="px-4 py-3 text-sm font-bold text-gray-700 text-right">Total</td>
                    <td class="px-4 py-3 text-right font-black text-lg text-gray-900">KSh <%= Decimal.round(@selected_order.total_amount, 2) %></td>
                  </tr>
                </tfoot>
              </table>
            </div>

            <%= if @selected_order.notes do %>
              <div class="bg-amber-50 border border-amber-200 rounded-xl p-4">
                <p class="text-xs font-bold uppercase tracking-widest text-amber-600 mb-1">Notes</p>
                <p class="text-sm text-amber-800"><%= @selected_order.notes %></p>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    <% end %>
    """
  end
end

defmodule LiquorWeb.Admin.SalesLive do
  use LiquorWeb, :live_view

  alias Liquor.{Catalog, Accounts, Orders}

  @impl true
  def mount(_params, _session, socket) do
    variants = Catalog.list_default_variants_for_products()
    users    = Accounts.list_users()

    {:ok,
     socket
     |> assign(
       page_title:     "Admin – Sales",
       active_tab:     "sales",
       variants:       variants,
       users:          users,
       cart_items:     [],
       customer_id:    nil,
       customer_name:  "",
       customer_email: "",
       payment_method: "cash",
       notes:          "",
       search_product: "",
       show_confirm:   false,
       recent_sales:   Orders.list_orders(status: "delivered") |> Enum.take(10)
     ),
     layout: {LiquorWeb.Layouts, :admin}}
  end

  @impl true
  def handle_event("search_product", %{"q" => q}, socket) do
    {:noreply, assign(socket, search_product: q)}
  end

  def handle_event("add_to_cart", %{"variant_id" => vid}, socket) do
    variant = Enum.find(socket.assigns.variants, &(to_string(&1.id) == vid))

    if variant do
      cart = socket.assigns.cart_items
      existing = Enum.find_index(cart, &(&1.variant_id == variant.id))

      updated_cart =
        if existing do
          List.update_at(cart, existing, &%{&1 | qty: &1.qty + 1})
        else
          cart ++ [%{
            variant_id:   variant.id,
            product_name: variant.product.name,
            sku:          variant.sku,
            size:         variant.size,
            price:        variant.price,
            qty:          1
          }]
        end

      {:noreply, assign(socket, cart_items: updated_cart)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("remove_from_cart", %{"variant_id" => vid}, socket) do
    vid_int = String.to_integer(vid)
    updated = Enum.reject(socket.assigns.cart_items, &(&1.variant_id == vid_int))
    {:noreply, assign(socket, cart_items: updated)}
  end

  def handle_event("update_qty", %{"variant_id" => vid, "qty" => qty_str}, socket) do
    vid_int = String.to_integer(vid)
    qty = max(1, String.to_integer(qty_str))

    updated = Enum.map(socket.assigns.cart_items, fn item ->
      if item.variant_id == vid_int, do: %{item | qty: qty}, else: item
    end)

    {:noreply, assign(socket, cart_items: updated)}
  end

  def handle_event("set_customer", %{"customer_id" => ""}, socket) do
    {:noreply, assign(socket, customer_id: nil)}
  end

  def handle_event("set_customer", %{"customer_id" => id}, socket) do
    user = Accounts.get_user!(id)
    {:noreply, assign(socket,
      customer_id:    String.to_integer(id),
      customer_name:  "#{user.first_name} #{user.last_name}",
      customer_email: user.email
    )}
  end

  def handle_event("set_payment", %{"method" => m}, socket) do
    {:noreply, assign(socket, payment_method: m)}
  end

  def handle_event("set_notes", %{"notes" => n}, socket) do
    {:noreply, assign(socket, notes: n)}
  end

  def handle_event("confirm_sale", _params, socket) do
    if socket.assigns.cart_items == [] do
      {:noreply, put_flash(socket, :error, "Add at least one item to record a sale.")}
    else
      {:noreply, assign(socket, show_confirm: true)}
    end
  end

  def handle_event("cancel_confirm", _params, socket) do
    {:noreply, assign(socket, show_confirm: false)}
  end

  def handle_event("record_sale", _params, socket) do
    %{cart_items: items, customer_id: cid, payment_method: pm, notes: notes} = socket.assigns

    subtotal = Enum.reduce(items, Decimal.new("0"), fn i, acc ->
      Decimal.add(acc, Decimal.mult(i.price, Decimal.new(i.qty)))
    end)

    order_attrs = %{
      user_id:         cid,
      status:          "delivered",
      payment_status:  "paid",
      payment_method:  pm,
      total_amount:    subtotal,
      shipping_amount: Decimal.new("0"),
      discount_amount: Decimal.new("0"),
      notes:           notes,
      shipping_name:   socket.assigns.customer_name,
      shipping_line1:  "In-store / Admin sale",
      shipping_city:   "N/A",
      shipping_state:  "N/A",
      shipping_zip:    "N/A",
      shipping_country: "N/A"
    }

    case Orders.create_order(order_attrs) do
      {:ok, order} ->
        Enum.each(items, fn item ->
          Orders.create_order_item(%{
            order_id:     order.id,
            product_name: item.product_name,
            variant_sku:  item.sku,
            variant_size: item.size,
            quantity:     item.qty,
            unit_price:   item.price,
            subtotal:     Decimal.mult(item.price, Decimal.new(item.qty))
          })
        end)

        {:noreply,
         socket
         |> put_flash(:info, "Sale ##{order.id} recorded successfully!")
         |> assign(
           cart_items:     [],
           customer_id:    nil,
           customer_name:  "",
           customer_email: "",
           notes:          "",
           show_confirm:   false,
           recent_sales:   Orders.list_orders(status: "delivered") |> Enum.take(10)
         )}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to record sale. Please try again.")}
    end
  end

  def handle_event("clear_cart", _params, socket) do
    {:noreply, assign(socket, cart_items: [], show_confirm: false)}
  end

  @impl true
  def render(assigns) do
    filtered_variants =
      if assigns.search_product == "" do
        assigns.variants
      else
        term = String.downcase(assigns.search_product)
        Enum.filter(assigns.variants, fn v ->
          String.contains?(String.downcase(v.product.name), term) ||
          String.contains?(String.downcase(v.sku || ""), term)
        end)
      end

    subtotal = Enum.reduce(assigns.cart_items, Decimal.new("0"), fn i, acc ->
      Decimal.add(acc, Decimal.mult(i.price, Decimal.new(i.qty)))
    end)

    assigns = assign(assigns,
      filtered_variants: filtered_variants,
      subtotal: subtotal
    )

    ~H"""
    <div class="max-w-screen-xl mx-auto px-4 py-8">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-2xl font-black text-gray-900">Record Sale</h1>
          <p class="text-sm text-gray-500 mt-0.5">POS-style quick sale entry</p>
        </div>
        <a href="/admin/invoices" class="text-sm font-semibold text-amber-600 hover:underline flex items-center gap-1">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2"/></svg>
          View Invoices
        </a>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">

        <!-- Left: product selector -->
        <div class="lg:col-span-2 space-y-5">

          <!-- Customer -->
          <div class="bg-white border border-gray-200 rounded-xl p-5">
            <h2 class="font-bold text-gray-800 mb-3 flex items-center gap-2">
              <svg class="w-4 h-4 text-amber-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
              </svg>
              Customer
            </h2>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label class="block text-xs font-semibold text-gray-500 mb-1">Select Existing Customer</label>
                <select
                  phx-change="set_customer"
                  name="customer_id"
                  class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-amber-400"
                >
                  <option value="">— Guest / Walk-in —</option>
                  <%= for u <- @users do %>
                    <option value={u.id} selected={@customer_id == u.id}>
                      <%= u.first_name %> <%= u.last_name %> (<%= u.email %>)
                    </option>
                  <% end %>
                </select>
              </div>
              <div>
                <label class="block text-xs font-semibold text-gray-500 mb-1">Payment Method</label>
                <div class="flex gap-2">
                  <%= for {label, val} <- [{"Cash", "cash"}, {"Card", "card"}, {"Transfer", "transfer"}] do %>
                    <button
                      phx-click="set_payment"
                      phx-value-method={val}
                      class={[
                        "flex-1 text-sm font-semibold py-2 rounded-lg border transition",
                        if(@payment_method == val,
                          do: "bg-amber-500 text-white border-amber-500",
                          else: "border-gray-200 text-gray-600 hover:border-amber-300")
                      ]}
                    >
                      <%= label %>
                    </button>
                  <% end %>
                </div>
              </div>
            </div>
          </div>

          <!-- Product search -->
          <div class="bg-white border border-gray-200 rounded-xl p-5">
            <h2 class="font-bold text-gray-800 mb-3 flex items-center gap-2">
              <svg class="w-4 h-4 text-amber-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path d="M20 7l-8-4-8 4m16 0v10l-8 4m0-14v14m0 0l-8-4V7"/>
              </svg>
              Products
            </h2>
            <input
              type="text"
              placeholder="Search products by name or SKU…"
              value={@search_product}
              phx-keyup="search_product"
              name="q"
              class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm mb-3 focus:outline-none focus:ring-2 focus:ring-amber-400"
            />
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-2 max-h-72 overflow-y-auto pr-1">
              <%= for v <- @filtered_variants do %>
                <button
                  phx-click="add_to_cart"
                  phx-value-variant_id={v.id}
                  class="flex items-center justify-between gap-3 border border-gray-200 rounded-lg px-4 py-3 text-left hover:border-amber-400 hover:bg-amber-50 transition group"
                >
                  <div class="min-w-0">
                    <p class="text-sm font-semibold text-gray-800 truncate"><%= v.product.name %></p>
                    <p class="text-xs text-gray-400"><%= v.size %> · <%= v.sku %></p>
                  </div>
                  <div class="text-right shrink-0">
                    <p class="text-sm font-black text-amber-600">KSh <%= Decimal.round(v.price, 2) %></p>
                    <p class={["text-xs", if(v.stock_quantity > 5, do: "text-emerald-500", else: "text-red-500")]}>
                      <%= v.stock_quantity %> in stock
                    </p>
                  </div>
                </button>
              <% end %>
              <%= if @filtered_variants == [] do %>
                <div class="col-span-2 py-6 text-center text-sm text-gray-400">No products found</div>
              <% end %>
            </div>
          </div>

          <!-- Notes -->
          <div class="bg-white border border-gray-200 rounded-xl p-5">
            <label class="block text-xs font-semibold text-gray-500 mb-1">Notes (optional)</label>
            <textarea
              phx-keyup="set_notes"
              name="notes"
              rows="2"
              class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400 resize-none"
              placeholder="Any notes about this sale…"
            ><%= @notes %></textarea>
          </div>
        </div>

        <!-- Right: cart / order summary -->
        <div class="space-y-4">
          <div class="bg-white border border-gray-200 rounded-xl overflow-hidden sticky top-4">
            <div class="flex items-center justify-between px-5 py-4 border-b border-gray-100">
              <h2 class="font-bold text-gray-800">Sale Summary</h2>
              <%= if @cart_items != [] do %>
                <button phx-click="clear_cart" class="text-xs text-red-500 hover:underline">Clear</button>
              <% end %>
            </div>

            <div class="divide-y divide-gray-100 max-h-64 overflow-y-auto">
              <%= if @cart_items == [] do %>
                <div class="px-5 py-8 text-center text-sm text-gray-400">
                  No items added yet
                </div>
              <% end %>
              <%= for item <- @cart_items do %>
                <div class="px-5 py-3 flex items-start gap-3">
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-semibold text-gray-800 truncate"><%= item.product_name %></p>
                    <p class="text-xs text-gray-400"><%= item.size %></p>
                  </div>
                  <div class="flex items-center gap-1">
                    <input
                      type="number"
                      min="1"
                      value={item.qty}
                      phx-change="update_qty"
                      phx-value-variant_id={item.variant_id}
                      name="qty"
                      class="w-14 border border-gray-200 rounded px-2 py-1 text-sm text-center focus:outline-none focus:ring-1 focus:ring-amber-400"
                    />
                  </div>
                  <div class="text-right shrink-0">
                    <p class="text-sm font-bold text-gray-900">KSh <%= Decimal.round(Decimal.mult(item.price, Decimal.new(item.qty)), 2) %></p>
                    <button
                      phx-click="remove_from_cart"
                      phx-value-variant_id={item.variant_id}
                      class="text-xs text-red-400 hover:text-red-600"
                    >remove</button>
                  </div>
                </div>
              <% end %>
            </div>

            <div class="px-5 py-4 border-t border-gray-100 bg-gray-50">
              <div class="flex justify-between text-sm mb-1">
                <span class="text-gray-500">Subtotal</span>
                <span class="font-semibold text-gray-900">KSh <%= Decimal.round(@subtotal, 2) %></span>
              </div>
              <div class="flex justify-between text-sm mb-3">
                <span class="text-gray-500">Shipping</span>
                <span class="text-gray-400">$0.00</span>
              </div>
              <div class="flex justify-between font-black text-base mb-4">
                <span class="text-gray-900">Total</span>
                <span class="text-amber-600">KSh <%= Decimal.round(@subtotal, 2) %></span>
              </div>
              <button
                phx-click="confirm_sale"
                class="w-full bg-amber-500 hover:bg-amber-600 text-white font-bold text-sm py-3 rounded-lg transition uppercase tracking-widest"
              >
                Record Sale
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Recent sales -->
      <div class="mt-8">
        <h2 class="text-lg font-black text-gray-900 mb-4">Recent Sales</h2>
        <div class="bg-white border border-gray-200 rounded-xl overflow-hidden">
          <table class="w-full text-sm">
            <thead class="bg-gray-50 border-b border-gray-200">
              <tr>
                <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">#</th>
                <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Customer</th>
                <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Date</th>
                <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Payment</th>
                <th class="text-right px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Total</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <%= for sale <- @recent_sales do %>
                <tr class="hover:bg-gray-50">
                  <td class="px-5 py-3 font-mono text-xs text-gray-400">#<%= sale.id %></td>
                  <td class="px-5 py-3 text-gray-700">
                    <%= if sale.user, do: "#{sale.user.first_name} #{sale.user.last_name}", else: sale.shipping_name || "Walk-in" %>
                  </td>
                  <td class="px-5 py-3 text-gray-400 text-xs"><%= Calendar.strftime(sale.inserted_at, "%b %d, %Y %H:%M") %></td>
                  <td class="px-5 py-3">
                    <span class="text-xs bg-gray-100 text-gray-600 font-semibold px-2 py-0.5 rounded capitalize">
                      <%= sale.payment_method || "—" %>
                    </span>
                  </td>
                  <td class="px-5 py-3 text-right font-bold text-gray-900">KSh <%= Decimal.round(sale.total_amount, 2) %></td>
                </tr>
              <% end %>
              <%= if @recent_sales == [] do %>
                <tr><td colspan="5" class="px-5 py-10 text-center text-sm text-gray-400">No sales recorded yet</td></tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Confirm modal -->
    <%= if @show_confirm do %>
      <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
        <div class="bg-white rounded-xl shadow-xl w-full max-w-sm p-6">
          <h3 class="text-lg font-black text-gray-900 mb-2">Confirm Sale</h3>
          <p class="text-sm text-gray-500 mb-4">
            Record a <%= String.upcase(@payment_method) %> sale of
            <strong class="text-gray-900">KSh <%= Decimal.round(@subtotal, 2) %></strong>
            for <%= if @customer_name != "", do: @customer_name, else: "Walk-in customer" %>?
          </p>
          <div class="flex gap-3">
            <button phx-click="cancel_confirm" class="flex-1 border border-gray-200 text-gray-600 font-semibold py-2.5 rounded-lg hover:bg-gray-50 transition">Cancel</button>
            <button phx-click="record_sale" class="flex-1 bg-amber-500 hover:bg-amber-600 text-white font-bold py-2.5 rounded-lg transition">Confirm</button>
          </div>
        </div>
      </div>
    <% end %>
    """
  end
end

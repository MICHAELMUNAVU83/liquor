defmodule LiquorWeb.Admin.SalesLive do
  use LiquorWeb, :live_view

  alias Liquor.{Catalog, Accounts, Orders}

  @impl true
  def mount(_params, _session, socket) do
    products  = Catalog.list_products(active: true)
    all_sales = Orders.list_orders(status: "delivered")

    {:ok,
     socket
     |> assign(
       page_title:             "Admin – Sales",
       active_tab:             "sales",
       products:               products,
       cart_items:             [],
       customer_id:            nil,
       customer_name:          "",
       customer_email:         "",
       customer_search:        "",
       customer_results:       [],
       show_new_customer:      false,
       nc_first_name:          "",
       nc_last_name:           "",
       nc_email:               "",
       nc_phone:               "",
       nc_error:               nil,
       payment_method:         "cash",
       notes:                  "",
       search_product:         "",
       expanded_product_id:    nil,
       variant_qtys:           %{},
       show_confirm:           false,
       show_pos:               false,
       all_sales:              all_sales,
       selected_sale:          nil,
       filter_search:          "",
       filter_payment:         "",
       filter_date_from:       "",
       filter_date_to:         ""
     ),
     layout: {LiquorWeb.Layouts, :admin}}
  end

  # ── Product search & cart ──────────────────────────────────────────────────

  @impl true
  def handle_event("search_product", %{"q" => q}, socket) do
    {:noreply, assign(socket, search_product: q, expanded_product_id: nil)}
  end

  def handle_event("toggle_product", %{"id" => id}, socket) do
    id_int = String.to_integer(id)
    expanded = if socket.assigns.expanded_product_id == id_int, do: nil, else: id_int
    {:noreply, assign(socket, expanded_product_id: expanded)}
  end

  def handle_event("set_variant_qty", %{"variant_id" => vid} = params, socket) do
    qty = parse_qty(params["qty"] || params["value"])
    qtys = Map.put(socket.assigns.variant_qtys, vid, qty)
    {:noreply, assign(socket, variant_qtys: qtys)}
  end

  def handle_event("add_to_cart", %{"variant_id" => vid}, socket) do
    variant =
      socket.assigns.products
      |> Enum.flat_map(& &1.variants)
      |> Enum.find(&(to_string(&1.id) == vid))

    product =
      Enum.find(socket.assigns.products, fn p ->
        Enum.any?(p.variants, &(to_string(&1.id) == vid))
      end)

    if variant && product do
      qty  = Map.get(socket.assigns.variant_qtys, vid, 1)
      cart = socket.assigns.cart_items
      existing = Enum.find_index(cart, &(&1.variant_id == variant.id))

      updated_cart =
        if existing do
          List.update_at(cart, existing, &%{&1 | qty: &1.qty + qty})
        else
          cart ++ [%{
            variant_id:   variant.id,
            product_name: product.name,
            sku:          variant.sku,
            size:         variant.size,
            price:        variant.price,
            qty:          qty
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

  def handle_event("increment_qty", %{"variant_id" => vid}, socket) do
    vid_int = String.to_integer(vid)
    updated = Enum.map(socket.assigns.cart_items, fn item ->
      if item.variant_id == vid_int, do: %{item | qty: item.qty + 1}, else: item
    end)
    {:noreply, assign(socket, cart_items: updated)}
  end

  def handle_event("decrement_qty", %{"variant_id" => vid}, socket) do
    vid_int = String.to_integer(vid)
    updated = Enum.map(socket.assigns.cart_items, fn item ->
      if item.variant_id == vid_int, do: %{item | qty: max(1, item.qty - 1)}, else: item
    end)
    {:noreply, assign(socket, cart_items: updated)}
  end

  def handle_event("update_qty", %{"variant_id" => vid} = params, socket) do
    qty     = parse_qty(params["qty"] || params["value"])
    vid_int = String.to_integer(vid)

    updated = Enum.map(socket.assigns.cart_items, fn item ->
      if item.variant_id == vid_int, do: %{item | qty: qty}, else: item
    end)

    {:noreply, assign(socket, cart_items: updated)}
  end

  # ── Customer search & creation ─────────────────────────────────────────────

  def handle_event("search_customer", %{"q" => q}, socket) do
    results = if String.trim(q) == "", do: [], else: Accounts.list_users(search: q)
    {:noreply, assign(socket, customer_search: q, customer_results: results)}
  end

  def handle_event("pick_customer", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    {:noreply, assign(socket,
      customer_id:      user.id,
      customer_name:    "#{user.first_name} #{user.last_name}" |> String.trim(),
      customer_email:   user.email || "",
      customer_search:  "",
      customer_results: []
    )}
  end

  def handle_event("clear_customer", _params, socket) do
    {:noreply, assign(socket, customer_id: nil, customer_name: "", customer_email: "",
                               customer_search: "", customer_results: [])}
  end

  def handle_event("toggle_new_customer", _params, socket) do
    {:noreply, assign(socket,
      show_new_customer: !socket.assigns.show_new_customer,
      customer_search:   "",
      customer_results:  [],
      nc_first_name:     "",
      nc_last_name:      "",
      nc_email:          "",
      nc_phone:          "",
      nc_error:          nil
    )}
  end

  def handle_event("nc_field", %{"field" => field, "value" => value}, socket) do
    key = String.to_existing_atom("nc_#{field}")
    {:noreply, assign(socket, [{key, value}])}
  end

  def handle_event("save_new_customer", _params, socket) do
    attrs = %{
      first_name: socket.assigns.nc_first_name,
      last_name:  socket.assigns.nc_last_name,
      email:      socket.assigns.nc_email,
      phone:      socket.assigns.nc_phone
    }
    case Accounts.create_customer(attrs) do
      {:ok, user} ->
        {:noreply, assign(socket,
          customer_id:       user.id,
          customer_name:     "#{user.first_name} #{user.last_name}" |> String.trim(),
          customer_email:    user.email || "",
          show_new_customer: false,
          nc_first_name:     "",
          nc_last_name:      "",
          nc_email:          "",
          nc_phone:          "",
          nc_error:          nil
        )}
      {:error, cs} ->
        msg = cs.errors |> Enum.map(fn {f, {m, _}} -> "#{f} #{m}" end) |> Enum.join(", ")
        {:noreply, assign(socket, nc_error: msg)}
    end
  end

  def handle_event("set_payment", %{"method" => m}, socket) do
    {:noreply, assign(socket, payment_method: m)}
  end

  def handle_event("set_notes", params, socket) do
    n = params["notes"] || params["value"] || ""
    {:noreply, assign(socket, notes: n)}
  end

  # ── Sale confirmation & recording ─────────────────────────────────────────

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

    cash_register_id =
      if pm == "cash" do
        case Liquor.Cash.get_active_register() do
          nil      -> nil
          register -> register.id
        end
      end

    order_attrs = %{
      user_id:           cid,
      status:            "delivered",
      payment_status:    "paid",
      payment_method:    pm,
      cash_register_id:  cash_register_id,
      total_amount:      subtotal,
      shipping_amount:   Decimal.new("0"),
      discount_amount:   Decimal.new("0"),
      notes:             notes,
      shipping_name:     socket.assigns.customer_name,
      shipping_line1:    "In-store / Admin sale",
      shipping_city:     "N/A",
      shipping_state:    "N/A",
      shipping_zip:      "N/A",
      shipping_country:  "N/A"
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

        all_sales = Orders.list_orders(status: "delivered")

        {:noreply,
         socket
         |> put_flash(:info, "Sale ##{order.id} recorded successfully!")
         |> assign(
           show_pos:            false,
           cart_items:          [],
           customer_id:         nil,
           customer_name:       "",
           customer_email:      "",
           customer_search:     "",
           customer_results:    [],
           show_new_customer:   false,
           payment_method:      "cash",
           notes:               "",
           search_product:      "",
           expanded_product_id: nil,
           variant_qtys:        %{},
           show_confirm:        false,
           all_sales:           all_sales
         )}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to record sale. Please try again.")}
    end
  end

  def handle_event("clear_cart", _params, socket) do
    {:noreply, assign(socket, cart_items: [], show_confirm: false)}
  end

  def handle_event("open_pos", _params, socket) do
    {:noreply, assign(socket, show_pos: true)}
  end

  def handle_event("close_pos", _params, socket) do
    {:noreply, assign(socket,
      show_pos:            false,
      cart_items:          [],
      customer_id:         nil,
      customer_name:       "",
      customer_email:      "",
      customer_search:     "",
      customer_results:    [],
      show_new_customer:   false,
      payment_method:      "cash",
      notes:               "",
      search_product:      "",
      expanded_product_id: nil,
      variant_qtys:        %{},
      show_confirm:        false
    )}
  end

  # ── Sale detail modal ─────────────────────────────────────────────────────

  def handle_event("show_sale_detail", %{"id" => id}, socket) do
    sale = Enum.find(socket.assigns.all_sales, &(to_string(&1.id) == id))
    {:noreply, assign(socket, selected_sale: sale)}
  end

  def handle_event("close_sale_detail", _params, socket) do
    {:noreply, assign(socket, selected_sale: nil)}
  end

  # ── Filters ───────────────────────────────────────────────────────────────

  def handle_event("apply_filters", params, socket) do
    {:noreply, assign(socket,
      filter_search:    params["search"]    || "",
      filter_payment:   params["payment"]   || "",
      filter_date_from: params["date_from"] || "",
      filter_date_to:   params["date_to"]   || ""
    )}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply, assign(socket,
      filter_search:    "",
      filter_payment:   "",
      filter_date_from: "",
      filter_date_to:   ""
    )}
  end

  # ── Helpers ───────────────────────────────────────────────────────────────

  defp parse_qty(str) when is_binary(str) do
    case Integer.parse(str) do
      {n, _} -> max(1, n)
      :error -> 1
    end
  end
  defp parse_qty(_), do: 1

  defp filter_sales(assigns) do
    assigns.all_sales
    |> filter_by_search(assigns.filter_search)
    |> filter_by_payment(assigns.filter_payment)
    |> filter_by_date_from(assigns.filter_date_from)
    |> filter_by_date_to(assigns.filter_date_to)
  end

  defp filter_by_search(sales, ""), do: sales
  defp filter_by_search(sales, term) do
    t = String.downcase(term)
    Enum.filter(sales, fn s ->
      name = customer_name(s)
      String.contains?(String.downcase(name), t) ||
      String.contains?(to_string(s.id), t)
    end)
  end

  defp filter_by_payment(sales, ""), do: sales
  defp filter_by_payment(sales, m),  do: Enum.filter(sales, &(&1.payment_method == m))

  defp filter_by_date_from(sales, ""), do: sales
  defp filter_by_date_from(sales, d) do
    case Date.from_iso8601(d) do
      {:ok, date} -> Enum.filter(sales, &(NaiveDateTime.to_date(&1.inserted_at) >= date))
      _           -> sales
    end
  end

  defp filter_by_date_to(sales, ""), do: sales
  defp filter_by_date_to(sales, d) do
    case Date.from_iso8601(d) do
      {:ok, date} -> Enum.filter(sales, &(NaiveDateTime.to_date(&1.inserted_at) <= date))
      _           -> sales
    end
  end

  defp customer_name(sale) do
    if sale.user,
      do: "#{sale.user.first_name} #{sale.user.last_name}",
      else: sale.shipping_name || "Walk-in"
  end

  defp items_summary([]), do: "—"
  defp items_summary(items) do
    items
    |> Enum.map(&"#{&1.product_name} #{&1.variant_size} ×#{&1.quantity}")
    |> Enum.join(", ")
  end

  defp filters_active?(assigns) do
    assigns.filter_search != "" or assigns.filter_payment != "" or
    assigns.filter_date_from != "" or assigns.filter_date_to != ""
  end

  # ── Render ────────────────────────────────────────────────────────────────

  @impl true
  def render(assigns) do
    filtered_products =
      if assigns.search_product == "" do
        assigns.products
      else
        term = String.downcase(assigns.search_product)
        Enum.filter(assigns.products, fn p ->
          String.contains?(String.downcase(p.name), term) ||
          Enum.any?(p.variants, &String.contains?(String.downcase(&1.sku || ""), term))
        end)
      end

    subtotal = Enum.reduce(assigns.cart_items, Decimal.new("0"), fn i, acc ->
      Decimal.add(acc, Decimal.mult(i.price, Decimal.new(i.qty)))
    end)

    filtered_sales = filter_sales(assigns)

    assigns = assign(assigns,
      filtered_products: filtered_products,
      subtotal:          subtotal,
      filtered_sales:    filtered_sales
    )

    ~H"""
    <div class="max-w-screen-xl mx-auto px-4 py-6">

      <!-- Page header -->
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-xl font-black text-gray-900">Sales</h1>
          <p class="text-xs text-gray-500 mt-0.5">All recorded sales</p>
        </div>
        <div class="flex items-center gap-3">
          <a href="/admin/invoices" class="text-sm font-semibold text-gray-500 hover:text-gray-700 flex items-center gap-1">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2"/></svg>
            Invoices
          </a>
          <button
            phx-click="open_pos"
            class="flex items-center gap-2 bg-amber-500 hover:bg-amber-600 text-white font-bold text-sm px-4 py-2.5 rounded-lg transition shadow-sm"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>
            </svg>
            Record Sale
          </button>
        </div>
      </div>

      <!-- ── Sales history ─────────────────────────────────────────────── -->
      <div>
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-lg font-black text-gray-900">
            Sales History
            <span class="ml-2 text-sm font-normal text-gray-400">
              <%= length(@filtered_sales) %> record<%= if length(@filtered_sales) != 1, do: "s" %>
            </span>
          </h2>
          <%= if filters_active?(assigns) do %>
            <button phx-click="clear_filters" class="text-xs font-semibold text-red-500 hover:underline">
              Clear filters
            </button>
          <% end %>
        </div>

        <!-- Filter bar -->
        <form phx-change="apply_filters" class="bg-white border border-gray-200 rounded-xl p-4 mb-4">
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
            <!-- Search -->
            <div>
              <label class="block text-xs font-semibold text-gray-500 mb-1">Search customer / #</label>
              <div class="relative">
                <svg class="absolute left-2.5 top-2.5 w-3.5 h-3.5 text-gray-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                  <circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/>
                </svg>
                <input
                  type="text"
                  name="search"
                  value={@filter_search}
                  placeholder="Name or order #…"
                  phx-debounce="300"
                  class="w-full pl-8 pr-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
                />
              </div>
            </div>

            <!-- Payment method -->
            <div>
              <label class="block text-xs font-semibold text-gray-500 mb-1">Payment method</label>
              <select
                name="payment"
                class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-amber-400"
              >
                <option value="" selected={@filter_payment == ""}>All methods</option>
                <option value="cash"  selected={@filter_payment == "cash"}>Cash</option>
                <option value="mpesa" selected={@filter_payment == "mpesa"}>M-Pesa</option>
                <option value="card"  selected={@filter_payment == "card"}>Card</option>
              </select>
            </div>

            <!-- Date from -->
            <div>
              <label class="block text-xs font-semibold text-gray-500 mb-1">From date</label>
              <input
                type="date"
                name="date_from"
                value={@filter_date_from}
                class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
              />
            </div>

            <!-- Date to -->
            <div>
              <label class="block text-xs font-semibold text-gray-500 mb-1">To date</label>
              <input
                type="date"
                name="date_to"
                value={@filter_date_to}
                class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
              />
            </div>
          </div>

          <!-- Active filter chips -->
          <%= if filters_active?(assigns) do %>
            <div class="flex flex-wrap gap-2 mt-3 pt-3 border-t border-gray-100">
              <%= if @filter_search != "" do %>
                <span class="inline-flex items-center gap-1 bg-amber-50 text-amber-700 text-xs font-semibold px-2.5 py-1 rounded-full border border-amber-200">
                  Search: "<%= @filter_search %>"
                </span>
              <% end %>
              <%= if @filter_payment != "" do %>
                <span class="inline-flex items-center gap-1 bg-amber-50 text-amber-700 text-xs font-semibold px-2.5 py-1 rounded-full border border-amber-200 capitalize">
                  Payment: <%= @filter_payment %>
                </span>
              <% end %>
              <%= if @filter_date_from != "" do %>
                <span class="inline-flex items-center gap-1 bg-amber-50 text-amber-700 text-xs font-semibold px-2.5 py-1 rounded-full border border-amber-200">
                  From: <%= @filter_date_from %>
                </span>
              <% end %>
              <%= if @filter_date_to != "" do %>
                <span class="inline-flex items-center gap-1 bg-amber-50 text-amber-700 text-xs font-semibold px-2.5 py-1 rounded-full border border-amber-200">
                  To: <%= @filter_date_to %>
                </span>
              <% end %>
            </div>
          <% end %>
        </form>

        <!-- Sales table -->
        <div class="bg-white border border-gray-200 rounded-xl overflow-hidden">
          <table class="w-full text-sm">
            <thead class="bg-gray-50 border-b border-gray-200">
              <tr>
                <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">#</th>
                <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Customer</th>
                <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide hidden lg:table-cell">Items sold</th>
                <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Date</th>
                <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Payment</th>
                <th class="text-right px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Total</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <%= for sale <- @filtered_sales do %>
                <tr
                  class="hover:bg-amber-50 cursor-pointer transition"
                  phx-click="show_sale_detail"
                  phx-value-id={sale.id}
                >
                  <td class="px-5 py-3 font-mono text-xs text-gray-400">#<%= sale.id %></td>
                  <td class="px-5 py-3 text-gray-700 font-medium"><%= customer_name(sale) %></td>
                  <td class="px-5 py-3 text-gray-500 text-xs hidden lg:table-cell max-w-xs">
                    <span class="truncate block" title={items_summary(sale.items)}>
                      <%= if sale.items == [] do %>
                        <span class="text-gray-300">—</span>
                      <% else %>
                        <span class="inline-flex items-center gap-1">
                          <span class="bg-amber-100 text-amber-700 font-semibold px-1.5 py-0.5 rounded text-xs"><%= length(sale.items) %></span>
                          <%= items_summary(sale.items) |> String.slice(0, 60) %><%= if String.length(items_summary(sale.items)) > 60, do: "…" %>
                        </span>
                      <% end %>
                    </span>
                  </td>
                  <td class="px-5 py-3 text-gray-400 text-xs"><%= Calendar.strftime(sale.inserted_at, "%b %d, %Y %H:%M") %></td>
                  <td class="px-5 py-3">
                    <span class="text-xs bg-gray-100 text-gray-600 font-semibold px-2 py-0.5 rounded capitalize">
                      <%= sale.payment_method || "—" %>
                    </span>
                  </td>
                  <td class="px-5 py-3 text-right font-bold text-gray-900">KSh <%= format_money(sale.total_amount) %></td>
                </tr>
              <% end %>
              <%= if @filtered_sales == [] do %>
                <tr>
                  <td colspan="6" class="px-5 py-12 text-center text-sm text-gray-400">
                    <%= if filters_active?(assigns) do %>
                      No sales match your filters.
                      <button phx-click="clear_filters" class="ml-1 text-amber-600 hover:underline font-semibold">Clear filters</button>
                    <% else %>
                      No sales recorded yet.
                    <% end %>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- ── POS modal ─────────────────────────────────────────────────── -->
    <%= if @show_pos do %>
      <div class="fixed inset-0 z-40 flex items-center justify-center bg-black/50 px-4">
        <div class="bg-white rounded-2xl shadow-2xl w-full max-w-5xl max-h-[92vh] flex flex-col overflow-hidden">

          <!-- Modal header -->
          <div class="flex items-center justify-between px-6 py-4 border-b border-gray-100 shrink-0">
            <div>
              <h2 class="text-base font-black text-gray-900">New Sale</h2>
              <p class="text-xs text-gray-400 mt-0.5">POS quick entry</p>
            </div>
            <button phx-click="close_pos" class="text-gray-400 hover:text-gray-600 p-1">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
              </svg>
            </button>
          </div>

          <!-- Modal body -->
          <div class="flex flex-1 overflow-hidden">

            <!-- Left: customer + products + notes -->
            <div class="flex-1 overflow-y-auto p-5 space-y-4 border-r border-gray-100">

              <!-- Customer & payment -->
              <div class="grid grid-cols-2 gap-3">
                <div>
                  <label class="block text-xs font-semibold text-gray-500 mb-1">Customer</label>

                  <%= if @customer_id do %>
                    <!-- Selected customer chip -->
                    <div class="flex items-center justify-between border border-amber-300 bg-amber-50 rounded-lg px-3 py-2">
                      <div>
                        <p class="text-sm font-semibold text-gray-800"><%= @customer_name %></p>
                        <%= if @customer_email != "" do %>
                          <p class="text-xs text-gray-400"><%= @customer_email %></p>
                        <% end %>
                      </div>
                      <button phx-click="clear_customer" class="text-gray-400 hover:text-red-400 ml-2">
                        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
                        </svg>
                      </button>
                    </div>
                  <% else %>
                    <!-- Search input -->
                    <div class="relative">
                      <input
                        type="text"
                        placeholder="Search by name or email…"
                        value={@customer_search}
                        phx-keyup="search_customer"
                        name="q"
                        autocomplete="off"
                        class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
                      />
                      <%= if @customer_results != [] do %>
                        <div class="absolute z-50 top-full left-0 right-0 mt-1 bg-white border border-gray-200 rounded-lg shadow-lg max-h-40 overflow-y-auto">
                          <%= for u <- @customer_results do %>
                            <button
                              phx-click="pick_customer"
                              phx-value-id={u.id}
                              class="w-full text-left px-3 py-2 hover:bg-amber-50 transition border-b border-gray-100 last:border-0"
                            >
                              <p class="text-sm font-semibold text-gray-800"><%= u.first_name %> <%= u.last_name %></p>
                              <p class="text-xs text-gray-400"><%= u.email %></p>
                            </button>
                          <% end %>
                        </div>
                      <% end %>
                    </div>
                    <!-- Add new customer toggle -->
                    <button phx-click="toggle_new_customer" class="mt-1.5 text-xs text-amber-600 hover:underline font-semibold">
                      <%= if @show_new_customer, do: "Cancel", else: "+ Add new customer" %>
                    </button>

                    <%= if @show_new_customer do %>
                      <div class="mt-2 border border-gray-200 rounded-lg p-3 space-y-2 bg-gray-50">
                        <%= if @nc_error do %>
                          <p class="text-xs text-red-500"><%= @nc_error %></p>
                        <% end %>
                        <div class="grid grid-cols-2 gap-2">
                          <input type="text" placeholder="First name *" value={@nc_first_name}
                            phx-keyup="nc_field" phx-value-field="first_name" name="nc_first_name"
                            class="border border-gray-200 rounded px-2 py-1.5 text-sm focus:outline-none focus:ring-1 focus:ring-amber-400" />
                          <input type="text" placeholder="Last name *" value={@nc_last_name}
                            phx-keyup="nc_field" phx-value-field="last_name" name="nc_last_name"
                            class="border border-gray-200 rounded px-2 py-1.5 text-sm focus:outline-none focus:ring-1 focus:ring-amber-400" />
                        </div>
                        <input type="text" placeholder="Phone" value={@nc_phone}
                          phx-keyup="nc_field" phx-value-field="phone" name="nc_phone"
                          class="w-full border border-gray-200 rounded px-2 py-1.5 text-sm focus:outline-none focus:ring-1 focus:ring-amber-400" />
                        <input type="email" placeholder="Email (optional)" value={@nc_email}
                          phx-keyup="nc_field" phx-value-field="email" name="nc_email"
                          class="w-full border border-gray-200 rounded px-2 py-1.5 text-sm focus:outline-none focus:ring-1 focus:ring-amber-400" />
                        <button phx-click="save_new_customer"
                          class="w-full bg-amber-500 hover:bg-amber-600 text-white text-xs font-bold py-2 rounded-lg transition">
                          Save Customer
                        </button>
                      </div>
                    <% end %>
                  <% end %>
                </div>
                <div>
                  <label class="block text-xs font-semibold text-gray-500 mb-1">Payment Method</label>
                  <div class="flex gap-2">
                    <%= for {label, val} <- [{"Cash", "cash"}, {"M-Pesa", "mpesa"}, {"Card", "card"}] do %>
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

              <!-- Product search -->
              <div>
                <div class="flex items-center gap-2 mb-2">
                  <svg class="w-4 h-4 text-amber-500 shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                    <path d="M20 7l-8-4-8 4m16 0v10l-8 4m0-14v14m0 0l-8-4V7"/>
                  </svg>
                  <input
                    type="text"
                    placeholder="Search products by name or SKU…"
                    value={@search_product}
                    phx-keyup="search_product"
                    name="q"
                    class="flex-1 border border-gray-200 rounded-lg px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
                  />
                </div>
                <div class="space-y-1 max-h-64 overflow-y-auto pr-1">
                  <%= if @filtered_products == [] do %>
                    <div class="py-6 text-center text-sm text-gray-400">No products found</div>
                  <% end %>
                  <%= for product <- @filtered_products do %>
                    <% expanded = @expanded_product_id == product.id %>
                    <div class="border border-gray-200 rounded-lg overflow-hidden">
                      <button
                        phx-click="toggle_product"
                        phx-value-id={product.id}
                        class={[
                          "w-full flex items-center justify-between px-3 py-2 text-left transition",
                          if(expanded, do: "bg-amber-50 border-b border-amber-100", else: "hover:bg-gray-50")
                        ]}
                      >
                        <div class="flex items-center gap-2 min-w-0">
                          <%= if product.image_url do %>
                            <img src={product.image_url} class="w-7 h-7 rounded-md object-cover shrink-0" />
                          <% else %>
                            <div class="w-7 h-7 rounded-md bg-gray-100 flex items-center justify-center shrink-0">
                              <svg class="w-3.5 h-3.5 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01"/>
                              </svg>
                            </div>
                          <% end %>
                          <div class="min-w-0">
                            <p class="text-sm font-semibold text-gray-800 truncate"><%= product.name %></p>
                            <p class="text-xs text-gray-400"><%= length(product.variants) %> variant<%= if length(product.variants) != 1, do: "s" %></p>
                          </div>
                        </div>
                        <svg class={["w-4 h-4 text-gray-400 shrink-0 transition-transform", if(expanded, do: "rotate-180")]} fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7"/>
                        </svg>
                      </button>
                      <%= if expanded do %>
                        <div class="divide-y divide-gray-100 bg-white">
                          <%= for v <- product.variants do %>
                            <% vid_str = to_string(v.id) %>
                            <% qty = Map.get(@variant_qtys, vid_str, 1) %>
                            <div class="flex items-center gap-2 px-3 py-1.5">
                              <div class="flex-1 min-w-0">
                                <p class="text-sm font-medium text-gray-700"><%= v.size %></p>
                                <p class="text-xs text-gray-400"><%= v.sku %></p>
                              </div>
                              <p class="text-sm font-black text-amber-600 shrink-0">KSh <%= format_money(v.price) %></p>
                              <p class={["text-xs shrink-0", if(v.stock_quantity > 5, do: "text-emerald-500", else: "text-red-400")]}>
                                <%= v.stock_quantity %> in stock
                              </p>
                              <div class="flex items-center gap-1 shrink-0">
                                <input
                                  type="number"
                                  min="1"
                                  value={qty}
                                  phx-change="set_variant_qty"
                                  phx-keyup="set_variant_qty"
                                  phx-value-variant_id={vid_str}
                                  name="qty"
                                  class="w-12 border border-gray-200 rounded-lg px-2 py-1 text-sm text-center focus:outline-none focus:ring-1 focus:ring-amber-400"
                                />
                                <button
                                  phx-click="add_to_cart"
                                  phx-value-variant_id={vid_str}
                                  disabled={v.stock_quantity == 0}
                                  class={[
                                    "px-3 py-1.5 text-xs font-bold rounded-lg transition",
                                    if(v.stock_quantity > 0,
                                      do: "bg-amber-500 hover:bg-amber-600 text-white",
                                      else: "bg-gray-100 text-gray-400 cursor-not-allowed")
                                  ]}
                                >
                                  Add
                                </button>
                              </div>
                            </div>
                          <% end %>
                          <%= if product.variants == [] do %>
                            <p class="px-4 py-2 text-xs text-gray-400">No variants available</p>
                          <% end %>
                        </div>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              </div>

              <!-- Notes -->
              <div>
                <label class="block text-xs font-semibold text-gray-500 mb-1">Notes (optional)</label>
                <textarea
                  phx-change="set_notes"
                  phx-keyup="set_notes"
                  name="notes"
                  rows="2"
                  class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400 resize-none"
                  placeholder="Any notes about this sale…"
                ><%= @notes %></textarea>
              </div>
            </div>

            <!-- Right: cart summary -->
            <div class="w-72 shrink-0 flex flex-col bg-gray-50">
              <div class="flex items-center justify-between px-4 py-3 border-b border-gray-200">
                <h3 class="font-bold text-gray-800 text-sm">Cart</h3>
                <%= if @cart_items != [] do %>
                  <button phx-click="clear_cart" class="text-xs text-red-500 hover:underline">Clear</button>
                <% end %>
              </div>

              <div class="flex-1 overflow-y-auto divide-y divide-gray-200">
                <%= if @cart_items == [] do %>
                  <div class="px-4 py-10 text-center text-sm text-gray-400">No items added yet</div>
                <% end %>
                <%= for item <- @cart_items do %>
                  <div class="px-4 py-3">
                    <div class="flex items-start justify-between gap-2 mb-1">
                      <div class="min-w-0">
                        <p class="text-sm font-semibold text-gray-800 truncate"><%= item.product_name %></p>
                        <p class="text-xs text-gray-400"><%= item.size %></p>
                      </div>
                      <button
                        phx-click="remove_from_cart"
                        phx-value-variant_id={item.variant_id}
                        class="text-gray-300 hover:text-red-400 shrink-0 mt-0.5"
                      >
                        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
                        </svg>
                      </button>
                    </div>
                    <div class="flex items-center justify-between">
                      <div class="flex items-center gap-1">
                        <button
                          phx-click="decrement_qty"
                          phx-value-variant_id={item.variant_id}
                          class="w-6 h-6 rounded bg-gray-100 hover:bg-gray-200 text-gray-600 font-bold text-sm flex items-center justify-center"
                        >−</button>
                        <span class="w-8 text-center text-sm font-semibold text-gray-800"><%= item.qty %></span>
                        <button
                          phx-click="increment_qty"
                          phx-value-variant_id={item.variant_id}
                          class="w-6 h-6 rounded bg-gray-100 hover:bg-gray-200 text-gray-600 font-bold text-sm flex items-center justify-center"
                        >+</button>
                      </div>
                      <p class="text-sm font-bold text-gray-900">KSh <%= format_money(Decimal.mult(item.price, Decimal.new(item.qty))) %></p>
                    </div>
                  </div>
                <% end %>
              </div>

              <!-- Totals + action -->
              <div class="px-4 py-4 border-t border-gray-200 bg-white space-y-2">
                <div class="flex justify-between text-xs text-gray-500">
                  <span>Subtotal</span>
                  <span class="font-semibold text-gray-800">KSh <%= format_money(@subtotal) %></span>
                </div>
                <div class="flex justify-between font-black text-sm">
                  <span class="text-gray-900">Total</span>
                  <span class="text-amber-600">KSh <%= format_money(@subtotal) %></span>
                </div>
                <button
                  phx-click="confirm_sale"
                  class="w-full mt-1 bg-amber-500 hover:bg-amber-600 text-white font-bold text-sm py-3 rounded-lg transition uppercase tracking-widest"
                >
                  Record Sale
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    <% end %>

    <!-- ── Confirm sale modal ─────────────────────────────────────────── -->
    <%= if @show_confirm do %>
      <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 px-4">
        <div class="bg-white rounded-xl shadow-xl w-full max-w-sm p-6">
          <h3 class="text-lg font-black text-gray-900 mb-2">Confirm Sale</h3>
          <p class="text-sm text-gray-500 mb-4">
            Record a <%= String.upcase(@payment_method) %> sale of
            <strong class="text-gray-900">KSh <%= format_money(@subtotal) %></strong>
            for <%= if @customer_name != "", do: @customer_name, else: "Walk-in customer" %>?
          </p>
          <div class="flex gap-3">
            <button phx-click="cancel_confirm" class="flex-1 border border-gray-200 text-gray-600 font-semibold py-2.5 rounded-lg hover:bg-gray-50 transition">Cancel</button>
            <button phx-click="record_sale" class="flex-1 bg-amber-500 hover:bg-amber-600 text-white font-bold py-2.5 rounded-lg transition">Confirm</button>
          </div>
        </div>
      </div>
    <% end %>

    <!-- ── Sale detail modal ──────────────────────────────────────────── -->
    <%= if @selected_sale do %>
      <% s = @selected_sale %>
      <div
        class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4"
        phx-click="close_sale_detail"
      >
        <div class="bg-white rounded-xl shadow-xl w-full max-w-lg p-0 overflow-hidden" phx-click-away="close_sale_detail">
          <!-- Modal header -->
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

            <!-- Customer & payment -->
            <div class="grid grid-cols-2 gap-4">
              <div>
                <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-1">Customer</p>
                <p class="text-sm font-semibold text-gray-800"><%= customer_name(s) %></p>
                <%= if s.user && s.user.email do %>
                  <p class="text-xs text-gray-400"><%= s.user.email %></p>
                <% end %>
              </div>
              <div>
                <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-1">Payment</p>
                <span class="inline-block bg-emerald-100 text-emerald-700 text-xs font-bold px-2.5 py-1 rounded-full capitalize">
                  <%= s.payment_method || "—" %>
                </span>
                <p class="text-xs text-gray-400 mt-1 capitalize"><%= s.payment_status %></p>
              </div>
            </div>

            <!-- Items table -->
            <div>
              <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-2">Items Sold</p>
              <%= if s.items == [] do %>
                <p class="text-sm text-gray-400 italic">No item details recorded.</p>
              <% else %>
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
                            <p class="text-xs text-gray-400"><%= item.variant_size %> · <%= item.variant_sku %></p>
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
            </div>

            <!-- Totals -->
            <div class="bg-gray-50 rounded-lg px-4 py-3 space-y-1.5">
              <div class="flex justify-between text-sm">
                <span class="text-gray-500">Subtotal</span>
                <span class="font-semibold text-gray-800">KSh <%= format_money(s.total_amount) %></span>
              </div>
              <%= if Decimal.compare(s.shipping_amount, Decimal.new("0")) != :eq do %>
                <div class="flex justify-between text-sm">
                  <span class="text-gray-500">Shipping</span>
                  <span class="text-gray-700">KSh <%= format_money(s.shipping_amount) %></span>
                </div>
              <% end %>
              <%= if Decimal.compare(s.discount_amount, Decimal.new("0")) != :eq do %>
                <div class="flex justify-between text-sm">
                  <span class="text-gray-500">Discount</span>
                  <span class="text-emerald-600">-KSh <%= format_money(s.discount_amount) %></span>
                </div>
              <% end %>
              <div class="flex justify-between text-base font-black pt-1.5 border-t border-gray-200">
                <span class="text-gray-900">Total</span>
                <span class="text-amber-600">KSh <%= format_money(s.total_amount) %></span>
              </div>
            </div>

            <!-- Notes -->
            <%= if s.notes && s.notes != "" do %>
              <div>
                <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-1">Notes</p>
                <p class="text-sm text-gray-700 bg-amber-50 border border-amber-100 rounded-lg px-3 py-2"><%= s.notes %></p>
              </div>
            <% end %>
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
    """
  end
end

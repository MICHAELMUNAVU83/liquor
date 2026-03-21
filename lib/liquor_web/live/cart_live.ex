defmodule LiquorWeb.CartLive do
  use LiquorWeb, :live_view

  alias Liquor.Cart

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title:   "Shopping Cart · The Mint",
       current_page: "",
       loading:      true,
       items:        [],
       promo_input:  "",
       discount:     nil
     )}
  end

  # ── Restore cart from localStorage ─────────────────────────────────────────

  @impl true
  def handle_event("cart:restore", %{"items" => raw}, socket) do
    items = Cart.resolve_items(raw)
    # Do NOT push_cart_sync here — that would overwrite localStorage with only
    # the DB-resolvable subset, silently deleting items added from other pages.
    # localStorage stays as-is; only explicit user actions (inc/dec/remove) sync back.
    {:noreply, assign(socket, loading: false, items: items)}
  end

  def handle_event("cart:restore", _params, socket) do
    {:noreply, assign(socket, loading: false)}
  end

  # ── Quantity controls ───────────────────────────────────────────────────────

  def handle_event("inc_qty", %{"id" => id}, socket) do
    vid = String.to_integer(id)
    items = update_item_qty(socket.assigns.items, vid, &(&1 + 1))
    {:noreply, socket |> assign(items: items) |> push_cart_sync(items)}
  end

  def handle_event("dec_qty", %{"id" => id}, socket) do
    vid = String.to_integer(id)

    items =
      socket.assigns.items
      |> Enum.flat_map(fn item ->
        if item.variant_id == vid do
          new_qty = item.quantity - 1
          if new_qty <= 0, do: [], else: [%{item | quantity: new_qty}]
        else
          [item]
        end
      end)

    {:noreply, socket |> assign(items: items) |> push_cart_sync(items)}
  end

  def handle_event("set_qty", %{"id" => id, "qty" => qty_str}, socket) do
    vid = String.to_integer(id)

    items =
      case Integer.parse(qty_str) do
        {n, _} when n > 0 ->
          update_item_qty(socket.assigns.items, vid, fn _ -> n end)
        _ ->
          Enum.reject(socket.assigns.items, &(&1.variant_id == vid))
      end

    {:noreply, socket |> assign(items: items) |> push_cart_sync(items)}
  end

  def handle_event("remove_item", %{"id" => id}, socket) do
    vid   = String.to_integer(id)
    items = Enum.reject(socket.assigns.items, &(&1.variant_id == vid))
    {:noreply, socket |> assign(items: items) |> push_cart_sync(items)}
  end

  # ── Variant switching ────────────────────────────────────────────────────────

  def handle_event("change_variant", %{"old_id" => old_id_str, "new_id" => new_id_str}, socket)
      when old_id_str != new_id_str do
    old_vid = String.to_integer(old_id_str)
    new_vid = String.to_integer(new_id_str)
    old_qty = Enum.find_value(socket.assigns.items, 1, fn item ->
      if item.variant_id == old_vid, do: item.quantity
    end)

    items =
      case Cart.resolve_items([%{"variant_id" => new_vid, "quantity" => old_qty}]) do
        [new_item] ->
          Enum.map(socket.assigns.items, fn item ->
            if item.variant_id == old_vid, do: %{new_item | quantity: old_qty}, else: item
          end)
        _ ->
          socket.assigns.items
      end

    {:noreply, socket |> assign(items: items) |> push_cart_sync(items)}
  end

  def handle_event("change_variant", _params, socket), do: {:noreply, socket}

  def handle_event("clear_cart", _params, socket) do
    {:noreply, socket |> assign(items: []) |> push_cart_sync([])}
  end

  # ── Promo code ──────────────────────────────────────────────────────────────

  def handle_event("update_promo", %{"promo" => code}, socket) do
    {:noreply, assign(socket, promo_input: code)}
  end

  def handle_event("apply_promo", _params, socket) do
    case String.upcase(String.trim(socket.assigns.promo_input)) do
      "MINT10" ->
        {:noreply,
         socket
         |> assign(discount: %{code: "MINT10", pct: 10})
         |> put_flash(:info, "10% discount applied!")}
      "WELCOME" ->
        {:noreply,
         socket
         |> assign(discount: %{code: "WELCOME", pct: 15})
         |> put_flash(:info, "15% welcome discount applied!")}
      _ ->
        {:noreply, put_flash(socket, :error, "Invalid promo code.")}
    end
  end

  def handle_event("remove_promo", _params, socket) do
    {:noreply, assign(socket, discount: nil, promo_input: "")}
  end

  # ── Helpers ─────────────────────────────────────────────────────────────────

  defp update_item_qty(items, vid, fun) do
    Enum.map(items, fn item ->
      if item.variant_id == vid, do: %{item | quantity: fun.(item.quantity)}, else: item
    end)
  end

  defp push_cart_sync(socket, items) do
    raw = Enum.map(items, &%{"variant_id" => &1.variant_id, "quantity" => &1.quantity})
    push_event(socket, "cart:sync", %{items: raw})
  end

  defp fmt(decimal), do: format_money(decimal || Decimal.new("0"))

  # ── Render ──────────────────────────────────────────────────────────────────

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign_new(:subtotal,  fn -> Cart.subtotal(assigns.items) end)
      |> assign_new(:shipping,  fn -> Cart.shipping_cost(Cart.subtotal(assigns.items)) end)
      |> assign_new(:discount_amount, fn ->
        sub = Cart.subtotal(assigns.items)
        if assigns.discount do
          Decimal.mult(sub, Decimal.div(Decimal.new(assigns.discount.pct), Decimal.new(100)))
        else
          Decimal.new("0")
        end
      end)

    ~H"""
    <div
      id="cart-sync"
      phx-hook="CartSync"
      class="min-h-screen bg-zinc-50"
    >
      <div class="max-w-screen-xl mx-auto px-4 sm:px-6 py-8">

        <!-- Header -->
        <div class="flex items-center gap-3 mb-8">
          <a href="/shop" class="text-zinc-400 hover:text-zinc-700 transition">
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M10 19l-7-7m0 0l7-7m-7 7h18"/>
            </svg>
          </a>
          <div>
            <h1 class="text-2xl font-black text-zinc-900 font-display">Shopping Cart</h1>
            <p class="text-sm text-zinc-500 font-sans">
              <%= if @loading, do: "Loading…", else: "#{length(@items)} #{if length(@items) == 1, do: "item", else: "items"}" %>
            </p>
          </div>
        </div>

        <!-- Loading skeleton -->
        <%= if @loading do %>
          <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div class="lg:col-span-2 space-y-4">
              <%= for _ <- 1..3 do %>
                <div class="bg-white rounded-xl p-5 flex gap-4 animate-pulse">
                  <div class="w-20 h-24 bg-zinc-200 rounded-lg shrink-0"></div>
                  <div class="flex-1 space-y-2 py-1">
                    <div class="h-4 bg-zinc-200 rounded w-3/4"></div>
                    <div class="h-3 bg-zinc-200 rounded w-1/3"></div>
                    <div class="h-3 bg-zinc-200 rounded w-1/4"></div>
                  </div>
                </div>
              <% end %>
            </div>
            <div class="bg-white rounded-xl p-6 h-64 animate-pulse">
              <div class="h-4 bg-zinc-200 rounded w-1/2 mb-4"></div>
              <div class="space-y-2">
                <div class="h-3 bg-zinc-200 rounded"></div>
                <div class="h-3 bg-zinc-200 rounded"></div>
                <div class="h-3 bg-zinc-200 rounded w-3/4"></div>
              </div>
            </div>
          </div>
        <% else %>
          <%= if @items == [] do %>
          <!-- Empty cart -->
          <div class="flex flex-col items-center justify-center py-24 text-center">
            <div class="w-24 h-24 rounded-full bg-zinc-100 flex items-center justify-center mb-6">
              <svg class="w-10 h-10 text-zinc-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 3h1.386c.51 0 .955.343 1.087.835l.383 1.437M7.5 14.25a3 3 0 00-3 3h15.75m-12.75-3h11.218c1.121-2.3 2.1-4.684 2.924-7.138a60.114 60.114 0 00-16.536-1.84M7.5 14.25L5.106 5.272M6 20.25a.75.75 0 11-1.5 0 .75.75 0 011.5 0zm12.75 0a.75.75 0 11-1.5 0 .75.75 0 011.5 0z"/>
              </svg>
            </div>
            <h2 class="text-xl font-bold text-zinc-800 mb-2 font-display">Your cart is empty</h2>
            <p class="text-zinc-500 text-sm mb-8">Looks like you haven't added anything yet.</p>
            <a
              href="/shop"
              class="bg-orange-500 hover:bg-orange-600 text-white font-bold text-sm px-8 py-3 transition uppercase tracking-widest"
            >
              Start Shopping
            </a>
          </div>

        <!-- Cart with items -->
        <% else %>
          <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">

            <!-- ── Items column ─────────────────────────────── -->
            <div class="lg:col-span-2">

              <!-- Clear all -->
              <div class="flex justify-end mb-3">
                <button
                  phx-click="clear_cart"
                  data-confirm="Remove all items from cart?"
                  class="text-xs text-zinc-400 hover:text-red-500 transition underline"
                >
                  Clear cart
                </button>
              </div>

              <!-- Item list -->
              <div class="space-y-3">
                <%= for item <- @items do %>
                  <div class="bg-white rounded-xl border border-zinc-100 p-4 sm:p-5 flex gap-4 group">
                    <!-- Image -->
                    <a href={"/shop"} class="shrink-0">
                      <div class="w-20 h-24 sm:w-24 sm:h-28 rounded-lg overflow-hidden bg-zinc-50 border border-zinc-100">
                        <%= if item.image_url do %>
                          <img
                            src={item.image_url <> "?w=200&auto=format&fit=crop"}
                            alt={item.product_name}
                            class="w-full h-full object-cover"
                          />
                        <% else %>
                          <div class="w-full h-full flex items-center justify-center">
                            <svg class="w-8 h-8 text-zinc-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1">
                              <path stroke-linecap="round" stroke-linejoin="round" d="M9 3v1m6-1v1M9 19v1m6-1v1M5 9H4m1 6H4m16-6h-1m1 6h-1M7 4h10l1 4v8a2 2 0 01-2 2H8a2 2 0 01-2-2V8l1-4z" />
                            </svg>
                          </div>
                        <% end %>
                      </div>
                    </a>

                    <!-- Details -->
                    <div class="flex-1 min-w-0">
                      <div class="flex items-start justify-between gap-2">
                        <div class="min-w-0 flex-1">
                          <p class="font-semibold text-zinc-900 text-sm leading-snug font-sans">
                            <%= item.product_name %>
                          </p>
                          <p class="text-xs text-zinc-400 mt-0.5 font-sans">SKU: <%= item.sku %></p>

                          <!-- Variant / size selector -->
                          <%= if length(item.all_variants) > 1 do %>
                            <form phx-change="change_variant" class="mt-2">
                              <input type="hidden" name="old_id" value={item.variant_id} />
                              <select
                                name="new_id"
                                class="text-xs border border-zinc-200 rounded-lg px-2 py-1.5 text-zinc-700 bg-white focus:outline-none focus:ring-1 focus:ring-amber-400 cursor-pointer"
                              >
                                <%= for v <- item.all_variants do %>
                                  <option
                                    value={v.id}
                                    selected={v.id == item.variant_id}
                                    disabled={!v.in_stock && v.id != item.variant_id}
                                  >
                                    <%= v.size %> — KSh <%= format_money(v.price) %><%= if !v.in_stock, do: " (out of stock)" %>
                                  </option>
                                <% end %>
                              </select>
                            </form>
                          <% else %>
                            <p class="text-xs text-zinc-500 mt-1"><%= item.size %></p>
                          <% end %>

                          <!-- Stock badge -->
                          <%= if item.in_stock do %>
                            <span class="inline-block mt-1.5 text-[10px] font-bold bg-emerald-50 text-emerald-700 px-2 py-0.5 rounded-full">
                              In Stock
                            </span>
                          <% else %>
                            <span class="inline-block mt-1.5 text-[10px] font-bold bg-red-50 text-red-600 px-2 py-0.5 rounded-full">
                              Out of Stock
                            </span>
                          <% end %>
                        </div>
                        <!-- Price (desktop) -->
                        <div class="text-right shrink-0 hidden sm:block">
                          <p class="font-bold text-zinc-900 text-base">
                            KSh <%= fmt(Decimal.mult(item.price, Decimal.new(item.quantity))) %>
                          </p>
                          <p class="text-xs text-zinc-400">
                            KSh <%= fmt(item.price) %> each
                          </p>
                        </div>
                      </div>

                      <!-- Controls row -->
                      <div class="flex items-center justify-between mt-3 gap-3">
                        <!-- Quantity stepper -->
                        <div class="flex items-center border border-zinc-200 rounded-lg overflow-hidden">
                          <button
                            phx-click="dec_qty"
                            phx-value-id={item.variant_id}
                            class="w-8 h-8 flex items-center justify-center text-zinc-500 hover:bg-zinc-50 hover:text-zinc-900 transition text-lg font-light"
                          >
                            −
                          </button>
                          <input
                            type="number"
                            min="1"
                            max={item.stock_qty}
                            value={item.quantity}
                            phx-blur="set_qty"
                            phx-value-id={item.variant_id}
                            name="qty"
                            class="w-10 h-8 text-center text-sm font-semibold text-zinc-900 border-x border-zinc-200 focus:outline-none focus:ring-1 focus:ring-amber-400 font-sans [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
                          />
                          <button
                            phx-click="inc_qty"
                            phx-value-id={item.variant_id}
                            class="w-8 h-8 flex items-center justify-center text-zinc-500 hover:bg-zinc-50 hover:text-zinc-900 transition text-lg font-light"
                          >
                            +
                          </button>
                        </div>

                        <!-- Price (mobile) + Remove -->
                        <div class="flex items-center gap-3">
                          <span class="font-bold text-zinc-900 text-sm sm:hidden">
                            KSh <%= fmt(Decimal.mult(item.price, Decimal.new(item.quantity))) %>
                          </span>
                          <button
                            phx-click="remove_item"
                            phx-value-id={item.variant_id}
                            class="text-xs text-zinc-400 hover:text-red-500 transition flex items-center gap-1"
                          >
                            <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                              <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                            </svg>
                            Remove
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>

              <!-- Continue shopping -->
              <a
                href="/shop"
                class="mt-6 inline-flex items-center gap-2 text-sm text-zinc-500 hover:text-amber-600 transition font-sans"
              >
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M10 19l-7-7m0 0l7-7m-7 7h18"/>
                </svg>
                Continue Shopping
              </a>
            </div>

            <!-- ── Order Summary ─────────────────────────────── -->
            <div class="lg:col-span-1">
              <div class="bg-white rounded-xl border border-zinc-100 p-6 sticky top-20">
                <h2 class="font-black text-zinc-900 text-lg mb-5 font-display">Order Summary</h2>

                <!-- Line items -->
                <div class="space-y-2.5 text-sm text-zinc-600 mb-5 font-sans">
                  <div class="flex justify-between">
                    <span>Subtotal (<%= length(@items) %> items)</span>
                    <span class="font-semibold text-zinc-900">KSh <%= fmt(@subtotal) %></span>
                  </div>

                  <%= if @discount do %>
                    <div class="flex justify-between text-emerald-600">
                      <span>Discount (<%= @discount.code %> <%= @discount.pct %>% off)</span>
                      <span class="font-semibold">−KSh <%= fmt(@discount_amount) %></span>
                    </div>
                  <% end %>

                  <div class="flex justify-between">
                    <span>Shipping</span>
                    <%= if Decimal.equal?(@shipping, Decimal.new("0")) do %>
                      <span class="font-semibold text-emerald-600">Free</span>
                    <% else %>
                      <span class="font-semibold text-zinc-900">KSh <%= fmt(@shipping) %></span>
                    <% end %>
                  </div>

                  <%= if Decimal.equal?(@shipping, Decimal.new("0")) == false do %>
                    <p class="text-xs text-zinc-400">
                      Add KSh <%= fmt(Decimal.sub(Decimal.new(Liquor.StoreConfig.free_ship_threshold()), @subtotal)) %> more for free delivery
                    </p>
                  <% end %>
                </div>

                <!-- Divider -->
                <div class="border-t border-zinc-100 my-4"></div>

                <!-- Total -->
                <div class="flex justify-between items-center mb-6 font-sans">
                  <span class="font-bold text-zinc-900">Total</span>
                  <span class="text-xl font-black text-zinc-900">
                    KSh <%= fmt(Decimal.sub(Decimal.add(Cart.subtotal(@items), @shipping), @discount_amount)) %>
                  </span>
                </div>

                <!-- Promo code -->
                <div class="mb-5 font-sans">
                  <%= if @discount do %>
                    <div class="flex items-center justify-between bg-emerald-50 border border-emerald-200 rounded-lg px-3 py-2">
                      <div class="flex items-center gap-2 text-xs text-emerald-700">
                        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                        </svg>
                        <span class="font-semibold"><%= @discount.code %></span> applied
                      </div>
                      <button phx-click="remove_promo" class="text-xs text-emerald-600 hover:text-red-500 transition">Remove</button>
                    </div>
                  <% else %>
                    <form phx-submit="apply_promo" class="flex gap-2">
                      <input
                        type="text"
                        name="promo"
                        value={@promo_input}
                        phx-change="update_promo"
                        placeholder="Promo code"
                        class="flex-1 text-sm border border-zinc-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-amber-400 placeholder-zinc-400"
                      />
                      <button
                        type="submit"
                        class="text-xs font-bold border border-zinc-300 text-zinc-700 hover:border-amber-500 hover:text-amber-600 px-3 py-2 rounded-lg transition"
                      >
                        Apply
                      </button>
                    </form>
                    <p class="text-xs text-zinc-400 mt-1">Try: MINT10 or WELCOME</p>
                  <% end %>
                </div>

                <!-- Checkout button -->
                <a
                  href="/checkout"
                  class="block w-full bg-orange-500 hover:bg-orange-600 text-white text-center font-bold text-sm py-4 transition uppercase tracking-widest"
                >
                  Proceed to Checkout
                </a>

                <!-- Trust badges -->
                <div class="mt-4 flex items-center justify-center gap-3 text-zinc-400">
                  <div class="flex items-center gap-1 text-xs font-sans">
                    <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/>
                    </svg>
                    Secure checkout
                  </div>
                  <span class="text-zinc-200">|</span>
                  <div class="flex items-center gap-1 text-xs font-sans">
                    <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
                    </svg>
                    Free returns
                  </div>
                </div>

              </div>
            </div>
          </div>
        <% end %>
        <% end %>

      </div>
    </div>
    """
  end
end

defmodule LiquorWeb.CheckoutLive do
  use LiquorWeb, :live_view

  alias Liquor.{Cart, Orders, Settings, Paystack}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title:   "Checkout · The Mint",
       current_page: "",
       loading:      true,
       items:        [],
       discount:     nil,
       form_errors:  %{},
       submitting:   false,
       form:         %{"name" => "", "email" => "", "phone" => "", "address" => "", "city" => "", "notes" => ""}
     )}
  end

  # ── Restore cart from localStorage (same pattern as CartLive) ────────────────

  @impl true
  def handle_event("cart:restore", %{"items" => raw}, socket) do
    items = Cart.resolve_items(raw)
    discount = socket.assigns.discount
    {:noreply, assign(socket, loading: false, items: items, discount: discount)}
  end

  def handle_event("cart:restore", _params, socket) do
    {:noreply, assign(socket, loading: false)}
  end

  # ── Form field updates ────────────────────────────────────────────────────────

  def handle_event("update_field", %{"field" => field, "value" => value}, socket) do
    form = Map.put(socket.assigns.form, field, value)
    errors = Map.delete(socket.assigns.form_errors, field)
    {:noreply, assign(socket, form: form, form_errors: errors)}
  end

  # ── Checkout submit ───────────────────────────────────────────────────────────

  def handle_event("checkout", %{"checkout" => params}, socket) do
    items = socket.assigns.items

    if items == [] do
      {:noreply, put_flash(socket, :error, "Your cart is empty.")}
    else
      errors = validate_params(params)

      if errors != %{} do
        {:noreply, assign(socket, form_errors: errors, form: params)}
      else
        socket = assign(socket, submitting: true, form: params)
        subtotal        = Cart.subtotal(items)
        shipping        = Cart.shipping_cost(subtotal)
        discount_amount = calc_discount(subtotal, socket.assigns.discount)
        total           = Decimal.sub(Decimal.add(subtotal, shipping), discount_amount)
        reference       = "MINT-#{:os.system_time(:millisecond)}"

        paystack_enabled = Settings.get("paystack_enabled") == "true"

        order_attrs = %{
          status:            "pending",
          payment_status:    "unpaid",
          payment_method:    if(paystack_enabled, do: "paystack", else: "whatsapp"),
          payment_reference: reference,
          total_amount:      total,
          shipping_amount:   shipping,
          discount_amount:   discount_amount,
          shipping_name:     params["name"],
          shipping_line1:    params["address"],
          shipping_city:     params["city"],
          customer_email:    params["email"],
          customer_phone:    params["phone"],
          notes:             params["notes"]
        }

        case Orders.create_order_with_items(order_attrs, items) do
          {:ok, order} ->
            if paystack_enabled do
              do_paystack_redirect(socket, order, params["email"], total, reference)
            else
              do_whatsapp_redirect(socket, order, items, params)
            end

          {:error, _} ->
            {:noreply,
             socket
             |> assign(submitting: false)
             |> put_flash(:error, "Something went wrong. Please try again.")}
        end
      end
    end
  end

  # ── Success mount ─────────────────────────────────────────────────────────────

  @impl true
  def handle_params(%{"ref" => ref}, _uri, socket) when socket.assigns.live_action == :success do
    {:noreply, assign(socket, order_ref: ref)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, order_ref: nil)}
  end

  # ── Private helpers ───────────────────────────────────────────────────────────

  defp do_paystack_redirect(socket, _order, email, total, reference) do
    case Paystack.initialize(email, Decimal.to_float(total), reference) do
      {:ok, %{authorization_url: url}} ->
        {:noreply, socket |> push_event("cart:clear", %{}) |> redirect(external: url)}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(submitting: false)
         |> put_flash(:error, "Payment init failed: #{reason}")}
    end
  end

  defp do_whatsapp_redirect(socket, order, items, params) do
    phone = Settings.get("whatsapp_order_phone") || Settings.get("social_whatsapp") || ""
    phone = String.replace(phone, ~r/[^\d+]/, "")
    text  = build_whatsapp_message(order, items, params)
    url   = "https://wa.me/#{phone}?text=#{URI.encode_www_form(text)}"
    {:noreply, socket |> push_event("cart:clear", %{}) |> redirect(external: url)}
  end

  defp build_whatsapp_message(order, items, params) do
    items_text =
      items
      |> Enum.map(fn item ->
        line_total = Decimal.round(Decimal.mult(item.price, Decimal.new(item.quantity)), 2)
        "• #{item.product_name} #{item.size} × #{item.quantity} = KSh #{line_total}"
      end)
      |> Enum.join("\n")

    notes_line =
      if (params["notes"] || "") != "",
        do: "\n📝 *Notes:* #{params["notes"]}",
        else: ""

    """
    🛒 *New Order – #{order.payment_reference}*

    👤 *Name:* #{params["name"]}
    📞 *Phone:* #{params["phone"]}
    📧 *Email:* #{params["email"]}
    📍 *Delivery:* #{params["address"]}, #{params["city"]}#{notes_line}

    *Items:*
    #{items_text}

    💰 *Subtotal:* KSh #{Decimal.round(Cart.subtotal(items), 2)}
    🚚 *Shipping:* KSh #{Decimal.round(order.shipping_amount, 2)}
    ✅ *Total:* KSh #{Decimal.round(order.total_amount, 2)}
    """
    |> String.trim()
  end

  defp validate_params(params) do
    %{}
    |> maybe_error(params["name"] == "", "name", "Full name is required")
    |> maybe_error(params["phone"] == "", "phone", "Phone number is required")
    |> maybe_error(params["email"] == "", "email", "Email address is required")
    |> maybe_error(params["address"] == "", "address", "Delivery address is required")
    |> maybe_error(params["city"] == "", "city", "City / area is required")
  end

  defp maybe_error(errs, true, key, msg), do: Map.put(errs, key, msg)
  defp maybe_error(errs, false, _key, _msg), do: errs

  defp calc_discount(_sub, nil), do: Decimal.new("0")
  defp calc_discount(sub, %{pct: pct}) do
    Decimal.mult(sub, Decimal.div(Decimal.new(pct), Decimal.new(100)))
  end

  defp fmt(d), do: Decimal.round(d || Decimal.new("0"), 2)

  # ── Render ────────────────────────────────────────────────────────────────────

  @impl true
  def render(%{live_action: :success} = assigns) do
    ~H"""
    <div
      id="cart-sync"
      phx-hook="CartSync"
      class="min-h-screen bg-zinc-50 flex items-center justify-center px-4"
    >
      <div class="max-w-md w-full text-center py-16">
        <div class="w-20 h-20 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-6">
          <svg class="w-10 h-10 text-emerald-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/>
          </svg>
        </div>
        <h1 class="text-2xl font-black text-zinc-900 mb-2 font-display">Order Confirmed!</h1>
        <p class="text-zinc-500 text-sm mb-2">
          Thank you for your order. We're processing your payment now.
        </p>
        <%= if @order_ref do %>
          <p class="text-xs text-zinc-400 mb-8">Reference: <span class="font-mono font-semibold text-zinc-600"><%= @order_ref %></span></p>
        <% end %>
        <a
          href="/shop"
          class="inline-block bg-orange-500 hover:bg-orange-600 text-white font-bold text-sm px-8 py-3 transition uppercase tracking-widest"
        >
          Continue Shopping
        </a>
      </div>
    </div>
    """
  end

  def render(assigns) do
    paystack_enabled = Settings.get("paystack_enabled") == "true"
    assigns = assign(assigns, :paystack_enabled, paystack_enabled)

    assigns =
      assigns
      |> assign_new(:subtotal, fn -> Cart.subtotal(assigns.items) end)
      |> assign_new(:shipping, fn -> Cart.shipping_cost(Cart.subtotal(assigns.items)) end)
      |> assign_new(:discount_amount, fn ->
        calc_discount(Cart.subtotal(assigns.items), assigns.discount)
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
          <a href="/cart" class="text-zinc-400 hover:text-zinc-700 transition">
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M10 19l-7-7m0 0l7-7m-7 7h18"/>
            </svg>
          </a>
          <div>
            <h1 class="text-2xl font-black text-zinc-900 font-display">Checkout</h1>
            <p class="text-sm text-zinc-500 font-sans">Complete your order details below</p>
          </div>
        </div>

        <%= if @loading do %>
          <div class="flex items-center justify-center py-24">
            <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-orange-500"></div>
          </div>
        <% else %>
          <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">

            <!-- ── Checkout form ─────────────────────────────── -->
            <div class="lg:col-span-2">
              <form phx-submit="checkout" id="checkout-form">

                <!-- Contact details -->
                <div class="bg-white rounded-xl border border-zinc-100 p-6 mb-5">
                  <h2 class="font-black text-zinc-900 text-base mb-5 font-display">Contact Details</h2>
                  <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">

                    <!-- Name -->
                    <div class="sm:col-span-2">
                      <label class="block text-xs font-semibold text-zinc-600 mb-1">Full Name *</label>
                      <input
                        type="text"
                        name="checkout[name]"
                        value={@form["name"]}
                        placeholder="John Doe"
                        class={["w-full border rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-orange-400",
                          if(Map.has_key?(@form_errors, "name"), do: "border-red-400 bg-red-50", else: "border-zinc-200")]}
                      />
                      <%= if err = @form_errors["name"] do %>
                        <p class="text-xs text-red-500 mt-1"><%= err %></p>
                      <% end %>
                    </div>

                    <!-- Phone -->
                    <div>
                      <label class="block text-xs font-semibold text-zinc-600 mb-1">Phone Number *</label>
                      <input
                        type="tel"
                        name="checkout[phone]"
                        value={@form["phone"]}
                        placeholder="+254 700 123 456"
                        class={["w-full border rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-orange-400",
                          if(Map.has_key?(@form_errors, "phone"), do: "border-red-400 bg-red-50", else: "border-zinc-200")]}
                      />
                      <%= if err = @form_errors["phone"] do %>
                        <p class="text-xs text-red-500 mt-1"><%= err %></p>
                      <% end %>
                    </div>

                    <!-- Email -->
                    <div>
                      <label class="block text-xs font-semibold text-zinc-600 mb-1">Email Address *</label>
                      <input
                        type="email"
                        name="checkout[email]"
                        value={@form["email"]}
                        placeholder="john@email.com"
                        class={["w-full border rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-orange-400",
                          if(Map.has_key?(@form_errors, "email"), do: "border-red-400 bg-red-50", else: "border-zinc-200")]}
                      />
                      <%= if err = @form_errors["email"] do %>
                        <p class="text-xs text-red-500 mt-1"><%= err %></p>
                      <% end %>
                    </div>

                  </div>
                </div>

                <!-- Delivery address -->
                <div class="bg-white rounded-xl border border-zinc-100 p-6 mb-5">
                  <h2 class="font-black text-zinc-900 text-base mb-5 font-display">Delivery Address</h2>
                  <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">

                    <!-- Street address -->
                    <div class="sm:col-span-2">
                      <label class="block text-xs font-semibold text-zinc-600 mb-1">Street / Estate *</label>
                      <input
                        type="text"
                        name="checkout[address]"
                        value={@form["address"]}
                        placeholder="123 Thika Road, Roysambu"
                        class={["w-full border rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-orange-400",
                          if(Map.has_key?(@form_errors, "address"), do: "border-red-400 bg-red-50", else: "border-zinc-200")]}
                      />
                      <%= if err = @form_errors["address"] do %>
                        <p class="text-xs text-red-500 mt-1"><%= err %></p>
                      <% end %>
                    </div>

                    <!-- City / area -->
                    <div>
                      <label class="block text-xs font-semibold text-zinc-600 mb-1">City / Area *</label>
                      <input
                        type="text"
                        name="checkout[city]"
                        value={@form["city"]}
                        placeholder="Nairobi"
                        class={["w-full border rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-orange-400",
                          if(Map.has_key?(@form_errors, "city"), do: "border-red-400 bg-red-50", else: "border-zinc-200")]}
                      />
                      <%= if err = @form_errors["city"] do %>
                        <p class="text-xs text-red-500 mt-1"><%= err %></p>
                      <% end %>
                    </div>

                    <!-- Notes -->
                    <div class="sm:col-span-2">
                      <label class="block text-xs font-semibold text-zinc-600 mb-1">Order Notes <span class="font-normal text-zinc-400">(optional)</span></label>
                      <textarea
                        name="checkout[notes]"
                        rows="2"
                        placeholder="Delivery instructions, gate code, etc."
                        class="w-full border border-zinc-200 rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-orange-400 resize-none"
                      ><%= @form["notes"] %></textarea>
                    </div>

                  </div>
                </div>

                <!-- Payment method notice -->
                <div class={["rounded-xl border p-4 mb-6 flex items-start gap-3",
                  if(@paystack_enabled, do: "bg-blue-50 border-blue-200", else: "bg-green-50 border-green-200")]}>
                  <%= if @paystack_enabled do %>
                    <svg class="w-5 h-5 text-blue-500 shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"/>
                    </svg>
                    <div>
                      <p class="text-sm font-semibold text-blue-800">Pay securely via Paystack</p>
                      <p class="text-xs text-blue-600 mt-0.5">You'll be redirected to Paystack to complete payment. Card, M-Pesa & more accepted.</p>
                    </div>
                  <% else %>
                    <svg class="w-5 h-5 text-green-600 shrink-0 mt-0.5" viewBox="0 0 24 24" fill="currentColor">
                      <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z"/>
                      <path d="M11.997 2C6.478 2 2 6.478 2 11.997c0 1.762.463 3.414 1.268 4.85L2 22l5.27-1.246A9.953 9.953 0 0011.997 22C17.522 22 22 17.522 22 11.997 22 6.478 17.522 2 11.997 2z"/>
                    </svg>
                    <div>
                      <p class="text-sm font-semibold text-green-800">Order via WhatsApp</p>
                      <p class="text-xs text-green-600 mt-0.5">You'll be taken to WhatsApp with your order details pre-filled. We'll confirm and arrange payment.</p>
                    </div>
                  <% end %>
                </div>

                <!-- Submit -->
                <button
                  type="submit"
                  disabled={@submitting || @items == []}
                  class="w-full bg-orange-500 hover:bg-orange-600 disabled:bg-zinc-300 disabled:cursor-not-allowed text-white font-bold text-sm py-4 transition uppercase tracking-widest flex items-center justify-center gap-2"
                >
                  <%= if @submitting do %>
                    <svg class="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
                      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
                      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
                    </svg>
                    Processing…
                  <% else %>
                    <%= if @paystack_enabled, do: "Pay Now →", else: "Send Order via WhatsApp →" %>
                  <% end %>
                </button>

              </form>
            </div>

            <!-- ── Order Summary ─────────────────────────────── -->
            <div class="lg:col-span-1">
              <div class="bg-white rounded-xl border border-zinc-100 p-6 sticky top-20">
                <h2 class="font-black text-zinc-900 text-lg mb-4 font-display">Order Summary</h2>

                <!-- Items -->
                <div class="space-y-3 mb-5">
                  <%= for item <- @items do %>
                    <div class="flex gap-3 items-start">
                      <%= if item.image_url do %>
                        <img src={item.image_url} class="w-12 h-12 object-cover rounded-lg shrink-0 border border-zinc-100" />
                      <% else %>
                        <div class="w-12 h-12 bg-zinc-100 rounded-lg shrink-0"></div>
                      <% end %>
                      <div class="flex-1 min-w-0">
                        <p class="text-xs font-semibold text-zinc-800 leading-snug truncate"><%= item.product_name %></p>
                        <p class="text-xs text-zinc-400"><%= item.size %> × <%= item.quantity %></p>
                      </div>
                      <span class="text-xs font-bold text-zinc-900 shrink-0">
                        KSh <%= fmt(Decimal.mult(item.price, Decimal.new(item.quantity))) %>
                      </span>
                    </div>
                  <% end %>
                </div>

                <div class="border-t border-zinc-100 pt-4 space-y-2 text-sm text-zinc-600">
                  <div class="flex justify-between">
                    <span>Subtotal</span>
                    <span class="font-semibold text-zinc-900">KSh <%= fmt(@subtotal) %></span>
                  </div>
                  <div class="flex justify-between">
                    <span>Shipping</span>
                    <%= if Decimal.equal?(@shipping, Decimal.new("0")) do %>
                      <span class="font-semibold text-emerald-600">Free</span>
                    <% else %>
                      <span class="font-semibold text-zinc-900">KSh <%= fmt(@shipping) %></span>
                    <% end %>
                  </div>
                  <%= if @discount do %>
                    <div class="flex justify-between text-emerald-600">
                      <span>Discount (<%= @discount.code %>)</span>
                      <span class="font-semibold">−KSh <%= fmt(@discount_amount) %></span>
                    </div>
                  <% end %>
                </div>

                <div class="border-t border-zinc-100 mt-4 pt-4 flex justify-between items-center">
                  <span class="font-bold text-zinc-900">Total</span>
                  <span class="text-xl font-black text-zinc-900">
                    KSh <%= fmt(Decimal.sub(Decimal.add(@subtotal, @shipping), @discount_amount)) %>
                  </span>
                </div>
              </div>
            </div>

          </div>
        <% end %>

      </div>
    </div>
    """
  end
end

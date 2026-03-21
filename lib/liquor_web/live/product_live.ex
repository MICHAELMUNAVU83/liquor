defmodule LiquorWeb.ProductLive do
  use LiquorWeb, :live_view

  import LiquorWeb.ShopComponents

  alias Liquor.Catalog

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    product = Catalog.get_product_by_slug!(slug)

    active_variant =
      Enum.find(product.variants, & &1.is_default) || List.first(product.variants)

    {:ok,
     socket
     |> assign(
       current_page: "shop",
       page_title: product.name,
       page_description: product.description || "#{product.name} – available at The Mint Liquor Store",
       canonical_path: "/shop/#{product.slug}",
       product: product,
       active_variant: active_variant
     )}
  end

  @impl true
  def handle_event("select_variant", %{"variant_id" => vid}, socket) do
    vid_int = String.to_integer(vid)
    variant = Enum.find(socket.assigns.product.variants, &(&1.id == vid_int))
    {:noreply, assign(socket, active_variant: variant)}
  end

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <.page_hero
      title={@product.name}
      breadcrumb={[{"Home", "/"}, {"Shop", "/shop"}, {@product.name, "#"}]}
      image_url={@product.image_url || "https://images.unsplash.com/photo-1569529465841-dfecdab7503b?w=1600&auto=format&fit=crop"}
    />

    <div class="max-w-screen-xl mx-auto px-4 py-10">
      <div class="flex flex-col lg:flex-row gap-10">

        <!-- Product image -->
        <div class="lg:w-1/2">
          <div class="bg-zinc-50 rounded-2xl overflow-hidden aspect-square flex items-center justify-center border border-zinc-200">
            <%= if @product.image_url do %>
              <img
                src={@product.image_url}
                alt={@product.name}
                class="w-full h-full object-cover"
              />
            <% else %>
              <svg class="w-24 h-24 text-zinc-300" fill="none" stroke="currentColor" stroke-width="1" viewBox="0 0 24 24">
                <path d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
            <% end %>
          </div>
        </div>

        <!-- Product details -->
        <div class="lg:w-1/2 flex flex-col">

          <!-- Category / brand -->
          <p class="text-xs font-bold uppercase tracking-widest text-amber-500 mb-2">
            {@product.category.name}
            <%= if @product.brand, do: " · #{@product.brand.name}" %>
          </p>

          <!-- Name + badge -->
          <div class="flex items-start gap-3 mb-2">
            <h1 class="text-3xl font-black text-zinc-900 leading-tight">{@product.name}</h1>
            <%= if @product.badge do %>
              <span class={[
                "mt-1.5 shrink-0 text-[9px] font-black uppercase tracking-widest px-2 py-1 rounded",
                if(@product.badge == "best_seller",
                  do: "bg-emerald-500 text-white",
                  else: "bg-orange-500 text-white"
                )
              ]}>
                {String.replace(@product.badge, "_", " ")}
              </span>
            <% end %>
          </div>

          <%= if @product.year do %>
            <p class="text-sm text-zinc-400 mb-4">Vintage {@product.year}</p>
          <% end %>

          <!-- Price -->
          <div class="flex items-baseline gap-3 mb-6">
            <%= if @active_variant do %>
              <span class="text-4xl font-black text-zinc-900">
                KSh {format_money(@active_variant.price)}
              </span>
              <%= if @active_variant.compare_price &&
                     Decimal.compare(@active_variant.compare_price, @active_variant.price) == :gt do %>
                <span class="text-lg text-zinc-400 line-through">
                  KSh {format_money(@active_variant.compare_price)}
                </span>
                <% saving = Decimal.sub(@active_variant.compare_price, @active_variant.price)
                pct =
                  Decimal.div(saving, @active_variant.compare_price)
                  |> Decimal.mult(Decimal.new(100))
                  |> Decimal.round(0) %>
                <span class="text-sm font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded">
                  −{pct}% off
                </span>
              <% end %>
            <% else %>
              <span class="text-zinc-400">No variants available</span>
            <% end %>
          </div>

          <!-- ABV -->
          <%= if @active_variant && @active_variant.abv do %>
            <p class="text-sm text-zinc-500 mb-4">
              <span class="font-semibold">{@active_variant.abv}%</span> ABV
            </p>
          <% end %>

          <!-- Variant selector -->
          <%= if length(@product.variants) > 1 do %>
            <div class="mb-6">
              <p class="text-xs font-bold uppercase tracking-widest text-zinc-400 mb-2">Size</p>
              <div class="flex flex-wrap gap-2">
                <%= for v <- @product.variants do %>
                  <button
                    phx-click="select_variant"
                    phx-value-variant_id={v.id}
                    class={[
                      "px-4 py-2 rounded-lg border text-sm font-semibold transition",
                      if(@active_variant && @active_variant.id == v.id,
                        do: "bg-zinc-900 text-white border-zinc-900",
                        else: "border-zinc-200 text-zinc-600 hover:border-zinc-400"
                      ),
                      if(v.stock_quantity == 0,
                        do: "opacity-40 line-through cursor-not-allowed",
                        else: ""
                      )
                    ]}
                  >
                    {v.size}
                  </button>
                <% end %>
              </div>
            </div>
          <% else %>
            <%= if @active_variant do %>
              <p class="text-sm text-zinc-500 mb-6">{@active_variant.size}</p>
            <% end %>
          <% end %>

          <!-- Stock -->
          <%= if @active_variant do %>
            <%= if @active_variant.stock_quantity > 0 do %>
              <p class="text-sm text-emerald-600 font-semibold mb-4">
                In stock · {@active_variant.stock_quantity} available
              </p>
            <% else %>
              <p class="text-sm text-red-500 font-semibold mb-4">Out of stock</p>
            <% end %>
          <% end %>

          <!-- Add to cart -->
          <div class="mb-8">
            <%= if @active_variant && @active_variant.stock_quantity > 0 do %>
              <button
                data-cart-add
                data-variant-id={@active_variant.id}
                data-name={@product.name}
                data-size={@active_variant.size || ""}
                data-price={Decimal.to_string(@active_variant.price)}
                data-image={@product.image_url || ""}
                class="w-full bg-zinc-900 hover:bg-orange-500 text-white text-sm font-black uppercase tracking-widest py-4 rounded-xl transition"
              >
                Add to Cart
              </button>
            <% else %>
              <button
                disabled
                class="w-full bg-zinc-200 text-zinc-400 text-sm font-black uppercase tracking-widest py-4 rounded-xl cursor-not-allowed"
              >
                Out of Stock
              </button>
            <% end %>
          </div>

          <!-- Description -->
          <%= if @product.description && @product.description != "" do %>
            <div class="border-t border-zinc-200 pt-6">
              <p class="text-xs font-bold uppercase tracking-widest text-zinc-400 mb-3">Description</p>
              <p class="text-sm text-zinc-600 leading-relaxed">{@product.description}</p>
            </div>
          <% end %>

          <!-- Back to shop -->
          <div class="mt-8">
            <a href="/shop" class="text-sm font-semibold text-zinc-500 hover:text-orange-500 transition">
              ← Back to Shop
            </a>
          </div>
        </div>
      </div>
    </div>
    """
  end
end

defmodule LiquorWeb.HomeLive do
  use LiquorWeb, :live_view

  import LiquorWeb.HomeComponents

  alias Liquor.Catalog

  @impl true
  def mount(_params, _session, socket) do
    all_active   = Catalog.list_products(active: true)
    highlights   = Enum.take(all_active, 5)

    best_sellers =
      all_active
      |> Enum.filter(&(&1.badge == "best_seller"))
      |> Enum.take(4)
      |> then(fn
        [] -> Enum.take(all_active, 4)
        bs -> bs
      end)

    featured_products =
      all_active
      |> Enum.filter(&(&1.is_featured == true))

    categories = Catalog.list_categories()
    brands     = Catalog.list_brands()

    {:ok,
     socket
     |> assign(
       current_page:      "home",
       page_title:        "Home",
       highlights:        highlights,
       best_sellers:      best_sellers,
       featured_products: featured_products,
       categories:        categories,
       brands:            brands,
       selected_variants: %{}
     )}
  end

  @impl true
  def handle_event("select_variant", %{"product_id" => pid, "variant_id" => vid}, socket) do
    updated = Map.put(socket.assigns.selected_variants,
                      String.to_integer(pid),
                      String.to_integer(vid))
    {:noreply, assign(socket, selected_variants: updated)}
  end

  def handle_event("add_to_cart", _params, socket) do
    {:noreply, socket}
  end

  # ── Helpers ─────────────────────────────────────────────────────────────────

  defp active_variant(product, selected_variants) do
    vid = Map.get(selected_variants, product.id)
    cond do
      vid -> Enum.find(product.variants, &(&1.id == vid))
      true -> Enum.find(product.variants, &(&1.is_default)) || List.first(product.variants)
    end
  end

  # ── Render ──────────────────────────────────────────────────────────────────

  @impl true
  def render(assigns) do
    ~H"""
    <.hero_section />

    <!-- ── Today's Highlights ──────────────────────────────────────── -->
    <section class="max-w-screen-xl mx-auto px-4 py-10">
      <div class="flex items-center justify-between mb-6">
        <h2 class="text-xl sm:text-2xl font-black uppercase tracking-tight text-zinc-900 font-display">
          Today's <span class="font-light">Highlights</span>
        </h2>
        <a href="/shop" class="text-xs font-bold uppercase tracking-widest text-zinc-700 hover:text-amber-600 transition border-b border-zinc-400 hover:border-amber-500 pb-0.5">
          View All
        </a>
      </div>

      <%= if @highlights == [] do %>
        <p class="text-sm text-zinc-400 text-center py-10">No products yet — add some in the admin.</p>
      <% else %>
        <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-4">
          <%= for product <- @highlights do %>
            <.live_product_card
              product={product}
              active_variant={active_variant(product, @selected_variants)}
              selected_variants={@selected_variants}
            />
          <% end %>
        </div>
      <% end %>
    </section>

    <.popular_category categories={@categories} brands={@brands} />
    <.shop_by_spirits categories={@categories} />

    <!-- ── Best Sellers ────────────────────────────────────────────── -->
    <section class="max-w-screen-xl mx-auto px-4 py-10 border-t border-zinc-100">
      <div class="flex items-center justify-between mb-6">
        <h2 class="text-xl sm:text-2xl font-black uppercase tracking-tight text-zinc-900 font-display">
          Our <span class="font-light">Best Sellers</span>
        </h2>
        <a href="/shop" class="text-xs font-bold uppercase tracking-widest text-zinc-700 hover:text-amber-600 transition border-b border-zinc-400 hover:border-amber-500 pb-0.5">
          View All
        </a>
      </div>

      <%= if @best_sellers == [] do %>
        <p class="text-sm text-zinc-400 text-center py-10">No products yet.</p>
      <% else %>
        <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <%= for product <- @best_sellers do %>
            <.live_product_card
              product={product}
              active_variant={active_variant(product, @selected_variants)}
              selected_variants={@selected_variants}
            />
          <% end %>
        </div>
      <% end %>
    </section>

    <.products_of_month featured_products={@featured_products} />
    <.newsletter_signup />
    <.find_our_store />
    """
  end

  # ── Live product card ────────────────────────────────────────────────────────
  # Renders a product card with live variant size switching.
  # Works inside HomeLive so phx-click events are handled by this LiveView.

  defp live_product_card(assigns) do
    ~H"""
    <div class="border border-zinc-200 rounded-xl p-4 flex flex-col group hover:shadow-md transition-shadow relative bg-white">

      <!-- Badge -->
      <%= if @product.badge do %>
        <span class={[
          "absolute top-3 left-3 z-10 text-[9px] font-black uppercase tracking-wide text-white px-2 py-0.5 rounded",
          if(@product.badge == "best_seller", do: "bg-emerald-500", else: "bg-orange-500")
        ]}>
          <%= String.replace(@product.badge, "_", " ") %>
        </span>
      <% end %>

      <!-- Quick-action icons (hover) -->
      <div class="absolute top-3 right-3 z-10 flex flex-col gap-1.5 opacity-0 group-hover:opacity-100 transition-opacity">
        <button class="w-7 h-7 bg-white border border-zinc-200 rounded-full flex items-center justify-center shadow hover:bg-amber-50 transition">
          <svg class="w-3.5 h-3.5 text-zinc-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"/>
          </svg>
        </button>
      </div>

      <!-- Image -->
      <div class="flex items-center justify-center h-40 mb-3 overflow-hidden rounded-lg bg-zinc-50">
        <%= if @product.image_url do %>
          <img
            src={@product.image_url}
            alt={@product.name}
            class="h-full w-full object-cover group-hover:scale-105 transition-transform duration-300"
          />
        <% else %>
          <div class="w-16 h-36 bg-zinc-100 rounded flex items-center justify-center">
            <svg class="w-8 h-8 text-zinc-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1">
              <path stroke-linecap="round" stroke-linejoin="round" d="M20 3H4l2 7H6a1 1 0 000 2h.06l1.42 5.68A2 2 0 009.42 19h5.16a2 2 0 001.94-1.32L18 12h.06A1 1 0 0018 10h-2l2-7z"/>
            </svg>
          </div>
        <% end %>
      </div>

      <!-- Category -->
      <p class="text-[10px] text-zinc-400 uppercase tracking-widest mb-1">
        <%= @product.category.name %>
      </p>

      <!-- Name -->
      <p class="text-sm font-semibold text-zinc-800 leading-snug mb-2 line-clamp-2">
        <%= @product.name %>
      </p>

      <!-- Stars -->
      <div class="flex items-center gap-0.5 mb-2">
        <%= for _i <- 1..5 do %>
          <svg class="w-3 h-3 text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
            <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/>
          </svg>
        <% end %>
      </div>

      <!-- Price (updates when a size is selected) -->
      <div class="flex items-baseline gap-2 mb-2">
        <%= if @active_variant do %>
          <span class="text-base font-bold text-zinc-900">
            KSh <%= Decimal.round(@active_variant.price, 2) %>
          </span>
          <%= if @active_variant.compare_price &&
                 Decimal.compare(@active_variant.compare_price, @active_variant.price) == :gt do %>
            <span class="text-xs text-zinc-400 line-through">
              KSh <%= Decimal.round(@active_variant.compare_price, 2) %>
            </span>
          <% end %>
        <% else %>
          <span class="text-sm text-zinc-400">No variants</span>
        <% end %>
      </div>

      <!-- Size + ABV + stock row -->
      <div class="flex items-center gap-1.5 mb-3 flex-wrap">
        <%= if @active_variant do %>
          <span class="text-[10px] bg-zinc-100 text-zinc-600 px-2 py-0.5 rounded font-medium">
            <%= @active_variant.size %>
          </span>
          <%= if @active_variant.abv do %>
            <span class="text-[10px] bg-zinc-100 text-zinc-600 px-2 py-0.5 rounded font-medium">
              <%= @active_variant.abv %>%
            </span>
          <% end %>
          <%= if @active_variant.stock_quantity > 0 do %>
            <span class="text-[10px] bg-emerald-100 text-emerald-700 px-2 py-0.5 rounded font-semibold ml-auto">IN STOCK</span>
          <% else %>
            <span class="text-[10px] bg-red-100 text-red-600 px-2 py-0.5 rounded font-semibold ml-auto">OUT OF STOCK</span>
          <% end %>
        <% end %>
      </div>

      <!-- Size variant buttons (only if multiple variants) -->
      <%= if length(@product.variants) > 1 do %>
        <div class="flex flex-wrap gap-1 mb-3">
          <%= for v <- @product.variants do %>
            <button
              phx-click="select_variant"
              phx-value-product_id={@product.id}
              phx-value-variant_id={v.id}
              class={[
                "text-[10px] font-semibold px-2 py-0.5 rounded border transition",
                if(@active_variant && @active_variant.id == v.id,
                  do: "bg-zinc-900 text-white border-zinc-900",
                  else: "border-zinc-200 text-zinc-500 hover:border-zinc-500"),
                if(v.stock_quantity == 0, do: "opacity-40 line-through", else: "")
              ]}
            >
              <%= v.size %>
            </button>
          <% end %>
        </div>
      <% end %>

      <!-- Add to cart -->
      <div class="mt-auto">
        <%= if @active_variant && @active_variant.stock_quantity > 0 do %>
          <button
            data-cart-add
            data-variant-id={@active_variant.id}
            data-name={@product.name}
            data-size={@active_variant.size || ""}
            data-price={Decimal.to_string(@active_variant.price)}
            data-image={@product.image_url || ""}
            class="w-full bg-zinc-900 hover:bg-orange-500 text-white text-[10px] font-black uppercase tracking-widest py-2.5 rounded-lg transition"
          >
            Add to Cart
          </button>
        <% else %>
          <button disabled class="w-full bg-zinc-200 text-zinc-400 text-[10px] font-black uppercase tracking-widest py-2.5 rounded-lg cursor-not-allowed">
            Out of Stock
          </button>
        <% end %>
      </div>
    </div>
    """
  end
end

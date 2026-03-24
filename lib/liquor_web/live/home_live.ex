defmodule LiquorWeb.HomeLive do
  use LiquorWeb, :live_view

  import LiquorWeb.HomeComponents

  alias Liquor.Catalog
  alias Liquor.Settings

  @impl true
  def mount(_params, _session, socket) do
    all_active = Catalog.list_products(active: true)

    featured_ids_str = Settings.get("homepage_featured_ids", "")

    highlights =
      if featured_ids_str != "" do
        ids = featured_ids_str |> String.split(",", trim: true) |> Enum.map(&String.to_integer/1)

        Enum.filter(all_active, fn p -> p.id in ids end)
        |> Enum.sort_by(fn p -> Enum.find_index(ids, &(&1 == p.id)) end)
      else
        Enum.take(all_active, 5)
      end

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
    brands = Catalog.list_brands()

    s = Settings.all()

    {:ok,
     socket
     |> assign(
       current_page: "home",
       page_title: "Home",
       page_description:
         "The Mint Liquor Store – Nairobi's premier online liquor shop. Browse hundreds of wines, spirits, whisky, vodka, gin & craft beers. Free delivery over KSh 10,000.",
       canonical_path: "/",
       highlights: highlights,
       best_sellers: best_sellers,
       featured_products: featured_products,
       categories: categories,
       brands: brands,
       all_products: all_active,
       search_query: "",
       search_results: [],
       age_verified: false,
       selected_variants: %{},
       hero_main_label: s["hero_main_label"],
       hero_main_title: s["hero_main_title"],
       hero_main_price: s["hero_main_price"],
       hero_main_image: s["hero_main_image"],
       hero_main_link: s["hero_main_link"],
       hero_tile1_label: s["hero_tile1_label"],
       hero_tile1_title: s["hero_tile1_title"],
       hero_tile1_subtitle: s["hero_tile1_subtitle"],
       hero_tile1_image: s["hero_tile1_image"],
       hero_tile1_link: s["hero_tile1_link"],
       hero_tile2_title: s["hero_tile2_title"],
       hero_tile2_price: s["hero_tile2_price"],
       hero_tile2_image: s["hero_tile2_image"],
       hero_tile2_link: s["hero_tile2_link"]
     )}
  end

  @impl true
  def handle_event("hero_search", %{"q" => q}, socket) do
    q = String.trim(q)

    results =
      if String.length(q) >= 2 do
        lower = String.downcase(q)

        socket.assigns.all_products
        |> Enum.filter(fn p -> String.contains?(String.downcase(p.name), lower) end)
        |> Enum.take(8)
      else
        []
      end

    {:noreply, assign(socket, search_query: q, search_results: results)}
  end

  def handle_event("clear_search", _params, socket) do
    {:noreply, assign(socket, search_query: "", search_results: [])}
  end

  def handle_event("confirm_age", _params, socket) do
    {:noreply, assign(socket, age_verified: true)}
  end

  def handle_event("deny_age", _params, socket) do
    {:noreply, redirect(socket, external: "https://www.google.com")}
  end

  @impl true
  def handle_event("select_variant", %{"product_id" => pid, "variant_id" => vid}, socket) do
    updated =
      Map.put(
        socket.assigns.selected_variants,
        String.to_integer(pid),
        String.to_integer(vid)
      )

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
      true -> Enum.find(product.variants, & &1.is_default) || List.first(product.variants)
    end
  end

  # ── Render ──────────────────────────────────────────────────────────────────

  @impl true
  def render(assigns) do
    ~H"""
    <!-- ── Age Gate Modal ──────────────────────────────────────────── -->
    <%= if !@age_verified do %>
      <div class="fixed inset-0 z-[999] flex items-center justify-center bg-zinc-950/90 backdrop-blur-sm">
        <div class="bg-white rounded-2xl shadow-2xl max-w-sm w-full mx-4 overflow-hidden">
          <!-- Top accent bar -->
          <div class="h-1.5 w-full bg-gradient-to-r from-amber-400 via-orange-500 to-amber-400"></div>

          <div class="px-8 py-8 text-center">
            <!-- Icon -->
            <div class="text-5xl mb-4 select-none">🥃</div>

            <h2 class="text-xl font-black uppercase tracking-tight text-zinc-900 mb-1">
              Hold up!
            </h2>
            <p class="text-zinc-500 text-sm mb-6 leading-relaxed">
              You must be <span class="font-bold text-zinc-900">18 years or older</span>
              to enter.<br /> Are you of legal drinking age?
            </p>

            <div class="flex flex-col gap-3">
              <button
                phx-click="confirm_age"
                class="w-full bg-zinc-900 hover:bg-orange-500 text-white text-sm font-black uppercase tracking-widest py-3 rounded-xl transition-colors"
              >
                Yes, I'm 18+ — Let me in 🍸
              </button>
              <button
                phx-click="deny_age"
                class="w-full border border-zinc-200 text-zinc-400 hover:text-zinc-600 text-xs font-semibold uppercase tracking-widest py-2.5 rounded-xl transition-colors"
              >
                No, take me away
              </button>
            </div>

            <p class="text-[10px] text-zinc-300 mt-5 leading-relaxed">
              By entering you accept our terms of service.<br />Please drink responsibly.
            </p>
          </div>
        </div>
      </div>
    <% end %>

    <!-- ── Hero Search Bar ─────────────────────────────────────────── -->
    <div class="bg-white border-b border-zinc-100 px-4 py-2.5">
      <div class="max-w-screen-xl mx-auto flex justify-end">
        <div class="relative w-72" phx-click-away="clear_search">
          <form
            phx-change="hero_search"
            phx-submit="hero_search"
            class="flex items-center gap-2 bg-zinc-50 border border-zinc-200 rounded-lg px-3 py-1.5 focus-within:border-zinc-400 transition-all"
          >
            <svg
              class="w-3.5 h-3.5 text-zinc-400 flex-shrink-0"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="2"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M21 21l-4.35-4.35M17 11A6 6 0 105 11a6 6 0 0012 0z"
              />
            </svg>
            <input
              type="text"
              name="q"
              value={@search_query}
              placeholder="Search products…"
              autocomplete="off"
              class="flex-1 text-xs text-zinc-700 placeholder-zinc-400 border-none focus:border-none focus:outline-none bg-transparent w-full"
            />
            <%= if @search_query != "" do %>
              <button
                type="button"
                phx-click="clear_search"
                class="text-zinc-300 hover:text-zinc-500 transition flex-shrink-0"
              >
                <svg
                  class="w-3 h-3"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  stroke-width="2.5"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            <% end %>
          </form>

          <%= if @search_results != [] do %>
            <div class="absolute left-0 right-0 top-full mt-1 bg-white rounded-lg shadow-lg border border-zinc-100 z-50 overflow-hidden">
              <%= for product <- @search_results do %>
                <% variant =
                  Enum.find(product.variants, & &1.is_default) || List.first(product.variants) %>
                <a
                  href={"/shop/#{product.slug}"}
                  class="flex items-center gap-2.5 px-3 py-2 hover:bg-zinc-50 transition border-b border-zinc-50 last:border-0"
                >
                  <div class="w-7 h-7 rounded overflow-hidden bg-zinc-100 flex-shrink-0">
                    <%= if product.image_url do %>
                      <img
                        src={product.image_url}
                        alt={product.name}
                        class="w-full h-full object-cover"
                      />
                    <% else %>
                      <div class="w-full h-full flex items-center justify-center">
                        <svg
                          class="w-3.5 h-3.5 text-zinc-300"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                          stroke-width="1"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            d="M20 3H4l2 7H6a1 1 0 000 2h.06l1.42 5.68A2 2 0 009.42 19h5.16a2 2 0 001.94-1.32L18 12h.06A1 1 0 0018 10h-2l2-7z"
                          />
                        </svg>
                      </div>
                    <% end %>
                  </div>
                  <div class="flex-1 min-w-0">
                    <p class="text-xs font-medium text-zinc-800 truncate">{product.name}</p>
                    <p class="text-[10px] text-zinc-400">{product.category.name}</p>
                  </div>
                  <%= if variant do %>
                    <span class="text-xs font-semibold text-zinc-700 flex-shrink-0">
                      KSh {format_money(variant.price)}
                    </span>
                  <% end %>
                </a>
              <% end %>
              <a
                href={"/shop?q=#{URI.encode(@search_query)}"}
                class="flex items-center justify-center gap-1.5 px-3 py-2 text-[10px] font-semibold text-amber-600 hover:bg-zinc-50 transition tracking-wide"
              >
                See all results →
              </a>
            </div>
          <% end %>
        </div>
      </div>
    </div>

    <.hero_section
      main_label={@hero_main_label}
      main_title={@hero_main_title}
      main_price={@hero_main_price}
      main_image={@hero_main_image}
      main_link={@hero_main_link}
      tile1_label={@hero_tile1_label}
      tile1_title={@hero_tile1_title}
      tile1_subtitle={@hero_tile1_subtitle}
      tile1_image={@hero_tile1_image}
      tile1_link={@hero_tile1_link}
      tile2_title={@hero_tile2_title}
      tile2_price={@hero_tile2_price}
      tile2_image={@hero_tile2_image}
      tile2_link={@hero_tile2_link}
    />

    <!-- ── Today's Highlights ──────────────────────────────────────── -->
    <section class="max-w-screen-xl mx-auto px-4 py-10">
      <div class="flex items-center justify-between mb-6">
        <h2 class="text-xl sm:text-2xl font-black uppercase tracking-tight text-zinc-900 font-display">
          Today's <span class="font-light">Highlights</span>
        </h2>
        <a
          href="/shop"
          class="text-xs font-bold uppercase tracking-widest text-zinc-700 hover:text-amber-600 transition border-b border-zinc-400 hover:border-amber-500 pb-0.5"
        >
          View All
        </a>
      </div>

      <%= if @highlights == [] do %>
        <p class="text-sm text-zinc-400 text-center py-10">
          No products yet — add some in the admin.
        </p>
      <% else %>
        <div class="grid grid-cols-1 sm:grid-cols-3 lg:grid-cols-5 gap-4">
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

    <!-- ── Best Sellers ────────────────────────────────────────────── -->
    <section class="max-w-screen-xl mx-auto px-4 py-10 border-t border-zinc-100">
      <div class="flex items-center justify-between mb-6">
        <h2 class="text-xl sm:text-2xl font-black uppercase tracking-tight text-zinc-900 font-display">
          Our <span class="font-light">Best Sellers</span>
        </h2>
        <a
          href="/shop"
          class="text-xs font-bold uppercase tracking-widest text-zinc-700 hover:text-amber-600 transition border-b border-zinc-400 hover:border-amber-500 pb-0.5"
        >
          View All
        </a>
      </div>

      <%= if @best_sellers == [] do %>
        <p class="text-sm text-zinc-400 text-center py-10">No products yet.</p>
      <% else %>
        <div class="grid grid-cols-1 lg:grid-cols-4 gap-4">
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
          {String.replace(@product.badge, "_", " ")}
        </span>
      <% end %>
      
    <!-- Quick-action icons (hover) -->
      <div class="absolute top-3 right-3 z-10 flex flex-col gap-1.5 opacity-0 group-hover:opacity-100 transition-opacity">
        <button class="w-7 h-7 bg-white border border-zinc-200 rounded-full flex items-center justify-center shadow hover:bg-amber-50 transition">
          <svg
            class="w-3.5 h-3.5 text-zinc-500"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="2"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
            />
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
            <svg
              class="w-8 h-8 text-zinc-300"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="1"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M20 3H4l2 7H6a1 1 0 000 2h.06l1.42 5.68A2 2 0 009.42 19h5.16a2 2 0 001.94-1.32L18 12h.06A1 1 0 0018 10h-2l2-7z"
              />
            </svg>
          </div>
        <% end %>
      </div>
      
    <!-- Category -->
      <p class="text-[10px] text-zinc-400 uppercase tracking-widest mb-1">
        {@product.category.name}
      </p>
      
    <!-- Name -->
      <p class="text-sm font-semibold text-zinc-800 leading-snug mb-2 line-clamp-2">
        {@product.name}
      </p>
      
    <!-- Stars -->
      <div class="flex items-center gap-0.5 mb-2">
        <%= for _i <- 1..5 do %>
          <svg class="w-3 h-3 text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
            <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
          </svg>
        <% end %>
      </div>
      
    <!-- Price (updates when a size is selected) -->
      <div class="flex items-baseline gap-2 mb-2">
        <%= if @active_variant do %>
          <span class="text-base font-bold text-zinc-900">
            KSh {format_money(@active_variant.price)}
          </span>
          <%= if @active_variant.compare_price &&
                 Decimal.compare(@active_variant.compare_price, @active_variant.price) == :gt do %>
            <span class="text-xs text-zinc-400 line-through">
              KSh {format_money(@active_variant.compare_price)}
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
            {@active_variant.size}
          </span>
          <%= if @active_variant.abv do %>
            <span class="text-[10px] bg-zinc-100 text-zinc-600 px-2 py-0.5 rounded font-medium">
              {@active_variant.abv}%
            </span>
          <% end %>
          <%= if @active_variant.stock_quantity > 0 do %>
            <span class="text-[10px] bg-emerald-100 text-emerald-700 px-2 py-0.5 rounded font-semibold ml-auto">
              IN STOCK
            </span>
          <% else %>
            <span class="text-[10px] bg-red-100 text-red-600 px-2 py-0.5 rounded font-semibold ml-auto">
              OUT OF STOCK
            </span>
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
                  else: "border-zinc-200 text-zinc-500 hover:border-zinc-500"
                ),
                if(v.stock_quantity == 0, do: "opacity-40 line-through", else: "")
              ]}
            >
              {v.size}
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
          <button
            disabled
            class="w-full bg-zinc-200 text-zinc-400 text-[10px] font-black uppercase tracking-widest py-2.5 rounded-lg cursor-not-allowed"
          >
            Out of Stock
          </button>
        <% end %>
      </div>
    </div>
    """
  end
end

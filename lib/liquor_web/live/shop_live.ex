defmodule LiquorWeb.ShopLive do
  use LiquorWeb, :live_view

  import LiquorWeb.ShopComponents

  alias Liquor.Catalog

  @per_page 12

  @impl true
  def mount(_params, _session, socket) do
    categories = Catalog.list_categories()
    brands     = Catalog.list_brands()

    {:ok,
     socket
     |> assign(
       current_page:       "shop",
       page_title:         "Shop – Products",
       sort:               "default",
       per_page:           "#{@per_page}",
       view:               "grid",
       page:               1,
       selected_categories: [],
       selected_brands:    [],
       categories:         categories,
       brands:             brands,
       # map of product_id => selected variant_id for size picker
       selected_variants:  %{}
     )
     |> assign_products()}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    page = String.to_integer(params["page"] || "1")
    {:noreply, socket |> assign(page: page) |> assign_products()}
  end

  @impl true
  def handle_event("sort_changed", %{"sort" => sort}, socket) do
    {:noreply, socket |> assign(sort: sort, page: 1) |> assign_products()}
  end

  def handle_event("per_page_changed", %{"per_page" => per_page}, socket) do
    {:noreply, socket |> assign(per_page: per_page, page: 1) |> assign_products()}
  end

  def handle_event("set_view", %{"view" => view}, socket) do
    {:noreply, assign(socket, view: view)}
  end

  def handle_event("toggle_category", %{"category" => cat}, socket) do
    selected = socket.assigns.selected_categories
    updated  = if cat in selected, do: List.delete(selected, cat), else: [cat | selected]
    {:noreply, socket |> assign(selected_categories: updated, page: 1) |> assign_products()}
  end

  def handle_event("toggle_brand", %{"brand" => brand}, socket) do
    selected = socket.assigns.selected_brands
    updated  = if brand in selected, do: List.delete(selected, brand), else: [brand | selected]
    {:noreply, socket |> assign(selected_brands: updated, page: 1) |> assign_products()}
  end

  # Customer picks a variant size on a product card
  def handle_event("select_variant", %{"product_id" => pid, "variant_id" => vid}, socket) do
    pid_int = String.to_integer(pid)
    vid_int = String.to_integer(vid)
    updated = Map.put(socket.assigns.selected_variants, pid_int, vid_int)
    {:noreply, assign(socket, selected_variants: updated)}
  end

  def handle_event("add_to_cart", _params, socket) do
    {:noreply, socket}
  end

  # ── Load / filter / sort / paginate ────────────────────────────────────────

  defp assign_products(socket) do
    %{sort: sort, per_page: per_page_str, page: page,
      selected_categories: cats, selected_brands: brands} = socket.assigns

    per_page = String.to_integer(per_page_str)

    # Load from DB — preloads category, brand, variants
    all = Catalog.list_products(active: true)

    filtered =
      all
      |> filter_by_categories(cats)
      |> filter_by_brands(brands)

    sorted =
      case sort do
        "price_asc"  -> Enum.sort_by(filtered, &default_price/1)
        "price_desc" -> Enum.sort_by(filtered, &default_price/1, :desc)
        "newest"     -> Enum.sort_by(filtered, & &1.inserted_at, {:desc, DateTime})
        _            -> filtered
      end

    total       = length(sorted)
    total_pages = max(ceil(total / per_page), 1)
    paged       = sorted |> Enum.drop((page - 1) * per_page) |> Enum.take(per_page)

    assign(socket, products: paged, total_products: total, total_pages: total_pages)
  end

  defp filter_by_categories(products, []), do: products
  defp filter_by_categories(products, cats) do
    lower = Enum.map(cats, &String.downcase/1)
    Enum.filter(products, fn p -> String.downcase(p.category.name) in lower end)
  end

  defp filter_by_brands(products, []), do: products
  defp filter_by_brands(products, brands) do
    lower = Enum.map(brands, &String.downcase/1)
    Enum.filter(products, fn p ->
      p.brand && String.downcase(p.brand.name) in lower
    end)
  end

  defp default_price(%{variants: []}), do: Decimal.new("0")
  defp default_price(%{variants: variants}) do
    default = Enum.find(variants, &(&1.is_default)) || hd(variants)
    default.price
  end

  # ── Render ──────────────────────────────────────────────────────────────────

  @impl true
  def render(assigns) do
    ~H"""
    <.page_hero
      title="Products"
      breadcrumb={[{"Home", "/"}, {"Shop", "/shop"}]}
      image_url="https://images.unsplash.com/photo-1569529465841-dfecdab7503b?w=1600&auto=format&fit=crop"
    />

    <div class="max-w-screen-xl mx-auto px-4 py-8">
      <div class="flex gap-8 items-start">

        <!-- Sidebar -->
        <aside class="w-56 flex-shrink-0 hidden lg:block">
          <.live_filter_sidebar
            selected_categories={@selected_categories}
            selected_brands={@selected_brands}
            categories={@categories}
            brands={@brands}
            products={@products}
          />
        </aside>

        <!-- Main content -->
        <div class="flex-1 min-w-0">
          <.live_filter_toolbar
            sort={@sort}
            per_page={@per_page}
            view={@view}
            total={@total_products}
          />

          <%= if @products == [] do %>
            <div class="py-24 text-center">
              <svg class="w-12 h-12 text-zinc-300 mx-auto mb-3" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path d="M20 7l-8-4-8 4m16 0v10l-8 4m0-14v14m0 0l-8-4V7"/>
              </svg>
              <p class="text-zinc-500 font-semibold mb-1">No products found</p>
              <p class="text-zinc-400 text-sm">Try adjusting your filters</p>
            </div>
          <% else %>
            <div class={[
              if(@view == "grid",
                do: "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5",
                else: "flex flex-col gap-4"
              )
            ]}>
              <%= for product <- @products do %>
                <.product_card
                  product={product}
                  view={@view}
                  selected_variant_id={Map.get(@selected_variants, product.id)}
                />
              <% end %>
            </div>
          <% end %>

          <.pagination
            current_page={@page}
            total_pages={@total_pages}
            base_url="/shop"
          />
        </div>
      </div>
    </div>
    """
  end

  # ── Private live-aware components ───────────────────────────────────────────

  defp live_filter_toolbar(assigns) do
    ~H"""
    <div class="flex items-center justify-between py-4 border-b border-zinc-200 mb-6 gap-4 flex-wrap">
      <div class="flex items-center gap-3">
        <span class="text-sm font-semibold text-zinc-500"><%= @total %> products</span>
        <div class="h-4 w-px bg-zinc-300"></div>
        <form phx-change="sort_changed">
          <select
            name="sort"
            class="text-sm border border-zinc-200 rounded px-3 py-1.5 text-zinc-700 bg-white focus:outline-none focus:ring-1 focus:ring-amber-400 cursor-pointer"
          >
            <option value="default"    selected={@sort == "default"}>Default sorting</option>
            <option value="price_asc"  selected={@sort == "price_asc"}>Price: Low → High</option>
            <option value="price_desc" selected={@sort == "price_desc"}>Price: High → Low</option>
            <option value="newest"     selected={@sort == "newest"}>Newest</option>
          </select>
        </form>
        <form phx-change="per_page_changed">
          <select
            name="per_page"
            class="text-sm border border-zinc-200 rounded px-3 py-1.5 text-zinc-700 bg-white focus:outline-none focus:ring-1 focus:ring-amber-400 cursor-pointer"
          >
            <%= for n <- ["6", "12", "24", "48"] do %>
              <option value={n} selected={@per_page == n}>Show <%= n %></option>
            <% end %>
          </select>
        </form>
      </div>

      <div class="flex items-center gap-1 ml-auto">
        <span class="text-xs text-zinc-400 mr-2 hidden sm:inline">View as</span>
        <button
          phx-click="set_view" phx-value-view="grid"
          class={["p-1.5 rounded transition", if(@view == "grid", do: "text-amber-600 bg-amber-50", else: "text-zinc-400 hover:text-zinc-700")]}
        >
          <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
            <rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/>
            <rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/>
          </svg>
        </button>
        <button
          phx-click="set_view" phx-value-view="list"
          class={["p-1.5 rounded transition", if(@view == "list", do: "text-amber-600 bg-amber-50", else: "text-zinc-400 hover:text-zinc-700")]}
        >
          <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16M4 18h16"/>
          </svg>
        </button>
      </div>
    </div>
    """
  end

  defp live_filter_sidebar(assigns) do
    ~H"""
    <div class="space-y-6 text-sm text-zinc-700">

      <!-- Categories -->
      <div class="border-b border-zinc-200 pb-5">
        <p class="font-bold text-sm text-zinc-900 mb-3">Product Categories</p>
        <ul class="space-y-2">
          <%= for cat <- @categories do %>
            <li>
              <label class="flex items-center justify-between gap-2 cursor-pointer group">
                <span class="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={cat.name in @selected_categories}
                    phx-click="toggle_category"
                    phx-value-category={cat.name}
                    class="w-4 h-4 rounded border-zinc-300 text-amber-500 focus:ring-amber-400 cursor-pointer"
                  />
                  <span class="group-hover:text-amber-600 transition"><%= cat.name %></span>
                </span>
              </label>
            </li>
          <% end %>
        </ul>
      </div>

      <!-- Brands -->
      <%= if @brands != [] do %>
        <div class="border-b border-zinc-200 pb-5">
          <p class="font-bold text-sm text-zinc-900 mb-3">Brands</p>
          <ul class="space-y-2">
            <%= for brand <- @brands do %>
              <li>
                <label class="flex items-center gap-2 cursor-pointer group">
                  <input
                    type="checkbox"
                    checked={brand.name in @selected_brands}
                    phx-click="toggle_brand"
                    phx-value-brand={brand.name}
                    class="w-4 h-4 rounded border-zinc-300 text-amber-500 focus:ring-amber-400 cursor-pointer"
                  />
                  <span class="group-hover:text-amber-600 transition"><%= brand.name %></span>
                </label>
              </li>
            <% end %>
          </ul>
        </div>
      <% end %>
    </div>
    """
  end

  # ── Product card ─────────────────────────────────────────────────────────────
  # One card per product. Variants shown as size buttons; clicking a size
  # updates the displayed price live without a page reload.

  defp product_card(assigns) do
    product  = assigns.product
    variants = product.variants

    # Determine which variant is "active" on this card
    active_variant =
      cond do
        assigns.selected_variant_id ->
          Enum.find(variants, &(&1.id == assigns.selected_variant_id)) ||
          Enum.find(variants, &(&1.is_default)) ||
          List.first(variants)
        true ->
          Enum.find(variants, &(&1.is_default)) || List.first(variants)
      end

    assigns = assign(assigns,
      variants:       variants,
      active_variant: active_variant
    )

    ~H"""
    <div class={[
      "bg-white border border-zinc-200 rounded-xl overflow-hidden hover:shadow-lg transition-shadow group",
      if(@view == "list", do: "flex gap-4", else: "flex flex-col")
    ]}>
      <!-- Image -->
      <div class={[
        "relative overflow-hidden bg-zinc-50",
        if(@view == "list", do: "w-32 h-32 shrink-0 rounded-l-xl", else: "aspect-[4/3]")
      ]}>
        <%= if @product.image_url do %>
          <img
            src={@product.image_url}
            alt={@product.name}
            class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
          />
        <% else %>
          <div class="w-full h-full flex items-center justify-center text-zinc-300">
            <svg class="w-10 h-10" fill="none" stroke="currentColor" stroke-width="1" viewBox="0 0 24 24">
              <path d="M20 3H4l2 7H6a1 1 0 000 2h.06l1.42 5.68A2 2 0 009.42 19h5.16a2 2 0 001.94-1.32L18 12h.06A1 1 0 0018 10h-2l2-7z"/>
            </svg>
          </div>
        <% end %>

        <!-- Badge -->
        <%= if @product.badge do %>
          <span class={[
            "absolute top-2 left-2 text-[9px] font-black uppercase tracking-widest px-2 py-0.5 rounded",
            if(@product.badge == "best_seller", do: "bg-emerald-500 text-white", else: "bg-orange-500 text-white")
          ]}>
            <%= String.replace(@product.badge, "_", " ") %>
          </span>
        <% end %>

        <!-- Stock badge -->
        <%= if @active_variant && @active_variant.stock_quantity == 0 do %>
          <span class="absolute bottom-2 right-2 text-[9px] font-black uppercase tracking-widest px-2 py-0.5 rounded bg-red-500 text-white">
            Out of stock
          </span>
        <% end %>
      </div>

      <!-- Info -->
      <div class="flex flex-col flex-1 p-4">
        <p class="text-[10px] font-bold uppercase tracking-widest text-amber-500 mb-1">
          <%= @product.category.name %>
          <%= if @product.brand, do: " · #{@product.brand.name}" %>
        </p>

        <h3 class="font-black text-zinc-900 leading-snug mb-2 line-clamp-2">
          <%= @product.name %>
        </h3>

        <!-- Variant / size selector -->
        <%= if length(@variants) > 1 do %>
          <div class="flex flex-wrap gap-1.5 mb-3">
            <%= for v <- @variants do %>
              <button
                phx-click="select_variant"
                phx-value-product_id={@product.id}
                phx-value-variant_id={v.id}
                class={[
                  "text-xs font-semibold px-2.5 py-1 rounded-lg border transition",
                  if(@active_variant && @active_variant.id == v.id,
                    do: "bg-zinc-900 text-white border-zinc-900",
                    else: "border-zinc-200 text-zinc-600 hover:border-zinc-400 hover:text-zinc-900"),
                  if(v.stock_quantity == 0, do: "opacity-50 line-through cursor-not-allowed", else: "")
                ]}
              >
                <%= v.size %>
              </button>
            <% end %>
          </div>
        <% end %>

        <!-- Price row -->
        <div class="flex items-baseline gap-2 mb-3">
          <%= if @active_variant do %>
            <span class="text-xl font-black text-zinc-900">
              KSh <%= Decimal.round(@active_variant.price, 2) %>
            </span>
            <%= if @active_variant.compare_price &&
                   Decimal.compare(@active_variant.compare_price, @active_variant.price) == :gt do %>
              <span class="text-sm text-zinc-400 line-through">
                KSh <%= Decimal.round(@active_variant.compare_price, 2) %>
              </span>
              <%
                saving = Decimal.sub(@active_variant.compare_price, @active_variant.price)
                pct    = Decimal.div(saving, @active_variant.compare_price) |> Decimal.mult(Decimal.new(100)) |> Decimal.round(0)
              %>
              <span class="text-xs font-bold text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded">
                −<%= pct %>%
              </span>
            <% end %>
            <%= if @active_variant.abv do %>
              <span class="text-xs text-zinc-400 ml-auto"><%= @active_variant.abv %>% ABV</span>
            <% end %>
          <% else %>
            <span class="text-sm text-zinc-400">No variants</span>
          <% end %>
        </div>

        <!-- Single variant label (when only one size) -->
        <%= if length(@variants) == 1 && @active_variant do %>
          <p class="text-xs text-zinc-400 -mt-2 mb-3"><%= @active_variant.size %></p>
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
              class="w-full bg-zinc-900 hover:bg-orange-500 text-white text-xs font-black uppercase tracking-widest py-2.5 rounded-lg transition"
            >
              Add to Cart
            </button>
          <% else %>
            <button disabled class="w-full bg-zinc-200 text-zinc-400 text-xs font-black uppercase tracking-widest py-2.5 rounded-lg cursor-not-allowed">
              Out of Stock
            </button>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end

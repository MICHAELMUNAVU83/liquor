defmodule LiquorWeb.ShopComponents do
  @moduledoc """
  Shop / Products page UI components for the Liquor store.

  Sections:
    - shop_promo_bar/1      – top announcement strip (3 trust messages)
    - shop_navbar/1         – slim navbar: logo, nav links, search, locale, icons
    - page_hero/1           – full-width dark hero with page title + breadcrumb
    - filter_toolbar/1      – sort / per-page / view-toggle bar above the grid
    - shop_layout/1         – sidebar + product grid wrapper (accepts inner_content slot)
    - filter_sidebar/1      – collapsible filter panels (category, price, brands, size, year)
    - product_grid/1        – responsive 3-column product card grid
    - shop_product_card/1   – individual product card (image, badge, meta, CTA)
    - pagination/1          – numbered page links with prev/next arrows
  """

  use Phoenix.Component

  # ---------------------------------------------------------------------------
  # Shop Promo Bar
  # ---------------------------------------------------------------------------

  @doc """
  Three-message amber announcement strip at the very top of every shop page.
  """
  def shop_promo_bar(assigns) do
    ~H"""
    <div class="bg-amber-50 border-b border-amber-200 text-zinc-700 text-xs font-medium py-2">
      <div class="max-w-screen-xl mx-auto px-4 flex flex-col sm:flex-row items-center justify-between gap-2 text-center sm:text-left">
        <div class="flex items-center gap-2">
          <svg
            class="w-4 h-4 text-amber-500 flex-shrink-0"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="2"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          <span class="uppercase tracking-wide font-semibold">
            Online Drinks Retailer of the Year
          </span>
        </div>
        <div class="hidden sm:block h-4 w-px bg-amber-300"></div>
        <div class="flex items-center gap-2">
          <svg
            class="w-4 h-4 text-amber-500 flex-shrink-0"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="2"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4"
            />
          </svg>
          <span class="uppercase tracking-wide font-semibold">The Mint Liquor Store</span>
        </div>
        <div class="hidden sm:block h-4 w-px bg-amber-300"></div>
        <div class="flex items-center gap-2">
          <div class="flex text-yellow-400">
            <%= for _i <- 1..5 do %>
              <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
              </svg>
            <% end %>
          </div>
          <span class="uppercase tracking-wide font-semibold">
            Rated 4.8/5 Based on 44000+ Reviews
          </span>
        </div>
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Shop Navbar
  # ---------------------------------------------------------------------------

  @doc """
  Compact shop navbar: logo left, nav centre, search + locale + icons right.
  """
  def shop_navbar(assigns) do
    ~H"""
    <header class="bg-white border-b border-zinc-200 sticky top-0 z-50">
      <div class="max-w-screen-xl mx-auto px-4 py-3 flex items-center gap-6">
        <!-- Logo -->
        <a href="/" class="flex-shrink-0 flex flex-col leading-tight mr-2">
          <span class="text-xl font-black tracking-tight text-zinc-900 uppercase">
            COR<span class="text-amber-500">|</span>NO
          </span>
          <span class="text-[8px] tracking-[0.3em] text-zinc-400 uppercase font-medium">
            Liquor Store
          </span>
        </a>
        
    <!-- Nav links -->
        <nav class="hidden md:flex items-center gap-1 text-sm font-semibold text-zinc-700 flex-1">
          <a href="/" class="px-3 py-2 hover:text-amber-600 transition flex items-center gap-1">
            HOME
            <svg
              class="w-3 h-3"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="2.5"
            >
              <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
            </svg>
          </a>
          <a
            href="/shop"
            class="px-3 py-2 text-amber-600 border-b-2 border-amber-500 flex items-center gap-1"
          >
            SHOP
            <svg
              class="w-3 h-3"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="2.5"
            >
              <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
            </svg>
          </a>
          <a href="/blogs" class="px-3 py-2 hover:text-amber-600 transition flex items-center gap-1">
            BLOGS
            <svg
              class="w-3 h-3"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="2.5"
            >
              <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
            </svg>
          </a>
          <a href="/pages" class="px-3 py-2 hover:text-amber-600 transition flex items-center gap-1">
            PAGES
            <svg
              class="w-3 h-3"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="2.5"
            >
              <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
            </svg>
          </a>
          <a href="/contact" class="px-3 py-2 hover:text-amber-600 transition">CONTACT</a>
        </nav>
        
    <!-- Search -->
        <div class="flex items-center gap-2 ml-auto">
          <form
            action="/shop"
            method="get"
            class="hidden lg:flex items-center rounded-lg overflow-hidden border border-zinc-300 focus-within:border-amber-500 focus-within:ring-2 focus-within:ring-amber-200 transition-all"
          >
            <div class="relative flex items-center">
              <svg
                class="absolute left-3 w-4 h-4 text-zinc-400 pointer-events-none"
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
                placeholder="Search products..."
                class="text-sm text-zinc-600 py-2 pl-9 pr-4 w-52 focus:outline-none placeholder-zinc-400 bg-white"
              />
            </div>
            <button
              type="submit"
              class="bg-orange-500 hover:bg-orange-600 transition text-white px-4 py-2"
            >
              <svg
                class="w-4 h-4"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                stroke-width="2.5"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M21 21l-4.35-4.35M17 11A6 6 0 105 11a6 6 0 0012 0z"
                />
              </svg>
            </button>
          </form>
          
    <!-- Locale -->
          <div class="hidden lg:flex items-center gap-2 text-xs font-semibold text-zinc-700 border-l border-zinc-200 pl-4 ml-2">
            <span>🇰🇪 ENGLISH</span>
            <svg
              class="w-3 h-3"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="2.5"
            >
              <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
            </svg>
            <span class="border-l border-zinc-200 pl-2">KES</span>
            <svg
              class="w-3 h-3"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="2.5"
            >
              <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
            </svg>
          </div>
          
    <!-- Icon buttons -->
          <a href="/admin" class="p-2 rounded-full hover:bg-zinc-100 transition" title="Admin">
            <svg
              class="w-5 h-5 text-zinc-700"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="1.8"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
              />
            </svg>
          </a>
          <button class="p-2 rounded-full hover:bg-zinc-100 transition relative" title="Cart">
            <svg
              class="w-5 h-5 text-zinc-700"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="1.8"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-1.5 6h13"
              />
            </svg>
            <span class="absolute top-0.5 right-0.5 w-3.5 h-3.5 bg-zinc-800 rounded-full text-[8px] font-bold text-white flex items-center justify-center">
              0
            </span>
          </button>
        </div>
      </div>
    </header>
    """
  end

  # ---------------------------------------------------------------------------
  # Page Hero
  # ---------------------------------------------------------------------------

  @doc """
  Full-width dark overlay hero banner with page title and breadcrumb.

  ## Attributes
    - `title`      – page heading (default "Products")
    - `breadcrumb` – list of {label, url} tuples rendered as "Home — Shop"
    - `image_url`  – background image URL
  """
  attr :title, :string, default: "Products"
  attr :breadcrumb, :list, default: [{"Home", "/"}, {"Shop", "/shop"}]

  attr :image_url, :string,
    default:
      "https://images.unsplash.com/photo-1569529465841-dfecdab7503b?w=1600&auto=format&fit=crop"

  def page_hero(assigns) do
    ~H"""
    <section class="relative h-52 md:h-64 flex items-center justify-center overflow-hidden">
      <img src={@image_url} alt={@title} class="absolute inset-0 w-full h-full object-cover" />
      <div class="absolute inset-0 bg-black/60"></div>
      <div class="relative z-10 text-center text-white">
        <p class="text-sm text-zinc-300 mb-2">
          <%= for {{label, url}, i} <- Enum.with_index(@breadcrumb) do %>
            <a href={url} class="hover:text-amber-400 transition">{label}</a>
            <%= if i < length(@breadcrumb) - 1 do %>
              <span class="mx-2 text-zinc-500">—</span>
            <% end %>
          <% end %>
        </p>
        <h1 class="text-4xl md:text-5xl font-black uppercase tracking-tight">{@title}</h1>
      </div>
    </section>
    """
  end

  # ---------------------------------------------------------------------------
  # Filter Toolbar
  # ---------------------------------------------------------------------------

  @doc """
  Toolbar row above the product grid: filter toggle, sort select, per-page select,
  and view-as grid/list toggle buttons.

  ## Attributes
    - `total`       – total product count string shown next to the sort (optional)
    - `view`        – current view mode: "grid" | "list" (default "grid")
    - `sort`        – current sort value (default "default")
    - `per_page`    – current per-page value (default "24")
  """
  attr :total, :string, default: nil
  attr :view, :string, default: "grid"
  attr :sort, :string, default: "default"
  attr :per_page, :string, default: "24"

  def filter_toolbar(assigns) do
    ~H"""
    <div class="flex items-center justify-between py-4 border-b border-zinc-200 mb-6 gap-4 flex-wrap">
      <!-- left: filter toggle + sort + per-page -->
      <div class="flex items-center gap-3">
        <button class="flex items-center gap-2 text-sm font-semibold text-zinc-700 hover:text-amber-600 transition">
          <span>Filter</span>
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2a1 1 0 01-.293.707L13 13.414V19a1 1 0 01-.553.894l-4 2A1 1 0 017 21v-7.586L3.293 6.707A1 1 0 013 6V4z"
            />
          </svg>
        </button>

        <div class="h-4 w-px bg-zinc-300"></div>

        <select
          name="sort"
          class="text-sm border border-zinc-200 rounded px-3 py-1.5 text-zinc-700 bg-white focus:outline-none focus:ring-1 focus:ring-amber-400 cursor-pointer"
        >
          <option value="default" selected={@sort == "default"}>Default sorting</option>
          <option value="price_asc" selected={@sort == "price_asc"}>Price: Low to High</option>
          <option value="price_desc" selected={@sort == "price_desc"}>Price: High to Low</option>
          <option value="newest" selected={@sort == "newest"}>Newest</option>
          <option value="rating" selected={@sort == "rating"}>Top Rated</option>
        </select>
      </div>
      
    <!-- right: view toggles -->
      <div class="flex items-center gap-1 ml-auto">
        <span class="text-xs text-zinc-400 mr-2 hidden sm:inline">View as</span>
        <button class={[
          "p-1.5 rounded transition",
          if(@view == "grid",
            do: "text-amber-600 bg-amber-50",
            else: "text-zinc-400 hover:text-zinc-700"
          )
        ]}>
          <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
            <rect x="3" y="3" width="7" height="7" rx="1" />
            <rect x="14" y="3" width="7" height="7" rx="1" />
            <rect x="3" y="14" width="7" height="7" rx="1" />
            <rect x="14" y="14" width="7" height="7" rx="1" />
          </svg>
        </button>
        <button class={[
          "p-1.5 rounded transition",
          if(@view == "list",
            do: "text-amber-600 bg-amber-50",
            else: "text-zinc-400 hover:text-zinc-700"
          )
        ]}>
          <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16M4 18h16" />
          </svg>
        </button>
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Shop Layout (sidebar + grid wrapper)
  # ---------------------------------------------------------------------------

  @doc """
  Two-column layout wrapper: collapsible filter sidebar on the left,
  product content (toolbar + grid + pagination) on the right.

  Uses an inner_content slot for the right-hand column.
  """
  slot :inner_block, required: true

  def shop_layout(assigns) do
    ~H"""
    <div class="max-w-screen-xl mx-auto px-4 py-8">
      <div class="flex gap-8 items-start">
        <!-- Sidebar -->
        <aside class="w-56 flex-shrink-0 hidden lg:block">
          <.filter_sidebar />
        </aside>
        
    <!-- Main content -->
        <div class="flex-1 min-w-0">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Filter Sidebar
  # ---------------------------------------------------------------------------

  @doc """
  Left-hand sidebar with collapsible filter panels:
  Product Categories, Price range, Brands, Size, Year.
  """
  def filter_sidebar(assigns) do
    ~H"""
    <div class="space-y-6 text-sm text-zinc-700">
      <!-- Product Categories -->
      <.filter_panel title="Product Categories">
        <ul class="space-y-2 mt-3">
          <%= for {cat, count} <- [
            {"Brandy", 6}, {"Gin", 3}, {"Mezcal", 7}, {"Mixers", 5},
            {"Rum", 4}, {"Tequila", 8}, {"Vermouth", 8}, {"Vodka", 10}, {"Whiskies", 9}
          ] do %>
            <li>
              <label class="flex items-center justify-between gap-2 cursor-pointer group">
                <span class="flex items-center gap-2">
                  <input
                    type="checkbox"
                    class="w-4 h-4 rounded border-zinc-300 text-amber-500 focus:ring-amber-400 cursor-pointer"
                  />
                  <span class="group-hover:text-amber-600 transition">{cat}</span>
                </span>
                <span class="text-zinc-400 text-xs">({count})</span>
              </label>
            </li>
          <% end %>
        </ul>
      </.filter_panel>
      
    <!-- Price Range -->
      <.filter_panel title="Price">
        <div class="mt-3 space-y-3">
          <div class="relative h-1.5 bg-zinc-200 rounded-full">
            <div class="absolute left-[1%] right-[0%] h-full bg-zinc-800 rounded-full"></div>
            <div class="absolute left-[1%] w-4 h-4 bg-white border-2 border-zinc-800 rounded-full -top-[5px] cursor-pointer shadow">
            </div>
            <div class="absolute right-[0%] w-4 h-4 bg-white border-2 border-zinc-800 rounded-full -top-[5px] cursor-pointer shadow">
            </div>
          </div>
          <div class="flex items-center justify-between text-xs text-zinc-600">
            <span>$10.00</span>
            <span>—</span>
            <span>$1,000.00</span>
            <button class="text-[10px] font-bold uppercase tracking-widest text-zinc-700 hover:text-amber-600 transition border-b border-zinc-400 hover:border-amber-500 ml-2">
              Filter
            </button>
          </div>
        </div>
      </.filter_panel>
      
    <!-- Brands -->
      <.filter_panel title="Brands">
        <ul class="space-y-2 mt-3">
          <%= for {brand, count} <- [
            {"Bundaberg", 0}, {"Chivas Regal", 0}, {"Heineken", 3},
            {"Jack Daniels", 4}, {"Jameson", 3}, {"Jim Beam", 8},
            {"Johnnie Walker", 3}, {"Vodka O", 9}
          ] do %>
            <li>
              <label class="flex items-center justify-between gap-2 cursor-pointer group">
                <span class="flex items-center gap-2">
                  <input
                    type="checkbox"
                    class="w-4 h-4 rounded border-zinc-300 text-amber-500 focus:ring-amber-400 cursor-pointer"
                    disabled={count == 0}
                  />
                  <span class={[
                    "group-hover:text-amber-600 transition",
                    if(count == 0, do: "text-zinc-400", else: "")
                  ]}>
                    {brand}
                  </span>
                </span>
                <span class="text-zinc-400 text-xs">({count})</span>
              </label>
            </li>
          <% end %>
        </ul>
      </.filter_panel>
      
    <!-- Size -->
      <.filter_panel title="Size">
        <ul class="space-y-2 mt-3">
          <%= for {size, count} <- [
            {"1.75L", 12}, {"100ml", 8}, {"1L", 16}, {"200ml", 11}, {"50ml", 13}
          ] do %>
            <li>
              <label class="flex items-center justify-between gap-2 cursor-pointer group">
                <span class="flex items-center gap-2">
                  <input
                    type="checkbox"
                    class="w-4 h-4 rounded border-zinc-300 text-amber-500 focus:ring-amber-400 cursor-pointer"
                  />
                  <span class="group-hover:text-amber-600 transition">{size}</span>
                </span>
                <span class="text-zinc-400 text-xs">({count})</span>
              </label>
            </li>
          <% end %>
        </ul>
      </.filter_panel>
      
    <!-- Year -->
      <.filter_panel title="Year">
        <ul class="space-y-2 mt-3">
          <%= for {year, count} <- [
            {"3 Year", 21}, {"4 Year", 19}, {"5 Year", 21},
            {"6 Year", 22}, {"7 Year", 20}, {"8 Year", 24}, {"9 Year", 23}
          ] do %>
            <li>
              <label class="flex items-center justify-between gap-2 cursor-pointer group">
                <span class="flex items-center gap-2">
                  <input
                    type="checkbox"
                    class="w-4 h-4 rounded border-zinc-300 text-amber-500 focus:ring-amber-400 cursor-pointer"
                  />
                  <span class="group-hover:text-amber-600 transition">{year}</span>
                </span>
                <span class="text-zinc-400 text-xs">({count})</span>
              </label>
            </li>
          <% end %>
        </ul>
      </.filter_panel>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Product Grid
  # ---------------------------------------------------------------------------

  @doc """
  Responsive 3-column product grid. Pass a list of product maps to `products`.

  Each product map may have the following keys (all optional with defaults):
    - `:badge`       – nil | "BEST SELLER" | "LIMITED EDITION"
    - `:badge_color` – Tailwind bg class, default "bg-amber-500"
    - `:category`    – string
    - `:name`        – string
    - `:reviews`     – integer
    - `:price`       – string, e.g. "$10.26–$19.48"
    - `:size`        – string, e.g. "1.75L"
    - `:abv`         – string, e.g. "35%"
    - `:in_stock`    – boolean
    - `:has_options` – boolean (shows "Select Options" vs "Add to Cart")
    - `:image_url`   – product image URL or nil
    - `:rating`      – integer 1–5 (default 4)
  """
  attr :products, :list, default: []

  def product_grid(assigns) do
    ~H"""
    <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-5">
      <%= for product <- @products do %>
        <.shop_product_card
          badge={Map.get(product, :badge)}
          badge_color={Map.get(product, :badge_color, "bg-amber-500")}
          category={Map.get(product, :category, "")}
          name={Map.get(product, :name, "")}
          reviews={Map.get(product, :reviews, 5)}
          price={Map.get(product, :price, "")}
          size={Map.get(product, :size, "")}
          abv={Map.get(product, :abv, "")}
          in_stock={Map.get(product, :in_stock, true)}
          has_options={Map.get(product, :has_options, false)}
          image_url={Map.get(product, :image_url)}
          rating={Map.get(product, :rating, 4)}
          variant_id={Map.get(product, :id)}
        />
      <% end %>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Shop Product Card
  # ---------------------------------------------------------------------------

  @doc """
  Individual product card used in the shop grid: tall card with product
  image, optional badge, category, name, star rating, price, size/abv tags,
  stock pill, and a full-width Add to Cart / Select Options button.
  """
  attr :badge, :string, default: nil
  attr :badge_color, :string, default: "bg-amber-500"
  attr :category, :string, default: ""
  attr :name, :string, default: ""
  attr :reviews, :integer, default: 5
  attr :price, :string, default: ""
  attr :size, :string, default: ""
  attr :abv, :string, default: ""
  attr :in_stock, :boolean, default: true
  attr :has_options, :boolean, default: false
  attr :image_url, :string, default: nil
  attr :rating, :integer, default: 4
  attr :variant_id, :integer, default: nil

  def shop_product_card(assigns) do
    ~H"""
    <div class="border border-zinc-200 rounded-lg flex flex-col group hover:shadow-lg transition-shadow duration-200 relative overflow-hidden">
      <!-- Product image -->
      <div class="relative flex items-center justify-center bg-white h-60 p-6">
        <%= if @badge do %>
          <span class={[
            "absolute top-3 left-3 text-[9px] font-black uppercase tracking-wide text-white px-2 py-0.5 rounded z-10",
            @badge_color
          ]}>
            {@badge}
          </span>
        <% end %>
        
    <!-- Quick-action icons (appear on hover) -->
        <div class="absolute top-3 right-3 flex flex-col gap-1.5 opacity-0 group-hover:opacity-100 transition-opacity duration-200 z-10">
          <button
            title="Wishlist"
            class="w-7 h-7 bg-white border border-zinc-200 rounded-full flex items-center justify-center shadow hover:bg-amber-50 transition"
          >
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
          <button
            title="Compare"
            class="w-7 h-7 bg-white border border-zinc-200 rounded-full flex items-center justify-center shadow hover:bg-amber-50 transition"
          >
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
                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
              />
            </svg>
          </button>
          <button
            title="Quick view"
            class="w-7 h-7 bg-white border border-zinc-200 rounded-full flex items-center justify-center shadow hover:bg-amber-50 transition"
          >
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
                d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4"
              />
            </svg>
          </button>
        </div>

        <%= if @image_url do %>
          <img
            src={@image_url}
            alt={@name}
            class="h-full w-auto object-contain group-hover:scale-105 transition-transform duration-300"
          />
        <% else %>
          <!-- Bottle placeholder -->
          <div class="flex flex-col items-center justify-center h-40 w-20 bg-zinc-100 rounded-lg">
            <svg
              class="w-10 h-10 text-zinc-300"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="1"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M9 3v1m6-1v1M9 19v1m6-1v1M5 9H4m1 6H4m16-6h-1m1 6h-1M7 4h10l1 4v8a2 2 0 01-2 2H8a2 2 0 01-2-2V8l1-4z"
              />
            </svg>
          </div>
        <% end %>
      </div>
      
    <!-- Card body -->
      <div class="px-4 pb-4 flex flex-col flex-1">
        <p class="text-[10px] text-zinc-400 uppercase tracking-widest mb-1">{@category}</p>
        <p class="text-sm font-semibold text-zinc-800 leading-snug mb-2 line-clamp-2">{@name}</p>
        
    <!-- Stars -->
        <div class="flex items-center gap-1 mb-2">
          <%= for i <- 1..5 do %>
            <svg
              class={["w-3 h-3", if(i <= @rating, do: "text-yellow-400", else: "text-zinc-200")]}
              fill="currentColor"
              viewBox="0 0 20 20"
            >
              <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
            </svg>
          <% end %>
          <span class="text-[10px] text-zinc-400 ml-1">{@reviews} Reviews</span>
        </div>
        
    <!-- Price -->
        <p class="text-base font-bold text-zinc-900 mb-3">{@price}</p>
        
    <!-- Tags + stock -->
        <div class="flex items-center gap-2 mb-4 flex-wrap">
          <%= if @size != "" do %>
            <span class="text-[10px] bg-zinc-100 text-zinc-600 px-2 py-0.5 rounded font-medium">
              {@size}
            </span>
          <% end %>
          <%= if @abv != "" do %>
            <span class="text-[10px] bg-zinc-100 text-zinc-600 px-2 py-0.5 rounded font-medium">
              {@abv}
            </span>
          <% end %>
          <span class={[
            "text-[10px] px-2 py-0.5 rounded font-semibold ml-auto",
            if(@in_stock, do: "bg-emerald-100 text-emerald-700", else: "bg-red-100 text-red-600")
          ]}>
            {if @in_stock, do: "IN STOCK", else: "OUT OF STOCK"}
          </span>
        </div>
        
    <!-- CTA -->
        <%= if @has_options do %>
          <button class="mt-auto w-full py-2.5 text-xs font-bold uppercase tracking-widest transition border border-zinc-800 text-zinc-900 hover:bg-zinc-900 hover:text-white">
            Select Options
          </button>
        <% else %>
          <button
            data-cart-add="true"
            data-variant-id={@variant_id || ""}
            data-name={@name}
            data-size={@size}
            data-price={String.replace(@price, "$", "")}
            data-image={@image_url || ""}
            disabled={is_nil(@variant_id) or not @in_stock}
            class={[
              "mt-auto w-full py-2.5 text-xs font-bold uppercase tracking-widest transition border",
              if(@in_stock,
                do:
                  "bg-zinc-900 text-white hover:bg-orange-500 border-zinc-900 hover:border-orange-500 cursor-pointer",
                else: "bg-zinc-200 text-zinc-400 border-zinc-200 cursor-not-allowed"
              )
            ]}
          >
            {if @in_stock, do: "Add to Cart", else: "Out of Stock"}
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Pagination
  # ---------------------------------------------------------------------------

  @doc """
  Numbered pagination with previous/next arrows.

  ## Attributes
    - `current_page`  – active page number (integer, default 1)
    - `total_pages`   – total number of pages (integer, default 3)
    - `base_url`      – base path for page links, e.g. "/shop" (default "/shop")
  """
  attr :current_page, :integer, default: 1
  attr :total_pages, :integer, default: 3
  attr :base_url, :string, default: "/shop"

  def pagination(assigns) do
    ~H"""
    <div class="flex items-center justify-center gap-1 mt-10 mb-4">
      <!-- Prev arrow -->
      <a
        href={if @current_page > 1, do: "#{@base_url}?page=#{@current_page - 1}", else: "#"}
        class={[
          "w-9 h-9 flex items-center justify-center border rounded transition text-sm font-medium",
          if(@current_page > 1,
            do: "border-zinc-300 text-zinc-700 hover:bg-zinc-100",
            else: "border-zinc-200 text-zinc-300 cursor-default pointer-events-none"
          )
        ]}
      >
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" />
        </svg>
      </a>
      
    <!-- Page numbers -->
      <%= for page <- 1..@total_pages do %>
        <a
          href={"#{@base_url}?page=#{page}"}
          class={[
            "w-9 h-9 flex items-center justify-center border rounded transition text-sm font-medium",
            if(page == @current_page,
              do: "bg-orange-500 border-orange-500 text-white font-bold",
              else: "border-zinc-300 text-zinc-700 hover:bg-zinc-100"
            )
          ]}
        >
          {page}
        </a>
      <% end %>
      
    <!-- Next arrow -->
      <a
        href={
          if @current_page < @total_pages, do: "#{@base_url}?page=#{@current_page + 1}", else: "#"
        }
        class={[
          "w-9 h-9 flex items-center justify-center border rounded transition text-sm font-medium",
          if(@current_page < @total_pages,
            do: "border-zinc-300 text-zinc-700 hover:bg-zinc-100",
            else: "border-zinc-200 text-zinc-300 cursor-default pointer-events-none"
          )
        ]}
      >
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7" />
        </svg>
      </a>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Private helper: collapsible filter panel
  # ---------------------------------------------------------------------------

  attr :title, :string, required: true
  slot :inner_block, required: true

  defp filter_panel(assigns) do
    ~H"""
    <div class="border-b border-zinc-200 pb-5">
      <button class="w-full flex items-center justify-between font-bold text-sm text-zinc-900 hover:text-amber-600 transition">
        <span>{@title}</span>
        <svg
          class="w-4 h-4 text-zinc-500"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          stroke-width="2"
        >
          <path stroke-linecap="round" stroke-linejoin="round" d="M20 12H4" />
        </svg>
      </button>
      {render_slot(@inner_block)}
    </div>
    """
  end
end

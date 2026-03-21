defmodule LiquorWeb.HomeComponents do
  @moduledoc """
  Home page UI components for the Liquor store.

  Sections:
    - promo_banner/1        – scrolling top announcement bar
    - navbar/1              – site header with logo, search, cart
    - feature_strip/1       – 4-column trust badges
    - hero_section/1        – featured banner + two smaller promos
    - todays_highlights/1   – horizontal product card row
    - popular_category/1    – 4-column category mega-menu + brand logos
    - shop_by_spirits/1     – circular spirit category tiles
    - best_sellers/1        – 4-column best-seller product cards
    - products_of_month/1   – 3-panel dark image feature cards
    - newsletter_signup/1   – split newsletter sign-up section
    - find_our_store/1      – address + embedded map panel
    - site_footer/1         – multi-column footer + bottom bar
  """

  use Phoenix.Component

  import LiquorWeb.CoreComponents, only: [format_money: 1]

  # ---------------------------------------------------------------------------
  # Promo Banner
  # ---------------------------------------------------------------------------

  @doc """
  Scrolling dark announcement bar across the full width.
  """
  def promo_banner(assigns) do
    ~H"""
    <div class="bg-zinc-900 text-yellow-400 py-2 overflow-hidden">
      <div class="flex animate-marquee whitespace-nowrap gap-12">
        <%= for _i <- 1..8 do %>
          <span class="inline-flex items-center gap-3 text-xs font-semibold tracking-widest uppercase">
            <svg class="w-4 h-4 text-orange-500" viewBox="0 0 24 24" fill="currentColor">
              <circle cx="12" cy="12" r="10" />
              <path d="M12 6v6l4 2" stroke="#111" stroke-width="2" stroke-linecap="round" fill="none" />
            </svg>
            Start Saving 10% On Every Order
          </span>
        <% end %>
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Navbar
  # ---------------------------------------------------------------------------

  @doc """
  Full site header: top utility bar + main nav with logo, search, icons.
  """
  def navbar(assigns) do
    ~H"""
    <header class="bg-white shadow-sm sticky top-0 z-50">
      <!-- utility row -->
      <div class="bg-amber-50 border-b border-amber-100 text-xs text-zinc-600 px-6 py-1.5 flex items-center justify-between">
        <span class="flex items-center gap-2">
          <span class="fi fi-gb"></span>
          <span class="font-medium uppercase tracking-wide">English</span>
          <span class="mx-2 text-zinc-300">|</span>
          <span class="font-medium">KES</span>
        </span>
        <span>
          Free help &amp; advice
          <a href="#" class="text-amber-600 font-semibold hover:underline ml-1">Learn more</a>
        </span>
      </div>
      
    <!-- main header row -->
      <div class="max-w-screen-xl mx-auto px-4 py-3 flex items-center gap-4">
        <!-- Logo -->
        <a href="/" class="flex-shrink-0 mr-4">
          <img src="/images/logo.png" alt="The Mint Liquor Store" class="h-10 w-auto object-contain" />
        </a>
        
    <!-- Category + Search -->
        <form
          action="/shop"
          method="get"
          class="flex flex-1 max-w-2xl rounded-lg overflow-hidden border border-zinc-300 focus-within:border-amber-500 focus-within:ring-2 focus-within:ring-amber-200 transition-all"
        >
          <select
            name="category"
            class="bg-zinc-100 text-sm text-zinc-700 px-3 py-2.5 border-r border-zinc-300 focus:outline-none cursor-pointer hover:bg-zinc-200 transition"
          >
            <option value="">All Categories</option>
            <option>Spirits</option>
            <option>Wine</option>
            <option>Whiskey</option>
            <option>Beer</option>
          </select>
          <div class="relative flex-1 flex items-center">
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
              class="w-full pl-9 pr-4 py-2.5 text-sm text-zinc-700 focus:outline-none bg-white"
            />
          </div>
          <button
            type="submit"
            class="bg-orange-500 hover:bg-orange-600 active:bg-orange-700 transition text-white px-6 text-sm font-bold tracking-wide uppercase flex items-center gap-2"
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
            <span class="hidden sm:inline">Search</span>
          </button>
        </form>
        
    <!-- Contact -->
        <div class="hidden lg:flex items-center gap-6 ml-4 flex-shrink-0">
          <a href="tel:0841234568" class="flex items-center gap-2 text-sm text-zinc-700">
            <div class="w-9 h-9 rounded-full bg-amber-100 flex items-center justify-center">
              <svg
                class="w-4 h-4 text-amber-600"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                stroke-width="2"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M3 5a2 2 0 012-2h2.28a1 1 0 01.948.684l1.2 3.6a1 1 0 01-.27 1.047L7.6 9.9A16.016 16.016 0 0014.1 16.4l1.57-1.558a1 1 0 011.047-.27l3.6 1.2A1 1 0 0121 16.72V19a2 2 0 01-2 2h-1C9.163 21 3 14.837 3 7V5z"
                />
              </svg>
            </div>
            <div>
              <p class="text-[10px] text-zinc-400 uppercase tracking-wide">Need Support</p>
              <p class="font-semibold text-zinc-800">(084) 123 - 456 88</p>
            </div>
          </a>
          <a href="mailto:corino@example.com" class="flex items-center gap-2 text-sm text-zinc-700">
            <div class="w-9 h-9 rounded-full bg-amber-100 flex items-center justify-center">
              <svg
                class="w-4 h-4 text-amber-600"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                stroke-width="2"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                />
              </svg>
            </div>
            <div>
              <p class="text-[10px] text-zinc-400 uppercase tracking-wide">Contact</p>
              <p class="font-semibold text-zinc-800">corino@example.com</p>
            </div>
          </a>
        </div>
        
    <!-- Icons -->
        <div class="flex items-center gap-3 ml-auto flex-shrink-0">
          <a
            href="/admin"
            class="p-2 rounded-full hover:bg-zinc-100 transition relative"
            title="Admin"
          >
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
                d="M5.121 17.804A8 8 0 1118.88 6.196M15 12a3 3 0 11-6 0 3 3 0 016 0z"
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
            <span class="absolute top-0.5 right-0.5 w-4 h-4 bg-orange-500 rounded-full text-[9px] font-bold text-white flex items-center justify-center">
              0
            </span>
          </button>
        </div>
      </div>
      
    <!-- bottom nav -->
      <nav class="border-t border-zinc-100 max-w-screen-xl mx-auto px-4">
        <ul class="flex items-center gap-6 text-sm font-semibold text-zinc-700 py-2">
          <li>
            <a
              href="/"
              class="hover:text-amber-600 transition py-2 border-b-2 border-transparent hover:border-amber-500"
            >
              HOME
            </a>
          </li>
          <li>
            <a
              href="/shop"
              class="hover:text-amber-600 transition py-2 border-b-2 border-transparent hover:border-amber-500"
            >
              SHOP
            </a>
          </li>
          <li>
            <a
              href="/blogs"
              class="hover:text-amber-600 transition py-2 border-b-2 border-transparent hover:border-amber-500"
            >
              BLOGS
            </a>
          </li>
          <li>
            <a
              href="/pages"
              class="hover:text-amber-600 transition py-2 border-b-2 border-transparent hover:border-amber-500"
            >
              PAGES
            </a>
          </li>
          <li>
            <a
              href="/contact"
              class="hover:text-amber-600 transition py-2 border-b-2 border-transparent hover:border-amber-500"
            >
              CONTACT
            </a>
          </li>
        </ul>
      </nav>
    </header>
    """
  end

  # ---------------------------------------------------------------------------
  # Feature Strip
  # ---------------------------------------------------------------------------

  @doc """
  Four trust badges in a horizontal strip below the hero.
  """
  def feature_strip(assigns) do
    ~H"""
    <section class="bg-zinc-50 border-y border-zinc-200">
      <div class="max-w-screen-xl mx-auto px-4 grid grid-cols-2 md:grid-cols-3 divide-x divide-zinc-200">
        <div class="flex items-center gap-3 px-6 py-4">
          <svg
            class="w-8 h-8 text-zinc-500 flex-shrink-0"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="1.5"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4"
            />
          </svg>
          <div>
            <p class="font-bold text-sm text-zinc-900">Fast, Free Shipping</p>
            <p class="text-xs text-zinc-500">On all orders over KSh 10,000</p>
          </div>
        </div>
        <div class="flex items-center gap-3 px-6 py-4">
          <svg
            class="w-8 h-8 text-zinc-500 flex-shrink-0"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="1.5"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
            />
          </svg>
          <div>
            <p class="font-bold text-sm text-zinc-900">Authenticity Guarantee</p>
            <p class="text-xs text-zinc-500">Shop for items with confidence</p>
          </div>
        </div>
        <div class="flex items-center gap-3 px-6 py-4">
          <svg
            class="w-8 h-8 text-zinc-500 flex-shrink-0"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="1.5"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"
            />
          </svg>
          <div>
            <p class="font-bold text-sm text-zinc-900">Secure Payments</p>
            <p class="text-xs text-zinc-500">Secure payment methods</p>
          </div>
        </div>
        <div class="flex items-center gap-3 px-6 py-4">
          <svg
            class="w-8 h-8 text-zinc-500 flex-shrink-0"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="1.5"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M18.364 5.636l-3.536 3.536m0 5.656l3.536 3.536M9.172 9.172L5.636 5.636m3.536 9.192l-3.536 3.536M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-5 0a4 4 0 11-8 0 4 4 0 018 0z"
            />
          </svg>
          <div>
            <p class="font-bold text-sm text-zinc-900">Top Rated Customer Service</p>
            <p class="text-xs text-zinc-500">Quick responses and solutions</p>
          </div>
        </div>
      </div>
    </section>
    """
  end

  # ---------------------------------------------------------------------------
  # Hero Section
  # ---------------------------------------------------------------------------

  @doc """
  Large hero banner on the left with two smaller promotional tiles on the right.
  All text and images are driven by settings.
  """
  attr :main_label, :string, default: "Today's Highlights"
  attr :main_title, :string, default: "Whiskies of The Month"
  attr :main_price, :string, default: "KSh 3,999"

  attr :main_image, :string,
    default:
      "https://images.unsplash.com/photo-1569529465841-dfecdab7503b?w=900&auto=format&fit=crop"

  attr :main_link, :string, default: "/shop"
  attr :tile1_label, :string, default: "Black Friday"
  attr :tile1_title, :string, default: "Shop & Save"
  attr :tile1_subtitle, :string, default: "selected bourbons"

  attr :tile1_image, :string,
    default:
      "https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=600&auto=format&fit=crop"

  attr :tile1_link, :string, default: "/shop"
  attr :tile2_title, :string, default: "Exclusive Offer"
  attr :tile2_price, :string, default: "KSh 2,499"

  attr :tile2_image, :string,
    default:
      "https://images.unsplash.com/photo-1527281400683-1aae777175f8?w=600&auto=format&fit=crop"

  attr :tile2_link, :string, default: "/shop"

  def hero_section(assigns) do
    ~H"""
    <section class="max-w-screen-xl mx-auto px-4 py-6">
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-4 lg:h-[480px]">
        <!-- main banner -->
        <div class="lg:col-span-2 relative rounded-lg overflow-hidden bg-teal-900 flex items-end p-10 h-[320px] lg:h-auto">
          <img
            src={@main_image}
            alt={@main_title}
            class="absolute inset-0 w-full h-full object-cover opacity-60"
          />
          <div class="relative z-10 text-white">
            <p class="text-xs font-semibold uppercase tracking-widest text-amber-300 mb-2">
              {@main_label}
            </p>
            <h2 class="text-3xl sm:text-4xl md:text-5xl font-black uppercase leading-tight mb-3 font-display">
              {@main_title}
            </h2>
            <p class="text-sm text-zinc-300 mb-5">
              start from <span class="text-white font-bold text-lg">{@main_price}</span>
            </p>
            <a
              href={@main_link}
              class="inline-block bg-white text-zinc-900 font-bold text-sm px-6 py-2.5 hover:bg-orange-500 hover:text-white transition"
            >
              SHOP NOW
            </a>
          </div>
        </div>
        
    <!-- right tiles -->
        <div class="flex flex-col gap-4">
          <div class="flex-1 relative rounded-lg overflow-hidden bg-zinc-800 flex items-end p-6">
            <img
              src={@tile1_image}
              alt={@tile1_title}
              class="absolute inset-0 w-full h-full object-cover opacity-50"
            />
            <div class="relative z-10 text-white">
              <%= if @tile1_label && @tile1_label != "" do %>
                <p class="text-xs text-zinc-300 uppercase tracking-widest mb-1">{@tile1_label}</p>
              <% end %>
              <h3 class="text-xl font-black uppercase leading-tight mb-3">
                {@tile1_title}<br />
                <%= if @tile1_subtitle && @tile1_subtitle != "" do %>
                  <span class="text-sm font-medium normal-case">{@tile1_subtitle}</span>
                <% end %>
              </h3>
              <a
                href={@tile1_link}
                class="inline-block bg-white text-zinc-900 font-bold text-xs px-5 py-2 hover:bg-orange-500 hover:text-white transition"
              >
                SHOP NOW
              </a>
            </div>
          </div>

          <div class="flex-1 relative rounded-lg overflow-hidden bg-amber-900 flex items-end p-6">
            <img
              src={@tile2_image}
              alt={@tile2_title}
              class="absolute inset-0 w-full h-full object-cover opacity-50"
            />
            <div class="relative z-10 text-white">
              <h3 class="text-xl font-black uppercase leading-tight mb-1">{@tile2_title}</h3>
              <%= if @tile2_price && @tile2_price != "" do %>
                <p class="text-sm text-zinc-300 mb-3">
                  start from <span class="text-white font-bold">{@tile2_price}</span>
                </p>
              <% end %>
              <a
                href={@tile2_link}
                class="inline-block bg-white text-zinc-900 font-bold text-xs px-5 py-2 hover:bg-orange-500 hover:text-white transition"
              >
                SHOP NOW
              </a>
            </div>
          </div>
        </div>
      </div>
    </section>
    """
  end

  # ---------------------------------------------------------------------------
  # Today's Highlights (REMOVED — handled live in HomeLive)
  # ---------------------------------------------------------------------------

  @doc false
  def todays_highlights(assigns) do
    ~H"""
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

      <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-4">
        <.product_card
          badge={nil}
          category="Vodka"
          name="Grey Goose Vodka"
          reviews={5}
          price="$34.99"
          size="700ML"
          abv="40%"
          in_stock={true}
          has_options={false}
          variant_id={40}
          image_url="https://images.unsplash.com/photo-1571104508999-893933ded431?w=400&auto=format&fit=crop"
        />
        <.product_card
          badge={nil}
          category="Tequila"
          name="Patron Silver Tequila"
          reviews={5}
          price="$42.99"
          size="700ML"
          abv="40%"
          in_stock={true}
          has_options={false}
          variant_id={38}
          image_url="https://images.unsplash.com/photo-1598373182133-52452f7691ef?w=400&auto=format&fit=crop"
        />
        <.product_card
          badge="LIMITED EDITION"
          badge_color="bg-orange-500"
          category="Tequila"
          name="Patron Reposado Tequila"
          reviews={5}
          price="$46.99"
          size="700ML"
          abv="40%"
          in_stock={true}
          has_options={false}
          variant_id={54}
          image_url="https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=400&auto=format&fit=crop"
        />
        <.product_card
          badge={nil}
          category="Gin"
          name="Tanqueray London Dry Gin"
          reviews={5}
          price="$21.99"
          size="700ML"
          abv="43%"
          in_stock={true}
          has_options={false}
          variant_id={45}
          image_url="https://images.unsplash.com/photo-1547595628-c61a29f496f0?w=400&auto=format&fit=crop"
        />
        <.product_card
          badge="BEST SELLER"
          badge_color="bg-emerald-500"
          category="Rum"
          name="Bacardi Superior White Rum"
          reviews={5}
          price="$16.99"
          size="700ML"
          abv="40%"
          in_stock={true}
          has_options={false}
          variant_id={43}
          image_url="https://images.unsplash.com/photo-1551538827-9c037cb4f32a?w=400&auto=format&fit=crop"
        />
      </div>
    </section>
    """
  end

  # ---------------------------------------------------------------------------
  # Popular Category
  # ---------------------------------------------------------------------------

  @doc """
  Four-column mega category section with sub-category links, images and brand logos.
  """
  def popular_category(assigns) do
    assigns = assign_new(assigns, :categories, fn -> [] end)
    assigns = assign_new(assigns, :brands, fn -> [] end)

    ~H"""
    <section class="max-w-screen-xl mx-auto px-4 py-10 border-t border-zinc-100">
      <div class="flex items-center justify-between mb-6">
        <div>
          <p class="text-xs font-semibold uppercase tracking-widest text-zinc-400 mb-1">Start Here</p>
          <h2 class="text-xl sm:text-2xl font-black uppercase tracking-tight text-zinc-900 font-display">
            Popular <span class="font-light">Category</span>
          </h2>
        </div>
        <a
          href="/shop"
          class="text-xs font-bold uppercase tracking-widest text-zinc-700 hover:text-amber-600 transition border-b border-zinc-400 hover:border-amber-500 pb-0.5"
        >
          Shop All Range
        </a>
      </div>

      <%= if @categories == [] do %>
        <p class="text-sm text-zinc-400 py-8 text-center">
          No categories yet — add some in the admin.
        </p>
      <% else %>
        <div class="grid grid-cols-1 sm:grid-cols-3 lg:grid-cols-4 gap-4 mb-8">
          <%= for cat <- @categories do %>
            <div class="border border-zinc-200 rounded-lg p-5 hover:border-amber-300 transition">
              <div class="flex items-center justify-between mb-3">
                <h3 class="text-base font-bold text-zinc-900">{cat.name}</h3>
                <%= if cat.image_url do %>
                  <img src={cat.image_url} alt={cat.name} class="w-14 h-10 object-cover rounded" />
                <% end %>
              </div>
              <%= if cat.description do %>
                <p class="text-xs text-zinc-500 mb-3 line-clamp-2">{cat.description}</p>
              <% end %>
              <a
                href={"/shop?category=#{cat.slug}"}
                class="text-amber-600 text-xs font-semibold hover:underline"
              >
                Shop All {cat.name}
              </a>
            </div>
          <% end %>
        </div>
      <% end %>
      
    <!-- Brands scrolling marquee -->
      <%= if @brands != [] do %>
        <div class="relative overflow-hidden border-t border-zinc-100 pt-6">
          <div class="flex animate-marquee whitespace-nowrap gap-0">
            <%= for _repeat <- 1..4 do %>
              <%= for brand <- @brands do %>
                <a
                  href={"/shop?brand=#{brand.slug}"}
                  class="inline-flex items-center gap-3 px-8 text-sm font-black uppercase tracking-[0.2em] text-zinc-400 hover:text-amber-600 transition"
                >
                  <span class="w-1.5 h-1.5 rounded-full bg-orange-400 flex-shrink-0"></span>
                  {brand.name}
                </a>
              <% end %>
            <% end %>
          </div>
        </div>
      <% end %>
    </section>
    """
  end

  # ---------------------------------------------------------------------------
  # Shop by Spirits
  # ---------------------------------------------------------------------------

  @doc """
  Six spirit categories displayed as circular images with labels.
  """
  def shop_by_spirits(assigns) do
    assigns = assign_new(assigns, :categories, fn -> [] end)

    ~H"""
    <section class="max-w-screen-xl mx-auto px-4 py-10 border-t border-zinc-100">
      <div class="flex items-center justify-between mb-8">
        <h2 class="text-xl sm:text-2xl font-black uppercase tracking-tight text-zinc-900 font-display">
          Shop By <span class="font-light">Category</span>
        </h2>
        <a
          href="/shop"
          class="text-xs font-bold uppercase tracking-widest text-zinc-700 hover:text-amber-600 transition border-b border-zinc-400 hover:border-amber-500 pb-0.5"
        >
          View All
        </a>
      </div>

      <%= if @categories == [] do %>
        <p class="text-sm text-zinc-400 text-center py-8">
          No categories yet — add some in the admin.
        </p>
      <% else %>
        <div class={"grid gap-4 " <> (if length(@categories) <= 6, do: "grid-cols-3 sm:grid-cols-#{min(length(@categories), 6)}", else: "grid-cols-3 sm:grid-cols-6")}>
          <%= for cat <- Enum.take(@categories, 12) do %>
            <a href={"/shop?category=#{cat.slug}"} class="group flex flex-col items-center gap-3">
              <div class="w-24 h-24 rounded-full overflow-hidden bg-amber-50 border-4 border-transparent group-hover:border-amber-400 transition-all duration-200 shadow-md">
                <%= if cat.image_url do %>
                  <img
                    src={cat.image_url}
                    alt={cat.name}
                    class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-300"
                  />
                <% else %>
                  <div class="w-full h-full flex items-center justify-center bg-amber-100">
                    <span class="text-2xl font-black text-amber-400">{String.first(cat.name)}</span>
                  </div>
                <% end %>
              </div>
              <span class="text-sm font-semibold text-zinc-800 group-hover:text-amber-600 transition text-center">
                {cat.name}
              </span>
            </a>
          <% end %>
        </div>
      <% end %>
    </section>
    """
  end

  # ---------------------------------------------------------------------------
  # Best Sellers
  # ---------------------------------------------------------------------------

  @doc """
  Four-column "Our Best Sellers" product grid.
  """
  def best_sellers(assigns) do
    ~H"""
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

      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <.product_card
          badge="BEST SELLER"
          badge_color="bg-emerald-500"
          category="Irish Whiskey"
          name="Jameson Irish Whiskey"
          reviews={6}
          price="$24.99"
          size="700ML"
          abv="40%"
          in_stock={true}
          has_options={false}
          variant_id={28}
          image_url="https://images.unsplash.com/photo-1527281400683-1aae777175f8?w=400&auto=format&fit=crop"
        />
        <.product_card
          badge="BEST SELLER"
          badge_color="bg-emerald-500"
          category="Bourbon"
          name="Jack Daniel's Old No. 7"
          reviews={6}
          price="$22.99"
          size="700ML"
          abv="40%"
          in_stock={true}
          has_options={false}
          variant_id={31}
          image_url="https://images.unsplash.com/photo-1547595628-c61a29f496f0?w=400&auto=format&fit=crop"
        />
        <.product_card
          badge="BEST SELLER"
          badge_color="bg-emerald-500"
          category="Scotch Whisky"
          name="Johnnie Walker Black Label"
          reviews={6}
          price="$29.99"
          size="700ML"
          abv="40%"
          in_stock={true}
          has_options={false}
          variant_id={34}
          image_url="https://images.unsplash.com/photo-1569529465841-dfecdab7503b?w=400&auto=format&fit=crop"
        />
        <.product_card
          badge="BEST SELLER"
          badge_color="bg-emerald-500"
          category="Cognac"
          name="Hennessy VS Cognac"
          reviews={6}
          price="$35.99"
          size="700ML"
          abv="40%"
          in_stock={true}
          has_options={false}
          variant_id={36}
          image_url="https://images.unsplash.com/photo-1598373182133-52452f7691ef?w=400&auto=format&fit=crop"
        />
      </div>
    </section>
    """
  end

  # ---------------------------------------------------------------------------
  # Products of the Month
  # ---------------------------------------------------------------------------

  @doc """
  Three large dark-overlay image feature cards for "Products of the Month".
  """
  def products_of_month(assigns) do
    assigns = assign_new(assigns, :featured_products, fn -> [] end)

    ~H"""
    <section class="max-w-screen-xl mx-auto px-4 py-10 border-t border-zinc-100">
      <h2 class="text-xl sm:text-2xl font-black uppercase tracking-tight text-zinc-900 mb-6 font-display">
        Products <span class="font-light">of the Month</span>
      </h2>

      <%= if @featured_products == [] do %>
        <p class="text-sm text-zinc-400 text-center py-8">
          No featured products yet — mark products as featured in the admin.
        </p>
      <% else %>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <%= for product <- Enum.take(@featured_products, 3) do %>
            <% default_variant =
              Enum.find(product.variants, & &1.is_default) || List.first(product.variants) %>
            <div class="relative rounded-lg overflow-hidden h-72 group">
              <img
                src={
                  product.image_url ||
                    "https://images.unsplash.com/photo-1527281400683-1aae777175f8?w=700&auto=format&fit=crop"
                }
                alt={product.name}
                class="absolute inset-0 w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
              />
              <div class="absolute inset-0 bg-gradient-to-t from-black/80 via-black/30 to-transparent">
              </div>
              <div class="absolute bottom-0 left-0 right-0 p-6 text-white">
                <p class="text-xs text-amber-300 uppercase tracking-widest mb-1">
                  {if product.brand, do: product.brand.name}
                </p>
                <h3 class="text-xl font-black uppercase leading-tight mb-1">{product.name}</h3>
                <%= if default_variant do %>
                  <p class="text-sm text-zinc-300 mb-4">
                    from
                    <span class="text-amber-400 font-bold">
                      KSh {format_money(default_variant.price)}
                    </span>
                  </p>
                <% end %>
                <a
                  href={"/shop/#{product.slug}"}
                  class="inline-block bg-white text-zinc-900 text-xs font-bold px-5 py-2 hover:bg-orange-500 hover:text-white transition"
                >
                  SHOP NOW
                </a>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </section>
    """
  end

  # ---------------------------------------------------------------------------
  # Newsletter Sign-Up
  # ---------------------------------------------------------------------------

  @doc """
  Split-panel newsletter section: product image on the left, sign-up form on the right.
  """
  def newsletter_signup(assigns) do
    ~H"""
    <section class="max-w-screen-xl mx-auto px-4 py-10 border-t border-zinc-100">
      <div class="grid grid-cols-1 md:grid-cols-2 rounded-lg overflow-hidden border border-zinc-200 shadow-sm">
        <!-- image side -->
        <div class="relative min-h-[320px] bg-rose-900">
          <img
            src="https://images.unsplash.com/photo-1569529465841-dfecdab7503b?w=800&auto=format&fit=crop"
            alt="Claim 10% off"
            class="absolute inset-0 w-full h-full object-cover"
          />
          <div class="absolute top-6 right-6 w-20 h-20 bg-orange-600 rounded-full flex flex-col items-center justify-center text-white text-center shadow-lg">
            <span class="text-[9px] font-bold uppercase leading-tight">Authentic</span>
            <span class="text-lg font-black">100%</span>
            <span class="text-[9px] font-bold uppercase leading-tight">Guaranteed</span>
          </div>
        </div>
        
    <!-- form side -->
        <div class="bg-white p-10 flex flex-col justify-center">
          <p class="text-xs font-semibold uppercase tracking-widest text-zinc-400 mb-2">
            Newsletter Sign Up
          </p>
          <h2 class="text-2xl sm:text-3xl font-black text-zinc-900 mb-3 leading-tight font-display">
            Claim <span class="text-orange-500">10% Off</span> Your First Order
          </h2>
          <p class="text-sm text-zinc-500 mb-6">
            Get 10% off your first purchase when you sign up today. You'll also get access to exclusive sales and deals only available to our subscribers.
          </p>
          <form class="flex gap-0 mb-8">
            <input
              type="email"
              placeholder="Your Email Address..."
              class="flex-1 border-b border-zinc-300 focus:border-orange-500 outline-none py-2 text-sm text-zinc-700 placeholder-zinc-400"
            />
          </form>
          <button class="w-full bg-orange-500 hover:bg-orange-600 transition text-white font-bold py-3 tracking-widest uppercase text-sm mb-8">
            Subscribe
          </button>
          <div class="grid grid-cols-2 gap-6 pt-4 border-t border-zinc-100">
            <div class="flex items-start gap-3">
              <svg
                class="w-6 h-6 text-amber-500 flex-shrink-0 mt-0.5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                stroke-width="1.8"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              <div>
                <p class="text-sm font-bold text-zinc-900">Great Daily Deal</p>
                <p class="text-xs text-zinc-500">We have over 10,000 Reviews on Trustpilot.</p>
              </div>
            </div>
            <div class="flex items-start gap-3">
              <svg
                class="w-6 h-6 text-amber-500 flex-shrink-0 mt-0.5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                stroke-width="1.8"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                />
              </svg>
              <div>
                <p class="text-sm font-bold text-zinc-900">Next Day Delivery</p>
                <p class="text-xs text-zinc-500">
                  Order by 2PM Mon – Thur for Next Working Day Delivery
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
    """
  end

  # ---------------------------------------------------------------------------
  # Find Our Store
  # ---------------------------------------------------------------------------

  @doc """
  Store location section with address, hours and an embedded map placeholder.
  """
  def find_our_store(assigns) do
    ~H"""
    <section class="max-w-screen-xl mx-auto px-4 py-10 border-t border-zinc-100">
      <div class="grid grid-cols-1 md:grid-cols-2 rounded-lg overflow-hidden border border-zinc-200 shadow-sm">
        <!-- info panel -->
        <div class="bg-white px-10 py-10 flex flex-col justify-between">
          <div>
            <h2 class="text-xl sm:text-2xl font-black uppercase tracking-tight text-zinc-900 mb-6 font-display">
              <span class="font-black">Find</span> <span class="font-light">Our Store</span>
            </h2>
            <div class="mb-5">
              <p class="text-[10px] font-bold uppercase tracking-widest text-zinc-400 mb-1">
                Address
              </p>
              <p class="text-sm text-zinc-700 leading-relaxed">
                {Liquor.StoreConfig.hq_address()}
              </p>
            </div>
            <div class="mb-8">
              <p class="text-[10px] font-bold uppercase tracking-widest text-zinc-400 mb-3">
                Opening Hours
              </p>
              <div class="text-sm text-zinc-700 space-y-2">
                <div class="flex justify-between gap-4">
                  <span>{Liquor.StoreConfig.hours_weekday()}</span>
                </div>
                <div class="flex justify-between gap-4">
                  <span>{Liquor.StoreConfig.hours_saturday()}</span>
                </div>
                <div class="flex justify-between gap-4">
                  <span>{Liquor.StoreConfig.hours_sunday()}</span>
                </div>
              </div>
            </div>
          </div>
          <a
            href="https://maps.google.com"
            target="_blank"
            class="block text-center border border-amber-500 text-amber-600 font-bold text-sm py-3 hover:bg-amber-500 hover:text-white transition uppercase tracking-widest"
          >
            Get Direction
          </a>
        </div>
        
    <!-- map -->
        <div class="relative min-h-[360px]">
          <iframe
            src={"https://maps.google.com/maps?q=#{Liquor.StoreConfig.map_query()}&t=&z=11&ie=UTF8&iwloc=&output=embed"}
            class="absolute inset-0 w-full h-full border-0"
            loading="lazy"
            referrerpolicy="no-referrer-when-downgrade"
            title="Store location map"
          >
          </iframe>
        </div>
      </div>
    </section>
    """
  end

  # ---------------------------------------------------------------------------
  # Site Footer
  # ---------------------------------------------------------------------------

  @doc """
  Multi-column footer with link columns, a support contact, and a bottom bar.
  """
  def site_footer(assigns) do
    ~H"""
    <footer class="bg-white border-t border-zinc-200 mt-10">
      <div class="max-w-screen-xl mx-auto px-4 py-12 grid grid-cols-2 md:grid-cols-5 gap-8">
        <!-- Customer -->
        <div>
          <h4 class="text-[10px] font-black uppercase tracking-[0.2em] text-zinc-400 mb-4">
            Customer
          </h4>
          <ul class="space-y-2 text-sm text-zinc-700">
            <%= for link <- ["Help Center", "My Account", "Track My Order", "Return Policy", "Gift Cards"] do %>
              <li><a href="#" class="hover:text-amber-600 transition">{link}</a></li>
            <% end %>
          </ul>
        </div>
        
    <!-- About Us -->
        <div>
          <h4 class="text-[10px] font-black uppercase tracking-[0.2em] text-zinc-400 mb-4">
            About Us
          </h4>
          <ul class="space-y-2 text-sm text-zinc-700">
            <%= for link <- ["Company Info", "Press Releases", "Careers", "Reviews", "Investor Relations"] do %>
              <li><a href="#" class="hover:text-amber-600 transition">{link}</a></li>
            <% end %>
          </ul>
        </div>
        
    <!-- Quick Links -->
        <div>
          <h4 class="text-[10px] font-black uppercase tracking-[0.2em] text-zinc-400 mb-4">
            Quick Links
          </h4>
          <ul class="space-y-2 text-sm text-zinc-700">
            <%= for link <- ["Search", "Become a Reseller", "About Us", "Contact Us", "Terms of Service"] do %>
              <li><a href="#" class="hover:text-amber-600 transition">{link}</a></li>
            <% end %>
          </ul>
        </div>
        
    <!-- My Account -->
        <div>
          <h4 class="text-[10px] font-black uppercase tracking-[0.2em] text-zinc-400 mb-4">
            My Account
          </h4>
          <ul class="space-y-2 text-sm text-zinc-700">
            <%= for link <- ["Store Location", "Order History", "Wish List", "Newsletter", "Specials"] do %>
              <li><a href="#" class="hover:text-amber-600 transition">{link}</a></li>
            <% end %>
          </ul>
        </div>
        
    <!-- Contact / Support -->
        <div>
          <h4 class="text-[10px] font-black uppercase tracking-[0.2em] text-zinc-400 mb-4">
            Questions? We are here for you
          </h4>
          <div class="flex items-center gap-3 mb-4">
            <img
              src="https://randomuser.me/api/portraits/women/44.jpg"
              alt="Jane Cooper"
              class="w-10 h-10 rounded-full object-cover"
            />
            <div>
              <p class="text-sm font-bold text-zinc-900">Jane Cooper</p>
              <p class="text-[10px] uppercase tracking-widest text-zinc-400">
                Service Desk ·
                <a href="#" class="text-amber-500 hover:underline font-medium">Chat Now</a>
              </p>
            </div>
          </div>
          <div class="space-y-2 text-sm text-zinc-700">
            <div class="flex items-center gap-2">
              <svg
                class="w-4 h-4 text-amber-500"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                stroke-width="2"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M3 5a2 2 0 012-2h2.28a1 1 0 01.948.684l1.2 3.6a1 1 0 01-.27 1.047L7.6 9.9A16.016 16.016 0 0014.1 16.4l1.57-1.558a1 1 0 011.047-.27l3.6 1.2A1 1 0 0121 16.72V19a2 2 0 01-2 2h-1C9.163 21 3 14.837 3 7V5z"
                />
              </svg>
              <span>(084) 123 - 456 88</span>
            </div>
            <div class="flex items-center gap-2">
              <svg
                class="w-4 h-4 text-amber-500"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                stroke-width="2"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                />
              </svg>
              <span>contact@example.com</span>
            </div>
          </div>
        </div>
      </div>
      
    <!-- bottom bar -->
      <div class="border-t border-zinc-100 bg-zinc-50">
        <div class="max-w-screen-xl mx-auto px-4 py-4 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div class="flex items-center gap-3">
            <select class="text-xs border border-zinc-200 rounded px-2 py-1 bg-white text-zinc-600 focus:outline-none">
              <option>🇰🇪 Kenya Shilling (KES KSh)</option>
              <option>🇺🇸 USA Dollar (USD $)</option>
            </select>
            <select class="text-xs border border-zinc-200 rounded px-2 py-1 bg-white text-zinc-600 focus:outline-none">
              <option>English</option>
              <option>Swahili</option>
            </select>
          </div>

          <p class="text-xs text-zinc-500">
            Copyright © 2024 <a href="/" class="text-amber-500 font-semibold hover:underline"><%= Liquor.StoreConfig.short_name() %></a>. All rights reserved
          </p>

          <div class="flex items-center gap-2">
            <span class="text-[10px] text-zinc-400 hidden sm:inline">
              Guarantee Safe &amp; Secure Checkout
            </span>
          </div>
        </div>
      </div>
    </footer>
    """
  end

  # ---------------------------------------------------------------------------
  # Private: Product Card
  # ---------------------------------------------------------------------------

  defp product_card(assigns) do
    assigns = assign_new(assigns, :badge_color, fn -> "bg-orange-500" end)
    assigns = assign_new(assigns, :badge, fn -> nil end)
    assigns = assign_new(assigns, :image_url, fn -> nil end)
    assigns = assign_new(assigns, :variant_id, fn -> nil end)

    ~H"""
    <div class="border border-zinc-200 rounded-lg p-4 flex flex-col group hover:shadow-md transition-shadow relative">
      <!-- badge -->
      <%= if @badge do %>
        <span class={[
          "absolute top-3 left-3 z-10 text-[9px] font-black uppercase tracking-wide text-white px-2 py-0.5 rounded",
          @badge_color
        ]}>
          {@badge}
        </span>
      <% end %>
      
    <!-- quick-action icons -->
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
              d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
            />
          </svg>
        </button>
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
              d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4"
            />
          </svg>
        </button>
      </div>
      
    <!-- product image -->
      <div class="flex items-center justify-center h-40 mb-3 overflow-hidden rounded-md bg-zinc-50">
        <%= if @image_url do %>
          <img
            src={@image_url}
            alt={@name}
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
                d="M9 3v1m6-1v1M9 19v1m6-1v1M5 9H4m1 6H4m16-6h-1m1 6h-1M7 4h10l1 4v8a2 2 0 01-2 2H8a2 2 0 01-2-2V8l1-4z"
              />
            </svg>
          </div>
        <% end %>
      </div>
      
    <!-- meta -->
      <p class="text-[10px] text-zinc-400 uppercase tracking-widest mb-1">{@category}</p>
      <p class="text-sm font-semibold text-zinc-800 leading-snug mb-2 line-clamp-2">{@name}</p>
      
    <!-- stars -->
      <div class="flex items-center gap-1 mb-2">
        <%= for _i <- 1..5 do %>
          <svg class="w-3 h-3 text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
            <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
          </svg>
        <% end %>
        <span class="text-[10px] text-zinc-400 ml-1">{@reviews} Reviews</span>
      </div>
      
    <!-- price -->
      <p class="text-base font-bold text-zinc-900 mb-3">{@price}</p>
      
    <!-- tags row -->
      <div class="flex items-center gap-2 mb-4">
        <span class="text-[10px] bg-zinc-100 text-zinc-600 px-2 py-0.5 rounded font-medium">
          {@size}
        </span>
        <span class="text-[10px] bg-zinc-100 text-zinc-600 px-2 py-0.5 rounded font-medium">
          {@abv}
        </span>
        <%= if @in_stock do %>
          <span class="text-[10px] bg-emerald-100 text-emerald-700 px-2 py-0.5 rounded font-semibold ml-auto">
            IN STOCK
          </span>
        <% else %>
          <span class="text-[10px] bg-red-100 text-red-600 px-2 py-0.5 rounded font-semibold ml-auto">
            OUT OF STOCK
          </span>
        <% end %>
      </div>
      
    <!-- CTA -->
      <%= if @has_options do %>
        <button class="w-full py-2.5 text-xs font-bold uppercase tracking-widest transition border border-zinc-800 text-zinc-900 hover:bg-zinc-900 hover:text-white">
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
            "w-full py-2.5 text-xs font-bold uppercase tracking-widest transition border",
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
    """
  end
end

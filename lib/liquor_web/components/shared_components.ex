defmodule LiquorWeb.SharedComponents do
  @moduledoc """
  Site-wide layout components shared across every page via app.html.heex.

  Components:
    - site_promo_bar/1   – amber top strip with 3 trust messages
    - site_navbar/1      – compact header: logo, nav links, search, locale, icons
    - feature_strip/1    – 4-column trust badges above the footer
    - site_footer/1      – multi-column footer + bottom bar
    - scroll_to_top/1    – floating amber scroll-to-top button
  """

  use Phoenix.Component

  # ---------------------------------------------------------------------------
  # Site Promo Bar
  # ---------------------------------------------------------------------------

  @doc """
  Amber top announcement strip shared by all pages.
  """
  def site_promo_bar(assigns) do
    ~H"""
    <div class="bg-amber-50 border-b border-amber-200 text-zinc-700 text-xs font-medium py-2">
      <div class="max-w-screen-xl mx-auto px-4 flex flex-col sm:flex-row items-center justify-between gap-2 text-center">
        <div class="flex items-center gap-2">
          <svg class="w-4 h-4 text-amber-500 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <span class="uppercase tracking-wide font-semibold">Nairobi's Premier Liquor Store · TRM, Thika Road</span>
        </div>
        <div class="hidden sm:block h-4 w-px bg-amber-300"></div>
        <div class="flex items-center gap-2">
          <svg class="w-4 h-4 text-amber-500 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4" />
          </svg>
          <span class="uppercase tracking-wide font-semibold">Free Nairobi Delivery on Orders Over KSh 10,000</span>
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
          <span class="uppercase tracking-wide font-semibold">Nairobi's Most Trusted Spirits &amp; Wine Selection</span>
        </div>
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Site Navbar
  # ---------------------------------------------------------------------------

  @doc """
  Compact sticky site-wide navbar used on all pages.
  Pass `current_page` as one of: "home" | "shop" | "blogs" | "pages" | "contact"
  to highlight the active link.
  """
  attr :current_page, :string, default: ""

  def site_navbar(assigns) do
    ~H"""
    <header class="bg-white border-b border-zinc-200 sticky top-0 z-50 shadow-sm">
      <div class="max-w-screen-xl mx-auto px-4 sm:px-6 h-14 flex items-center gap-3">

        <!-- Logo -->
        <a href="/" class="flex-shrink-0 mr-2">
          <img src="/images/logo.png" alt="The Mint Liquor Store" class="h-9 w-auto object-contain" />
        </a>

        <!-- Desktop Nav -->
        <nav class="hidden md:flex items-center gap-0.5 text-xs font-bold text-zinc-700 flex-1">
          <%= for {label, path, key} <- [
            {"HOME",    "/",        "home"},
            {"SHOP",    "/shop",    "shop"},
            {"ABOUT",   "/about",   "about"},
            {"CONTACT", "/contact", "contact"}
          ] do %>
            <a
              href={path}
              class={[
                "px-3 py-5 transition tracking-widest border-b-2",
                if(@current_page == key,
                  do:   "text-amber-600 border-amber-500",
                  else: "border-transparent hover:text-amber-600 hover:border-amber-400"
                )
              ]}
            >
              <%= label %>
            </a>
          <% end %>
        </nav>

        <!-- Desktop Search -->
        <div class="hidden lg:flex items-center border-b border-zinc-300 focus-within:border-amber-500 transition gap-2 pr-2">
          <input
            type="text"
            placeholder="Search products..."
            class="font-sans text-sm text-zinc-600 py-1.5 w-44 focus:outline-none placeholder-zinc-400"
          />
          <button class="text-zinc-400 hover:text-amber-500 transition">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </button>
        </div>

        <!-- Desktop Locale -->
        <div class="hidden lg:flex items-center gap-2 text-xs font-semibold text-zinc-600 border-l border-zinc-200 pl-3 font-sans">
          <span>🇺🇸 USD</span>
          <svg class="w-3 h-3 text-zinc-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
          </svg>
        </div>

        <!-- Action icons + hamburger -->
        <div class="flex items-center gap-0.5 ml-auto">
          <button class="hidden sm:flex p-2 rounded-full hover:bg-zinc-100 transition">
            <svg class="w-5 h-5 text-zinc-700" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
              <path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
            </svg>
          </button>
          <button class="p-2 rounded-full hover:bg-zinc-100 transition relative">
            <svg class="w-5 h-5 text-zinc-700" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
              <path stroke-linecap="round" stroke-linejoin="round" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
            </svg>
            <span class="absolute top-0.5 right-0.5 w-3.5 h-3.5 bg-zinc-800 rounded-full text-[8px] font-bold text-white flex items-center justify-center">0</span>
          </button>
          <a
            href="/cart"
            data-cart-icon
            class="p-2 rounded-full hover:bg-zinc-100 transition relative"
            aria-label="Shopping cart"
            data-cart-badge-wrapper
          >
            <svg class="w-5 h-5 text-zinc-700" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
              <path stroke-linecap="round" stroke-linejoin="round" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-1.5 6h13" />
            </svg>
            <span
              data-cart-count
              class="absolute -top-0.5 -right-0.5 min-w-[18px] h-[18px] bg-orange-500 rounded-full text-[9px] font-bold text-white flex items-center justify-center px-1 opacity-0 transition-opacity"
            >0</span>
          </a>
          <!-- Hamburger (mobile only) -->
          <button
            id="mobile-nav-toggle"
            onclick="
              const menu = document.getElementById('mobile-nav');
              const open  = menu.classList.toggle('hidden');
              this.setAttribute('aria-expanded', String(!open));
            "
            aria-expanded="false"
            aria-controls="mobile-nav"
            class="md:hidden p-2 rounded-full hover:bg-zinc-100 transition ml-1"
            aria-label="Toggle navigation"
          >
            <svg class="w-5 h-5 text-zinc-700" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </button>
        </div>
      </div>

      <!-- Mobile dropdown menu -->
      <div id="mobile-nav" class="hidden md:hidden border-t border-zinc-100 bg-white">
        <nav class="max-w-screen-xl mx-auto px-4 py-3 flex flex-col divide-y divide-zinc-100">
          <%= for {label, path, key} <- [
            {"Home",    "/",        "home"},
            {"Shop",    "/shop",    "shop"},
            {"About",   "/about",   "about"},
            {"Contact", "/contact", "contact"}
          ] do %>
            <a
              href={path}
              class={[
                "py-3 text-sm font-semibold tracking-wide transition font-sans",
                if(@current_page == key,
                  do:   "text-amber-600",
                  else: "text-zinc-700 hover:text-amber-600"
                )
              ]}
            >
              <%= label %>
            </a>
          <% end %>
          <!-- Mobile search -->
          <div class="py-3">
            <div class="flex items-center border border-zinc-200 rounded-lg px-3 gap-2">
              <svg class="w-4 h-4 text-zinc-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
              <input
                type="text"
                placeholder="Search products..."
                class="flex-1 text-sm py-2.5 focus:outline-none placeholder-zinc-400 font-sans"
              />
            </div>
          </div>
        </nav>
      </div>
    </header>
    """
  end

  # ---------------------------------------------------------------------------
  # Feature Strip
  # ---------------------------------------------------------------------------

  @doc """
  Four-column trust badge strip above the footer.
  """
  def feature_strip(assigns) do
    ~H"""
    <section class="bg-stone-50 py-5 border-y border-zinc-200">
      <div class="max-w-screen-xl mx-auto px-4 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
        <%= for {icon, title, subtitle} <- [
          {:truck,   "Free Nairobi Delivery",      "On all orders over KSh 10,000"},
          {:bottle,  "Authenticity Guarantee",    "Shop for items with confidence"},
          {:card,    "Secure Payments",           "Secure payment methods"},
          {:headset, "Top Rated Customer Service","Quick responses and solutions"}
        ] do %>
          <div class="bg-white border border-zinc-200 rounded-lg flex items-center gap-4 px-5 py-4">
            <!-- Icon box -->
            <div class="w-12 h-12 border border-zinc-200 rounded-lg flex items-center justify-center shrink-0">
              <%= case icon do %>
                <% :truck -> %>
                  <svg class="w-7 h-7 text-zinc-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.4">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9 17a2 2 0 11-4 0 2 2 0 014 0zm10 0a2 2 0 11-4 0 2 2 0 014 0z" />
                    <path stroke-linecap="round" stroke-linejoin="round" d="M13 16V6a1 1 0 00-1-1H4a1 1 0 00-1 1v10m10 0H4m9 0h1m1-10h2.586a1 1 0 01.707.293l3.414 3.414A1 1 0 0122 10.414V14a2 2 0 01-2 2h-1" />
                  </svg>
                <% :bottle -> %>
                  <svg class="w-7 h-7 text-zinc-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.4">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9 3h6m-6 0v2.172a2 2 0 00.586 1.414L11 8.17V19a2 2 0 002 2 2 2 0 002-2V8.172l1.414-1.586A2 2 0 0017 5.172V3m-8 0H7a1 1 0 000 2h10a1 1 0 000-2h-2" />
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9 14h6" />
                  </svg>
                <% :card -> %>
                  <svg class="w-7 h-7 text-zinc-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.4">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
                  </svg>
                <% :headset -> %>
                  <svg class="w-7 h-7 text-zinc-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.4">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M18.364 5.636l-3.536 3.536m0 5.656l3.536 3.536M9.172 9.172L5.636 5.636m3.536 9.192l-3.536 3.536M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-5 0a4 4 0 11-8 0 4 4 0 018 0z" />
                  </svg>
              <% end %>
            </div>
            <!-- Text -->
            <div>
              <p class="font-bold text-sm text-zinc-900 leading-tight"><%= title %></p>
              <p class="text-xs text-zinc-500 mt-0.5 leading-tight"><%= subtitle %></p>
            </div>
          </div>
        <% end %>
      </div>
    </section>
    """
  end

  # ---------------------------------------------------------------------------
  # Site Footer
  # ---------------------------------------------------------------------------

  @doc """
  Multi-column footer with link groups, support contact, and a bottom bar.
  """
  def site_footer(assigns) do
    ~H"""
    <footer class="bg-white border-t border-zinc-200">
      <!-- Main columns -->
      <div class="max-w-screen-xl mx-auto px-6 py-12">
        <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-8">

          <!-- Customer -->
          <div>
            <h4 class="text-xs font-black uppercase tracking-[0.18em] text-zinc-400 mb-4">Customer</h4>
            <ul class="space-y-2.5">
              <%= for {label, href} <- [
                {"Help Center",      "#"},
                {"My Account",       "#"},
                {"Track My Order",   "#"},
                {"Return Policy",    "#"},
                {"Gift Cards",       "#"}
              ] do %>
                <li>
                  <a href={href} class="text-sm text-zinc-700 hover:text-amber-600 transition leading-tight">
                    <%= label %>
                  </a>
                </li>
              <% end %>
            </ul>
          </div>

          <!-- About Us -->
          <div>
            <h4 class="text-xs font-black uppercase tracking-[0.18em] text-zinc-400 mb-4">About Us</h4>
            <ul class="space-y-2.5">
              <%= for {label, href} <- [
                {"Company Info",        "#"},
                {"Press Releases",      "#"},
                {"Careers",             "#"},
                {"Reviews",             "#"},
                {"Investor Relations",  "#"}
              ] do %>
                <li>
                  <a href={href} class="text-sm text-zinc-700 hover:text-amber-600 transition leading-tight">
                    <%= label %>
                  </a>
                </li>
              <% end %>
            </ul>
          </div>

          <!-- Quick Links -->
          <div>
            <h4 class="text-xs font-black uppercase tracking-[0.18em] text-zinc-400 mb-4">Quick Links</h4>
            <ul class="space-y-2.5">
              <%= for {label, href} <- [
                {"Search",              "#"},
                {"Become a Reseller",   "#"},
                {"About Us",            "/about"},
                {"Contact Us",          "/contact"},
                {"Terms of Service",    "#"}
              ] do %>
                <li>
                  <a href={href} class="text-sm text-zinc-700 hover:text-amber-600 transition leading-tight">
                    <%= label %>
                  </a>
                </li>
              <% end %>
            </ul>
          </div>

          <!-- My Account -->
          <div>
            <h4 class="text-xs font-black uppercase tracking-[0.18em] text-zinc-400 mb-4">My Account</h4>
            <ul class="space-y-2.5">
              <%= for {label, href} <- [
                {"Store Location",  "#"},
                {"Order History",   "#"},
                {"Wish List",       "#"},
                {"Newsletter",      "#"},
                {"Specials",        "#"}
              ] do %>
                <li>
                  <a href={href} class="text-sm text-zinc-700 hover:text-amber-600 transition leading-tight">
                    <%= label %>
                  </a>
                </li>
              <% end %>
            </ul>
          </div>

          <!-- Support -->
          <div class="col-span-2 md:col-span-1">
            <h3 class="text-base font-black text-zinc-900 leading-snug mb-4">
              Questions? We are here for you
            </h3>
            <ul class="space-y-2">
              <li class="flex items-center gap-2.5 text-sm text-zinc-700">
                <svg class="w-4 h-4 text-amber-500 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M3 5a2 2 0 012-2h2.28a1 1 0 01.948.684l1.2 3.6a1 1 0 01-.27 1.047L7.6 9.9A16.016 16.016 0 0014.1 16.4l1.57-1.558a1 1 0 011.047-.27l3.6 1.2A1 1 0 0121 16.72V19a2 2 0 01-2 2h-1C9.163 21 3 14.837 3 7V5z" />
                </svg>
                <%= Liquor.StoreConfig.phone() %>
              </li>
              <li class="flex items-center gap-2.5 text-sm text-zinc-700">
                <svg class="w-4 h-4 text-amber-500 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                </svg>
                <%= Liquor.StoreConfig.email() %>
              </li>
              <li class="flex items-start gap-2.5 text-sm text-zinc-500 mt-1">
                <svg class="w-4 h-4 text-amber-500 shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/>
                  <path stroke-linecap="round" stroke-linejoin="round" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/>
                </svg>
                <%= Liquor.StoreConfig.store_address() %>
              </li>
            </ul>
          </div>

        </div>
      </div>

      <!-- Bottom bar -->
      <div class="border-t border-zinc-100">
        <div class="max-w-screen-xl mx-auto px-6 py-4 flex flex-col sm:flex-row items-center justify-between gap-4">

          <!-- Currency + Language -->
          <div class="flex items-center gap-2">
            <div class="relative">
              <select class="appearance-none text-xs border border-zinc-200 rounded-md pl-3 pr-7 py-1.5 bg-white text-zinc-600 focus:outline-none focus:ring-1 focus:ring-amber-400 cursor-pointer">
                <option>🇰🇪 Kenya Shilling (KES KSh)</option>
                <option>🇺🇸 USA Dollar (USD $)</option>
              </select>
              <svg class="pointer-events-none absolute right-2 top-1/2 -translate-y-1/2 w-3 h-3 text-zinc-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
              </svg>
            </div>
            <div class="relative">
              <select class="appearance-none text-xs border border-zinc-200 rounded-md pl-3 pr-7 py-1.5 bg-white text-zinc-600 focus:outline-none focus:ring-1 focus:ring-amber-400 cursor-pointer">
                <option>English</option>
                <option>Swahili</option>
              </select>
              <svg class="pointer-events-none absolute right-2 top-1/2 -translate-y-1/2 w-3 h-3 text-zinc-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
              </svg>
            </div>
          </div>

          <!-- Copyright -->
          <p class="text-xs text-zinc-500 order-last sm:order-none">
            Copyright &copy; <%= Date.utc_today().year %>
            <a href="/" class="text-amber-500 font-semibold hover:underline"><%= Liquor.StoreConfig.short_name() %></a>.
            All rights reserved
          </p>

          <!-- Payment logos -->
          <div class="flex items-center gap-2">
            <span class="text-[10px] text-zinc-400 hidden md:inline mr-1">Guarantee Safe &amp; Secure</span>
            <!-- Mastercard -->
            <div class="h-7 w-11 bg-white border border-zinc-200 rounded flex items-center justify-center shadow-sm overflow-hidden px-1">
              <div class="flex items-center">
                <div class="w-4 h-4 bg-red-500 rounded-full -mr-1.5"></div>
                <div class="w-4 h-4 bg-amber-400 rounded-full opacity-90"></div>
              </div>
            </div>
            <!-- PayPal -->
            <div class="h-7 w-11 bg-white border border-zinc-200 rounded flex items-center justify-center shadow-sm px-1">
              <span class="text-[9px] font-black text-blue-700 tracking-tight">Pay<span class="text-blue-400">Pal</span></span>
            </div>
            <!-- Visa -->
            <div class="h-7 w-11 bg-white border border-zinc-200 rounded flex items-center justify-center shadow-sm px-1">
              <span class="text-[11px] font-black italic text-blue-800 tracking-tight">VISA</span>
            </div>
            <!-- Maestro -->
            <div class="h-7 w-11 bg-white border border-zinc-200 rounded flex items-center justify-center shadow-sm overflow-hidden px-1">
              <div class="flex items-center">
                <div class="w-4 h-4 bg-red-600 rounded-full -mr-1.5 opacity-90"></div>
                <div class="w-4 h-4 bg-blue-600 rounded-full opacity-80"></div>
              </div>
            </div>
            <!-- Skrill -->
            <div class="h-7 w-11 bg-white border border-zinc-200 rounded flex items-center justify-center shadow-sm px-1">
              <span class="text-[10px] font-black text-purple-600 tracking-tight">Skrill</span>
            </div>
            <!-- Google Pay -->
            <div class="h-7 w-11 bg-white border border-zinc-200 rounded flex items-center justify-center shadow-sm px-1">
              <span class="text-[9px] font-black tracking-tight">
                <span class="text-blue-600">G</span><span class="text-zinc-600">Pay</span>
              </span>
            </div>
          </div>

        </div>
      </div>
    </footer>
    """
  end

  # ---------------------------------------------------------------------------
  # Scroll-to-top button
  # ---------------------------------------------------------------------------

  @doc """
  Fixed amber circle button that scrolls the page back to the top.
  """
  def scroll_to_top(assigns) do
    ~H"""
    <button
      onclick="window.scrollTo({top: 0, behavior: 'smooth'})"
      class="fixed bottom-6 right-6 z-50 w-11 h-11 bg-orange-500 hover:bg-orange-600 text-white rounded-full shadow-lg flex items-center justify-center transition"
      aria-label="Scroll to top"
    >
      <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
        <path stroke-linecap="round" stroke-linejoin="round" d="M5 15l7-7 7 7" />
      </svg>
    </button>
    """
  end
end

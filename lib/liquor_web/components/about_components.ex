defmodule LiquorWeb.AboutComponents do
  @moduledoc """
  About page UI components for the Liquor store.

  Sections:
    - about_hero/1        – split hero: store image left, headline + USP list right
    - stats_row/1         – 4 large outlined stat numbers with labels
    - mission_values/1    – centred heading with two-column mission + values text
    - team_section/1      – 4-column expert cards with photo, name, role, social icons
    - subscribe_banner/1  – amber scrolling "Subscribe & get 10% off" marquee bar
  """

  use Phoenix.Component

  # ---------------------------------------------------------------------------
  # About Hero
  # ---------------------------------------------------------------------------

  @doc """
  Split hero section: tall store photograph on the left, marketing copy on
  the right with a headline, short description, "Contact Us" CTA, and a
  two-column checklist of USPs.
  """
  def about_hero(assigns) do
    ~H"""
    <section class="max-w-screen-xl mx-auto grid grid-cols-1 lg:grid-cols-2 min-h-[520px]">
      <!-- Left: store image -->
      <div class="relative overflow-hidden bg-zinc-900 min-h-[360px] lg:min-h-full">
        <img
          src="https://images.unsplash.com/photo-1566417713940-fe7c737a9ef2?w=900&auto=format&fit=crop"
          alt="The Mint Liquor Store, Nairobi"
          class="absolute inset-0 w-full h-full object-cover"
        />
      </div>

      <!-- Right: copy -->
      <div class="bg-amber-50 flex flex-col justify-center px-10 py-14 lg:px-16">
        <h1 class="text-3xl md:text-4xl font-black text-zinc-900 leading-tight mb-5">
          Nairobi's Home for<br />Premium Spirits &amp; Wine
        </h1>
        <p class="text-sm text-zinc-600 leading-relaxed mb-8 max-w-md">
          We bring the world's finest spirits, wines, and craft beers straight to your door.
          Whether you're stocking a home bar or searching for the perfect gift, our curated
          selection and knowledgeable team are here to help.
        </p>
        <div class="mb-10">
          <a
            href="/contact"
            class="inline-block border border-amber-500 bg-amber-50 hover:bg-amber-500 hover:text-white text-amber-700 font-bold text-sm px-7 py-3 transition uppercase tracking-widest"
          >
            Contact Us
          </a>
        </div>

        <!-- USP checklist -->
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-3 border-t border-amber-200 pt-8">
          <%= for item <- [
            "Nairobi's premier spirits & wine retailer",
            "Earn loyalty points on every order",
            "Huge selection of imported & local brands",
            "Hassle-free walk-in & online shopping",
            "Knowledgeable staff to guide your choices",
            "Same-day delivery within Nairobi"
          ] do %>
            <div class="flex items-start gap-2 text-sm text-zinc-700">
              <svg class="w-4 h-4 text-amber-500 flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
              </svg>
              <%= item %>
            </div>
          <% end %>
        </div>
      </div>
    </section>
    """
  end

  # ---------------------------------------------------------------------------
  # Stats Row
  # ---------------------------------------------------------------------------

  @doc """
  Four large outlined/thin numbers with a label beneath each, separated by
  a subtle bottom divider line.
  """
  def stats_row(assigns) do
    assigns = assign_new(assigns, :stats, fn -> [] end)

    ~H"""
    <section class="max-w-screen-xl mx-auto px-4 py-16">
      <div class="grid grid-cols-2 md:grid-cols-4 gap-8">
        <%= for {value, suffix, label} <- @stats do %>
          <div class="flex flex-col items-start border-b-2 border-amber-200 pb-6">
            <p class="text-6xl md:text-7xl font-thin text-zinc-800 tracking-tighter leading-none mb-3" style="font-family: serif;">
              <%= value %><span class="text-3xl md:text-4xl text-amber-500 font-light"><%= suffix %></span>
            </p>
            <p class="text-sm font-semibold text-zinc-600"><%= label %></p>
          </div>
        <% end %>
      </div>
    </section>
    """
  end

  # ---------------------------------------------------------------------------
  # Mission & Values
  # ---------------------------------------------------------------------------

  @doc """
  Centred eyebrow label + headline, followed by two equal-width text columns:
  "Our Mission" and "Core Values", each with two paragraphs of body copy.
  """
  def mission_values(assigns) do
    ~H"""
    <section class="max-w-screen-xl mx-auto px-4 py-16 border-t border-zinc-100">
      <!-- Heading -->
      <div class="text-center mb-12">
        <p class="text-xs font-bold uppercase tracking-[0.3em] text-zinc-400 mb-4">
          Mission and Values
        </p>
        <h2 class="text-3xl md:text-4xl font-black text-zinc-900 leading-tight max-w-2xl mx-auto">
          Create unexpected delight as<br class="hidden sm:block" /> we help people explore
        </h2>
      </div>

      <!-- Two columns -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-12">
        <!-- Our Mission -->
        <div>
          <h3 class="text-lg font-black text-zinc-900 mb-5">Our Mission</h3>
          <div class="space-y-4 text-sm text-zinc-600 leading-relaxed">
            <p>
              Our mission is to connect people with exceptional drinks from around the world.
              We believe great occasions deserve great bottles, and we're committed to making
              premium spirits, wines, and beers accessible to everyone.
            </p>
            <p>
              From everyday favourites to rare collector's expressions, we hand-pick every product
              in our range for quality, provenance, and value — so you can shop with confidence.
            </p>
          </div>
        </div>

        <!-- Core Values -->
        <div>
          <h3 class="text-lg font-black text-zinc-900 mb-5">Core Values</h3>
          <div class="space-y-4 text-sm text-zinc-600 leading-relaxed">
            <p>
              <strong class="text-zinc-800">Quality first.</strong> Every product is verified for
              authenticity before it reaches our shelves. We work directly with distilleries,
              wineries, and trusted importers to guarantee provenance.
            </p>
            <p>
              <strong class="text-zinc-800">Customer obsession.</strong> Fast delivery, easy returns,
              and a team of experts ready to answer your questions — we measure success by how
              happy you are with every order.
            </p>
          </div>
        </div>
      </div>
    </section>
    """
  end

  # ---------------------------------------------------------------------------
  # Team Section
  # ---------------------------------------------------------------------------

  @doc """
  Four-column team grid with a photo, name, amber role label, and social icon
  links that appear on hover.
  """
  def team_section(assigns) do
    assigns = assign_new(assigns, :team_members, fn -> [] end)

    ~H"""
    <section class="max-w-screen-xl mx-auto px-4 py-16 border-t border-zinc-100">
      <!-- Heading -->
      <div class="text-center mb-10">
        <p class="text-xs font-bold uppercase tracking-[0.3em] text-zinc-400 mb-3">Our Team</p>
        <h2 class="text-3xl md:text-4xl font-black text-zinc-900">Our experts</h2>
      </div>

      <%= if @team_members == [] do %>
        <p class="text-sm text-zinc-400 text-center py-8">Team information coming soon.</p>
      <% else %>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          <%= for {name, role, img} <- @team_members do %>
            <.team_card name={name} role={role} img={img} />
          <% end %>
        </div>
      <% end %>
    </section>
    """
  end

  # ---------------------------------------------------------------------------
  # Subscribe Banner
  # ---------------------------------------------------------------------------

  @doc """
  Full-width amber scrolling marquee bar: "Subscribe today and get 10% off
  your first purchase", repeated with decorative asterisk separators.
  """
  def subscribe_banner(assigns) do
    ~H"""
    <div class="bg-orange-500 overflow-hidden py-5">
      <div class="flex animate-marquee whitespace-nowrap gap-16">
        <%= for _i <- 1..6 do %>
          <span class="inline-flex items-center gap-6 text-white">
            <svg class="w-5 h-5 flex-shrink-0 opacity-70" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 2l1.09 3.26L16.18 4l-1.64 2.91L18 8.18l-3.26 1.09L16 12l-2.91-1.64L12 13.82l-1.09-3.26L7.82 12l1.64-2.91L6 7.82l3.26-1.09L8 4l2.91 1.64L12 2z" />
            </svg>
            <span class="text-sm md:text-base font-medium tracking-wide">
              Subscribe Today and Get
              <strong class="font-black"> 10% Off Your First Purchase</strong>
            </span>
          </span>
        <% end %>
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Private: Team Card
  # ---------------------------------------------------------------------------

  attr :name, :string, required: true
  attr :role, :string, required: true
  attr :img, :string, required: true

  defp team_card(assigns) do
    ~H"""
    <div class="group">
      <!-- Photo -->
      <div class="relative overflow-hidden mb-4 aspect-[3/4] bg-zinc-100">
        <img
          src={@img}
          alt={@name}
          class="w-full h-full object-cover object-top group-hover:scale-105 transition-transform duration-500"
        />
        <!-- Social overlay -->
        <div class="absolute bottom-0 left-0 right-0 flex items-center justify-center gap-3 py-3 bg-white/80 translate-y-full group-hover:translate-y-0 transition-transform duration-300">
          <a href="#" class="text-zinc-500 hover:text-amber-600 transition" title="Facebook">
            <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
              <path d="M18 2h-3a5 5 0 00-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 011-1h3z" />
            </svg>
          </a>
          <a href="#" class="text-zinc-500 hover:text-amber-600 transition" title="Instagram">
            <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
              <rect x="2" y="2" width="20" height="20" rx="5" ry="5" fill="none" stroke="currentColor" stroke-width="2" />
              <circle cx="12" cy="12" r="4" fill="none" stroke="currentColor" stroke-width="2" />
              <circle cx="17.5" cy="6.5" r="1" />
            </svg>
          </a>
          <a href="#" class="text-zinc-500 hover:text-amber-600 transition" title="X / Twitter">
            <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
              <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
            </svg>
          </a>
          <a href="#" class="text-zinc-500 hover:text-amber-600 transition" title="YouTube">
            <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
              <path d="M22.54 6.42a2.78 2.78 0 00-1.95-1.96C18.88 4 12 4 12 4s-6.88 0-8.59.46A2.78 2.78 0 001.46 6.42 29 29 0 001 12a29 29 0 00.46 5.58A2.78 2.78 0 003.41 19.54C5.12 20 12 20 12 20s6.88 0 8.59-.46a2.78 2.78 0 001.95-1.96A29 29 0 0023 12a29 29 0 00-.46-5.58zM9.75 15.02V8.98L15.5 12l-5.75 3.02z" />
            </svg>
          </a>
        </div>
      </div>

      <!-- Name + role -->
      <p class="font-bold text-sm text-zinc-900"><%= @name %></p>
      <p class="text-[11px] font-semibold uppercase tracking-widest text-amber-600 mt-0.5"><%= @role %></p>
    </div>
    """
  end
end

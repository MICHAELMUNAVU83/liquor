defmodule LiquorWeb.ContactComponents do
  @moduledoc """
  Contact page UI components for the Liquor store.

  Sections:
    - contact_hero/1        – full-width store image with white card overlay
    - contact_info_strip/1  – 4-column address / hours / contact details row
    - contact_form/1        – "Information Request" form (name, phone, email, message)
    - contact_map/1         – full-width embedded Google Maps iframe
  """

  use Phoenix.Component

  # ---------------------------------------------------------------------------
  # Contact Hero
  # ---------------------------------------------------------------------------

  @doc """
  Full-width store photograph hero with a white floating card on the left
  containing the heading, sub-copy and a "Get in Touch" CTA.
  """
  def contact_hero(assigns) do
    ~H"""
    <section class="relative h-80 md:h-[420px] overflow-hidden">
      <!-- Background image -->
      <img
        src="https://images.unsplash.com/photo-1567880905822-56f8e06fe630?w=1600&auto=format&fit=crop"
        alt="The Mint Liquor Store, TRM Nairobi"
        class="absolute inset-0 w-full h-full object-cover"
      />
      <div class="absolute inset-0 bg-black/30"></div>

      <!-- White card overlay -->
      <div class="absolute left-0 top-0 bottom-0 w-full max-w-md bg-white flex flex-col justify-center px-10 py-12 shadow-xl">
        <h1 class="text-3xl md:text-4xl font-black text-zinc-900 leading-tight mb-4">
          We're Here <strong>For You</strong>
        </h1>
        <p class="text-sm text-zinc-500 leading-relaxed mb-8">
          Have a question, or want a product recommendation?<br />
          Get in touch—we're happy to help.
        </p>
        <a
          href="#contact-form"
          class="inline-block border border-amber-500 bg-white hover:bg-amber-500 hover:text-white text-amber-700 font-bold text-sm px-7 py-3 transition uppercase tracking-widest w-fit"
        >
          Get in Touch
        </a>
      </div>
    </section>
    """
  end

  # ---------------------------------------------------------------------------
  # Contact Info Strip
  # ---------------------------------------------------------------------------

  @doc """
  Four-column strip: Store Location · Headquarter · Office Hours · Contact Info.
  """
  def contact_info_strip(assigns) do
    ~H"""
    <section class="max-w-screen-xl mx-auto px-4 py-12 border-b border-zinc-100">
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8">
        <!-- Store Location -->
        <div class="flex items-start gap-4">
          <div class="flex-shrink-0 w-10 h-10 border border-zinc-300 rounded flex items-center justify-center">
            <svg class="w-5 h-5 text-zinc-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
              <path stroke-linecap="round" stroke-linejoin="round" d="M3 9.5A6.5 6.5 0 0112 3v0a6.5 6.5 0 016.5 6.5c0 4-6.5 12.5-6.5 12.5S3 13.5 3 9.5z" />
              <circle cx="12" cy="9.5" r="2" stroke-linecap="round" stroke-linejoin="round" />
            </svg>
          </div>
          <div>
            <p class="font-bold text-sm text-zinc-900 mb-1">Store Location</p>
            <p class="text-sm text-zinc-500 leading-relaxed">
              <%= Liquor.StoreConfig.store_address() %>
            </p>
          </div>
        </div>

        <!-- Headquarter -->
        <div class="flex items-start gap-4">
          <div class="flex-shrink-0 w-10 h-10 border border-zinc-300 rounded flex items-center justify-center">
            <svg class="w-5 h-5 text-zinc-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
              <path stroke-linecap="round" stroke-linejoin="round" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
              <path stroke-linecap="round" stroke-linejoin="round" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
          </div>
          <div>
            <p class="font-bold text-sm text-zinc-900 mb-1">Headquarter</p>
            <p class="text-sm text-zinc-500 leading-relaxed">
              <%= Liquor.StoreConfig.hq_address() %>
            </p>
          </div>
        </div>

        <!-- Office Hours -->
        <div class="flex items-start gap-4">
          <div class="flex-shrink-0 w-10 h-10 border border-zinc-300 rounded flex items-center justify-center">
            <svg class="w-5 h-5 text-zinc-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <div>
            <p class="font-bold text-sm text-zinc-900 mb-1">Opening Hours</p>
            <p class="text-sm text-zinc-500 leading-relaxed">
              <%= Liquor.StoreConfig.hours_weekday() %><br />
              <%= Liquor.StoreConfig.hours_saturday() %><br />
              <%= Liquor.StoreConfig.hours_sunday() %>
            </p>
          </div>
        </div>

        <!-- Contact Info -->
        <div class="flex items-start gap-4">
          <div class="flex-shrink-0 w-10 h-10 border border-zinc-300 rounded flex items-center justify-center">
            <svg class="w-5 h-5 text-zinc-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
              <path stroke-linecap="round" stroke-linejoin="round" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
            </svg>
          </div>
          <div>
            <p class="font-bold text-sm text-zinc-900 mb-1">Contact Info</p>
            <p class="text-sm text-zinc-500 leading-relaxed">
              Phone: <%= Liquor.StoreConfig.phone() %><br />
              Email: <%= Liquor.StoreConfig.email() %>
            </p>
          </div>
        </div>
      </div>
    </section>
    """
  end

  # ---------------------------------------------------------------------------
  # Contact Form
  # ---------------------------------------------------------------------------

  @doc """
  "Information Request" form with Name, Phone Number, Email, message textarea
  and a SEND MESSAGE submit button.
  """
  def contact_form(assigns) do
    ~H"""
    <section id="contact-form" class="max-w-screen-xl mx-auto px-4 py-14">
      <div class="max-w-2xl">
        <h2 class="text-2xl font-black text-zinc-900 mb-2">Information Request</h2>
        <p class="text-sm text-zinc-500 mb-10 leading-relaxed">
          For more information and how we can meet your needs, please fill out the form below<br />
          and someone from our team will be in touch.
        </p>

        <form class="space-y-8">
          <!-- Name + Phone row -->
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-8">
            <div class="flex flex-col gap-1">
              <label class="text-sm text-zinc-600">
                Name <span class="text-zinc-400">*</span>
              </label>
              <input
                type="text"
                name="name"
                required
                class="border-0 border-b border-zinc-300 focus:border-amber-500 py-2 text-sm text-zinc-800 focus:outline-none placeholder-zinc-300 bg-transparent"
              />
            </div>
            <div class="flex flex-col gap-1">
              <label class="text-sm text-zinc-600">
                Phone Number <span class="text-zinc-400">*</span>
              </label>
              <input
                type="tel"
                name="phone"
                required
                class="border-0 border-b border-zinc-300 focus:border-amber-500 py-2 text-sm text-zinc-800 focus:outline-none placeholder-zinc-300 bg-transparent"
              />
            </div>
          </div>

          <!-- Email -->
          <div class="flex flex-col gap-1">
            <label class="text-sm text-zinc-600">
              Email <span class="text-zinc-400">*</span>
            </label>
            <input
              type="email"
              name="email"
              required
              class="border-0 border-b border-zinc-300 focus:border-amber-500 py-2 text-sm text-zinc-800 focus:outline-none placeholder-zinc-300 bg-transparent w-full"
            />
          </div>

          <!-- Message -->
          <div class="flex flex-col gap-1">
            <label class="text-sm text-zinc-600 sr-only">Message</label>
            <textarea
              name="message"
              rows="5"
              placeholder="Say something..."
              class="border-0 border-b border-zinc-300 focus:border-amber-500 py-2 text-sm text-zinc-800 focus:outline-none placeholder-zinc-400 bg-transparent w-full resize-none"
            ></textarea>
          </div>

          <!-- Submit -->
          <div>
            <button
              type="submit"
              class="bg-orange-500 hover:bg-orange-600 text-white font-bold text-sm px-8 py-3 uppercase tracking-widest transition"
            >
              Send Message
            </button>
          </div>
        </form>
      </div>
    </section>
    """
  end

  # ---------------------------------------------------------------------------
  # Contact Map
  # ---------------------------------------------------------------------------

  @doc """
  Full-width embedded Google Maps iframe.
  """
  def contact_map(assigns) do
    ~H"""
    <div class="w-full h-96 md:h-[480px]">
      <iframe
        src={"https://maps.google.com/maps?q=#{Liquor.StoreConfig.map_query()}&t=&z=11&ie=UTF8&iwloc=&output=embed"}
        class="w-full h-full border-0"
        loading="lazy"
        referrerpolicy="no-referrer-when-downgrade"
        title="Store location map"
      ></iframe>
    </div>
    """
  end
end

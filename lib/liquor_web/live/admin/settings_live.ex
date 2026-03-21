defmodule LiquorWeb.Admin.SettingsLive do
  use LiquorWeb, :live_view

  alias Liquor.Settings
  alias Liquor.Catalog

  @tabs ~w(store location about homepage banners social payments)

  @impl true
  def mount(_params, _session, socket) do
    settings = Settings.all()
    products = Catalog.list_products(active: true)
    products_map = Map.new(products, fn p -> {to_string(p.id), p} end)

    featured_ids =
      (settings["homepage_featured_ids"] || "")
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    banner_previews = %{
      "main" =>
        resolve_banner_product(
          products_map,
          settings["hero_main_product_id"],
          settings["hero_main_image"]
        ),
      "tile1" =>
        resolve_banner_product(
          products_map,
          settings["hero_tile1_product_id"],
          settings["hero_tile1_image"]
        ),
      "tile2" =>
        resolve_banner_product(
          products_map,
          settings["hero_tile2_product_id"],
          settings["hero_tile2_image"]
        )
    }

    {:ok,
     assign(socket,
       page_title: "Admin – Settings",
       active_tab: "settings",
       tab: "store",
       settings: settings,
       products: products,
       products_map: products_map,
       featured_ids: featured_ids,
       banner_previews: banner_previews,
       saved: false
     ), layout: {LiquorWeb.Layouts, :admin}}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, tab: tab, saved: false)}
  end

  def handle_event("save_store", %{"settings" => params}, socket) do
    keys = ~w(store_name store_short_name store_tagline store_phone store_email site_url)
    Enum.each(keys, fn k -> Settings.set(k, params[k] || "") end)
    {:noreply, assign(socket, settings: Settings.all(), saved: true)}
  end

  def handle_event("save_location", %{"settings" => params}, socket) do
    keys = ~w(store_address store_map_query hours_weekday hours_saturday hours_sunday)
    Enum.each(keys, fn k -> Settings.set(k, params[k] || "") end)
    {:noreply, assign(socket, settings: Settings.all(), saved: true)}
  end

  def handle_event("save_about", %{"settings" => params}, socket) do
    keys = ~w(about_hero_heading about_hero_desc about_hero_image about_mission about_values)
    Enum.each(keys, fn k -> Settings.set(k, params[k] || "") end)
    {:noreply, assign(socket, settings: Settings.all(), saved: true)}
  end

  def handle_event("save_homepage", %{"settings" => params}, socket) do
    ids = params["featured_ids"] || []
    ids = ids |> Enum.reject(&(&1 == "")) |> Enum.take(5)
    Settings.set("homepage_featured_ids", Enum.join(ids, ","))
    {:noreply, assign(socket, settings: Settings.all(), featured_ids: ids, saved: true)}
  end

  def handle_event("pick_banner_product", %{"settings" => settings} = params, socket) do
    # Derive slot from _target since phx-value-* isn't sent with phx-change inside forms
    field = params |> Map.get("_target", []) |> List.last() || ""
    slot = cond do
      String.contains?(field, "main")  -> "main"
      String.contains?(field, "tile1") -> "tile1"
      String.contains?(field, "tile2") -> "tile2"
      true -> nil
    end
    key = case slot do
      "main"  -> "hero_main_product_id"
      "tile1" -> "hero_tile1_product_id"
      "tile2" -> "hero_tile2_product_id"
      _       -> nil
    end
    pid = key && settings[key]
    product = if pid && pid != "", do: Map.get(socket.assigns.products_map, pid), else: nil
    preview = if product, do: product.image_url, else: nil
    previews = if slot, do: Map.put(socket.assigns.banner_previews, slot, preview), else: socket.assigns.banner_previews
    {:noreply, assign(socket, banner_previews: previews)}
  end

  def handle_event("save_banners", %{"settings" => params}, socket) do
    for {_slot, prefix} <- [
          {"main", "hero_main"},
          {"tile1", "hero_tile1"},
          {"tile2", "hero_tile2"}
        ] do
      pid = params["#{prefix}_product_id"] || ""
      Settings.set("#{prefix}_product_id", pid)

      # Determine effective image: product image takes priority over manual URL
      image_url =
        if pid != "" do
          case Map.get(socket.assigns.products_map, pid) do
            nil -> params["#{prefix}_image"] || ""
            product -> product.image_url || params["#{prefix}_image"] || ""
          end
        else
          params["#{prefix}_image"] || ""
        end

      Settings.set("#{prefix}_image", image_url)
    end

    # Always save all text fields (empty string reverts to default on next load)
    text_keys = ~w(hero_main_label hero_main_title hero_main_price hero_main_link
                   hero_tile1_label hero_tile1_title hero_tile1_subtitle hero_tile1_link
                   hero_tile2_title hero_tile2_price hero_tile2_link)

    Enum.each(text_keys, fn k -> Settings.set(k, params[k] || "") end)

    new_settings = Settings.all()

    new_previews = %{
      "main" =>
        resolve_banner_product(
          socket.assigns.products_map,
          new_settings["hero_main_product_id"],
          new_settings["hero_main_image"]
        ),
      "tile1" =>
        resolve_banner_product(
          socket.assigns.products_map,
          new_settings["hero_tile1_product_id"],
          new_settings["hero_tile1_image"]
        ),
      "tile2" =>
        resolve_banner_product(
          socket.assigns.products_map,
          new_settings["hero_tile2_product_id"],
          new_settings["hero_tile2_image"]
        )
    }

    {:noreply, assign(socket, settings: new_settings, banner_previews: new_previews, saved: true)}
  end

  def handle_event("save_social", %{"settings" => params}, socket) do
    keys = ~w(social_instagram social_facebook social_twitter social_whatsapp)
    Enum.each(keys, fn k -> if v = params[k], do: Settings.set(k, v) end)
    {:noreply, assign(socket, settings: Settings.all(), saved: true)}
  end

  def handle_event("save_payments", %{"settings" => params}, socket) do
    enabled = if params["paystack_enabled"] == "true", do: "true", else: "false"
    Settings.set("paystack_enabled", enabled)
    keys = ~w(paystack_secret_key whatsapp_order_phone)
    Enum.each(keys, fn k -> if v = params[k], do: Settings.set(k, v) end)
    {:noreply, assign(socket, settings: Settings.all(), saved: true)}
  end

  @impl true
  def render(assigns) do
    tabs = @tabs
    assigns = assign(assigns, :tabs, tabs)

    ~H"""
    <div class="mx-auto px-4 py-8">
      
    <!-- Header -->
      <div class="mb-6">
        <h1 class="text-2xl font-black text-gray-900">Site Settings</h1>
        <p class="text-sm text-gray-500 mt-0.5">
          Control store info, homepage content, about page & social links
        </p>
      </div>
      
    <!-- Tabs -->
      <div class="flex gap-1 mb-6 border-b border-gray-200 flex-wrap">
        <%= for t <- @tabs do %>
          <button
            phx-click="switch_tab"
            phx-value-tab={t}
            class={[
              "px-4 py-2.5 text-sm font-semibold border-b-2 transition -mb-px",
              if(@tab == t,
                do: "border-amber-500 text-amber-600",
                else: "border-transparent text-gray-500 hover:text-gray-800"
              )
            ]}
          >
            {String.capitalize(t)}
          </button>
        <% end %>
      </div>

      <%= if @saved do %>
        <div class="bg-emerald-50 border border-emerald-200 rounded-lg px-4 py-3 text-sm text-emerald-700 font-medium mb-5">
          Settings saved successfully.
        </div>
      <% end %>
      
    <!-- Store Tab -->
      <%= if @tab == "store" do %>
        <.form
          for={%{}}
          phx-submit="save_store"
          class="space-y-5 bg-white border border-gray-200 rounded-xl p-6"
        >
          <h2 class="text-base font-black text-gray-800 mb-4">Store Information</h2>
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
            <.settings_field
              label="Store Full Name"
              name="settings[store_name]"
              value={@settings["store_name"]}
            />
            <.settings_field
              label="Short Name"
              name="settings[store_short_name]"
              value={@settings["store_short_name"]}
            />
            <.settings_field
              label="Tagline"
              name="settings[store_tagline]"
              value={@settings["store_tagline"]}
            />
            <.settings_field
              label="Site URL"
              name="settings[site_url]"
              value={@settings["site_url"]}
              placeholder="https://www.themint.co.ke"
            />
            <.settings_field
              label="Phone"
              name="settings[store_phone]"
              value={@settings["store_phone"]}
            />
            <.settings_field
              label="Email"
              name="settings[store_email]"
              value={@settings["store_email"]}
              type="email"
            />
          </div>
          <div class="flex justify-end pt-2">
            <button
              type="submit"
              class="bg-amber-500 hover:bg-amber-600 text-white font-bold text-sm px-6 py-2.5 rounded-lg transition"
            >
              Save Store Info
            </button>
          </div>
        </.form>
      <% end %>
      
    <!-- Location Tab -->
      <%= if @tab == "location" do %>
        <.form
          for={%{}}
          phx-submit="save_location"
          class="space-y-5 bg-white border border-gray-200 rounded-xl p-6"
        >
          <h2 class="text-base font-black text-gray-800 mb-4">Location & Opening Hours</h2>
          <.settings_field
            label="Store Address"
            name="settings[store_address]"
            value={@settings["store_address"]}
          />
          <.settings_field
            label="Google Maps Query (for embedded map)"
            name="settings[store_map_query]"
            value={@settings["store_map_query"]}
            placeholder="TRM+Mall+Thika+Road+Nairobi+Kenya"
          />
          <div class="grid grid-cols-1 sm:grid-cols-3 gap-5">
            <.settings_field
              label="Weekday Hours"
              name="settings[hours_weekday]"
              value={@settings["hours_weekday"]}
              placeholder="Monday – Friday, 9:00 am – 9:00 pm"
            />
            <.settings_field
              label="Saturday Hours"
              name="settings[hours_saturday]"
              value={@settings["hours_saturday"]}
              placeholder="Saturday, 9:00 am – 10:00 pm"
            />
            <.settings_field
              label="Sunday Hours"
              name="settings[hours_sunday]"
              value={@settings["hours_sunday"]}
              placeholder="Sunday, 10:00 am – 9:00 pm"
            />
          </div>
          <div class="flex justify-end pt-2">
            <button
              type="submit"
              class="bg-amber-500 hover:bg-amber-600 text-white font-bold text-sm px-6 py-2.5 rounded-lg transition"
            >
              Save Location
            </button>
          </div>
        </.form>
      <% end %>
      
    <!-- About Tab -->
      <%= if @tab == "about" do %>
        <.form
          for={%{}}
          phx-submit="save_about"
          class="space-y-5 bg-white border border-gray-200 rounded-xl p-6"
        >
          <h2 class="text-base font-black text-gray-800 mb-4">About Page Content</h2>
          <.settings_field
            label="Hero Heading"
            name="settings[about_hero_heading]"
            value={@settings["about_hero_heading"]}
          />
          <.settings_textarea
            label="Hero Description"
            name="settings[about_hero_desc]"
            value={@settings["about_hero_desc"]}
            rows={3}
          />
          <.settings_field
            label="Hero Image URL"
            name="settings[about_hero_image]"
            value={@settings["about_hero_image"]}
            placeholder="https://..."
          />
          <%= if @settings["about_hero_image"] && @settings["about_hero_image"] != "" do %>
            <img
              src={@settings["about_hero_image"]}
              class="h-32 w-48 object-cover rounded-lg border border-gray-200"
            />
          <% end %>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-5 pt-2 border-t border-gray-100">
            <.settings_textarea
              label="Our Mission"
              name="settings[about_mission]"
              value={@settings["about_mission"]}
              rows={6}
            />
            <.settings_textarea
              label="Core Values"
              name="settings[about_values]"
              value={@settings["about_values"]}
              rows={6}
            />
          </div>
          <div class="flex justify-end pt-2">
            <button
              type="submit"
              class="bg-amber-500 hover:bg-amber-600 text-white font-bold text-sm px-6 py-2.5 rounded-lg transition"
            >
              Save About Page
            </button>
          </div>
        </.form>
      <% end %>
      
    <!-- Homepage Tab -->
      <%= if @tab == "homepage" do %>
        <.form
          for={%{}}
          phx-submit="save_homepage"
          class="bg-white border border-gray-200 rounded-xl p-6"
        >
          <h2 class="text-base font-black text-gray-800 mb-2">Homepage Featured Products</h2>
          <p class="text-sm text-gray-500 mb-5">
            Select up to 5 products to feature in the homepage highlights grid (5 columns on desktop).
          </p>

          <div class="space-y-2 max-h-96 overflow-y-auto border border-gray-100 rounded-lg divide-y divide-gray-100">
            <%= for product <- @products do %>
              <% pid = to_string(product.id) %>
              <% checked = pid in @featured_ids %>
              <label class={[
                "flex items-center gap-3 px-4 py-3 cursor-pointer hover:bg-gray-50 transition",
                if(checked, do: "bg-amber-50")
              ]}>
                <input
                  type="checkbox"
                  name="settings[featured_ids][]"
                  value={pid}
                  checked={checked}
                  class="rounded border-gray-300 text-amber-500 focus:ring-amber-400"
                />
                <%= if product.image_url do %>
                  <img src={product.image_url} class="w-10 h-10 object-cover rounded" />
                <% else %>
                  <div class="w-10 h-10 bg-gray-100 rounded flex items-center justify-center">
                    <svg
                      class="w-5 h-5 text-gray-300"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                      />
                    </svg>
                  </div>
                <% end %>
                <div class="flex-1 min-w-0">
                  <p class="font-semibold text-sm text-gray-900 truncate">{product.name}</p>
                  <p class="text-xs text-gray-400">
                    {if product.category, do: product.category.name, else: ""}
                  </p>
                </div>
                <%= if checked do %>
                  <span class="text-[10px] font-bold uppercase tracking-wide bg-amber-100 text-amber-700 px-2 py-0.5 rounded">
                    Featured
                  </span>
                <% end %>
              </label>
            <% end %>
          </div>

          <p class="text-xs text-gray-400 mt-2">{length(@featured_ids)}/5 selected</p>

          <div class="flex justify-end pt-4">
            <button
              type="submit"
              class="bg-amber-500 hover:bg-amber-600 text-white font-bold text-sm px-6 py-2.5 rounded-lg transition"
            >
              Save Homepage
            </button>
          </div>
        </.form>
      <% end %>
      
    <!-- Banners Tab -->
      <%= if @tab == "banners" do %>
        <.form
          for={%{}}
          phx-submit="save_banners"
          class="space-y-6 bg-white border border-gray-200 rounded-xl p-6"
        >
          <h2 class="text-base font-black text-gray-800">Homepage Hero Banners</h2>
          <p class="text-sm text-gray-500 -mt-4">
            Pick a product for each panel — its image becomes the background. You can still override the title and price below.
          </p>
          
    <!-- Main Banner -->
          <div class="border border-gray-100 rounded-xl p-5 space-y-4">
            <div class="flex items-center gap-2 mb-1">
              <span class="w-2 h-2 rounded-full bg-amber-500"></span>
              <h3 class="font-bold text-sm text-gray-700">Main Banner (Large Left Panel)</h3>
            </div>
            <!-- Product picker -->
            <div>
              <label class="block text-xs font-semibold text-gray-600 mb-1">
                Select Product (uses product image)
              </label>
              <select
                name="settings[hero_main_product_id]"
                phx-change="pick_banner_product"
                phx-value-slot="main"
                class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-amber-400"
              >
                <option value="">— None (use image URL below) —</option>
                <%= for p <- @products do %>
                  <option
                    value={to_string(p.id)}
                    selected={to_string(p.id) == (@settings["hero_main_product_id"] || "")}
                  >
                    {p.name}{if p.category, do: " (#{p.category.name})"}
                  </option>
                <% end %>
              </select>
            </div>
            <!-- Live preview -->
            <%= if @banner_previews["main"] do %>
              <img
                src={@banner_previews["main"]}
                class="h-32 w-64 object-cover rounded-lg border border-gray-200"
              />
            <% end %>
            <!-- Text fields -->
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2 border-t border-gray-100">
              <.settings_field
                label="Label (small text above title)"
                name="settings[hero_main_label]"
                value={@settings["hero_main_label"]}
                placeholder="Today's Highlights"
              />
              <.settings_field
                label="Title"
                name="settings[hero_main_title]"
                value={@settings["hero_main_title"]}
                placeholder="Whiskies of The Month"
              />
              <.settings_field
                label="Price Text"
                name="settings[hero_main_price]"
                value={@settings["hero_main_price"]}
                placeholder="KSh 3,999"
              />
              <.settings_field
                label="Button Link"
                name="settings[hero_main_link]"
                value={@settings["hero_main_link"]}
                placeholder="/shop"
              />
            </div>
            <.settings_field
              label="Image URL (auto-filled from product above, or paste your own)"
              name="settings[hero_main_image]"
              value={@banner_previews["main"] || @settings["hero_main_image"] || ""}
              placeholder="https://..."
            />
          </div>
          
    <!-- Tile 1 -->
          <div class="border border-gray-100 rounded-xl p-5 space-y-4">
            <div class="flex items-center gap-2 mb-1">
              <span class="w-2 h-2 rounded-full bg-blue-500"></span>
              <h3 class="font-bold text-sm text-gray-700">Top Right Tile</h3>
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-600 mb-1">
                Select Product (uses product image)
              </label>
              <select
                name="settings[hero_tile1_product_id]"
                phx-change="pick_banner_product"
                phx-value-slot="tile1"
                class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-amber-400"
              >
                <option value="">— None (use image URL below) —</option>
                <%= for p <- @products do %>
                  <option
                    value={to_string(p.id)}
                    selected={to_string(p.id) == (@settings["hero_tile1_product_id"] || "")}
                  >
                    {p.name}{if p.category, do: " (#{p.category.name})"}
                  </option>
                <% end %>
              </select>
            </div>
            <%= if @banner_previews["tile1"] do %>
              <img
                src={@banner_previews["tile1"]}
                class="h-32 w-64 object-cover rounded-lg border border-gray-200"
              />
            <% end %>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2 border-t border-gray-100">
              <.settings_field
                label="Label"
                name="settings[hero_tile1_label]"
                value={@settings["hero_tile1_label"]}
                placeholder="Black Friday"
              />
              <.settings_field
                label="Title"
                name="settings[hero_tile1_title]"
                value={@settings["hero_tile1_title"]}
                placeholder="Shop & Save"
              />
              <.settings_field
                label="Subtitle"
                name="settings[hero_tile1_subtitle]"
                value={@settings["hero_tile1_subtitle"]}
                placeholder="selected bourbons"
              />
              <.settings_field
                label="Button Link"
                name="settings[hero_tile1_link]"
                value={@settings["hero_tile1_link"]}
                placeholder="/shop"
              />
            </div>
            <.settings_field
              label="Image URL (auto-filled from product above, or paste your own)"
              name="settings[hero_tile1_image]"
              value={@banner_previews["tile1"] || @settings["hero_tile1_image"] || ""}
              placeholder="https://..."
            />
          </div>
          
    <!-- Tile 2 -->
          <div class="border border-gray-100 rounded-xl p-5 space-y-4">
            <div class="flex items-center gap-2 mb-1">
              <span class="w-2 h-2 rounded-full bg-emerald-500"></span>
              <h3 class="font-bold text-sm text-gray-700">Bottom Right Tile</h3>
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-600 mb-1">
                Select Product (uses product image)
              </label>
              <select
                name="settings[hero_tile2_product_id]"
                phx-change="pick_banner_product"
                phx-value-slot="tile2"
                class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-amber-400"
              >
                <option value="">— None (use image URL below) —</option>
                <%= for p <- @products do %>
                  <option
                    value={to_string(p.id)}
                    selected={to_string(p.id) == (@settings["hero_tile2_product_id"] || "")}
                  >
                    {p.name}{if p.category, do: " (#{p.category.name})"}
                  </option>
                <% end %>
              </select>
            </div>
            <%= if @banner_previews["tile2"] do %>
              <img
                src={@banner_previews["tile2"]}
                class="h-32 w-64 object-cover rounded-lg border border-gray-200"
              />
            <% end %>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2 border-t border-gray-100">
              <.settings_field
                label="Title"
                name="settings[hero_tile2_title]"
                value={@settings["hero_tile2_title"]}
                placeholder="Exclusive Offer"
              />
              <.settings_field
                label="Price Text"
                name="settings[hero_tile2_price]"
                value={@settings["hero_tile2_price"]}
                placeholder="KSh 2,499"
              />
              <.settings_field
                label="Button Link"
                name="settings[hero_tile2_link]"
                value={@settings["hero_tile2_link"]}
                placeholder="/shop"
              />
            </div>
            <.settings_field
              label="Image URL (auto-filled from product above, or paste your own)"
              name="settings[hero_tile2_image]"
              value={@banner_previews["tile2"] || @settings["hero_tile2_image"] || ""}
              placeholder="https://..."
            />
          </div>

          <div class="flex justify-end pt-2">
            <button
              type="submit"
              class="bg-amber-500 hover:bg-amber-600 text-white font-bold text-sm px-6 py-2.5 rounded-lg transition"
            >
              Save Banners
            </button>
          </div>
        </.form>
      <% end %>
      
    <!-- Social Tab -->
      <%= if @tab == "social" do %>
        <.form
          for={%{}}
          phx-submit="save_social"
          class="space-y-5 bg-white border border-gray-200 rounded-xl p-6"
        >
          <h2 class="text-base font-black text-gray-800 mb-4">Social Links</h2>
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
            <.settings_field
              label="Instagram URL"
              name="settings[social_instagram]"
              value={@settings["social_instagram"]}
              placeholder="https://instagram.com/..."
            />
            <.settings_field
              label="Facebook URL"
              name="settings[social_facebook]"
              value={@settings["social_facebook"]}
              placeholder="https://facebook.com/..."
            />
            <.settings_field
              label="Twitter / X URL"
              name="settings[social_twitter]"
              value={@settings["social_twitter"]}
              placeholder="https://twitter.com/..."
            />
            <.settings_field
              label="WhatsApp Number"
              name="settings[social_whatsapp]"
              value={@settings["social_whatsapp"]}
              placeholder="+254700123456"
            />
          </div>
          <div class="flex justify-end pt-2">
            <button
              type="submit"
              class="bg-amber-500 hover:bg-amber-600 text-white font-bold text-sm px-6 py-2.5 rounded-lg transition"
            >
              Save Social Links
            </button>
          </div>
        </.form>
      <% end %>
      <!-- Payments Tab -->
      <%= if @tab == "payments" do %>
        <.form for={%{}} phx-submit="save_payments" class="space-y-5 bg-white border border-gray-200 rounded-xl p-6">
          <h2 class="text-base font-black text-gray-800 mb-1">Payment Settings</h2>
          <p class="text-sm text-gray-500 -mt-3 mb-4">Enable Paystack for online checkout, or fall back to a WhatsApp order.</p>

          <!-- Paystack toggle -->
          <div class="flex items-center justify-between bg-gray-50 border border-gray-200 rounded-xl px-5 py-4">
            <div>
              <p class="font-semibold text-sm text-gray-800">Enable Paystack Checkout</p>
              <p class="text-xs text-gray-500 mt-0.5">Customers will pay online via Paystack. If disabled, they'll be sent to WhatsApp.</p>
            </div>
            <label class="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                name="settings[paystack_enabled]"
                value="true"
                checked={@settings["paystack_enabled"] == "true"}
                class="sr-only peer"
              />
              <div class="w-11 h-6 bg-gray-200 peer-focus:ring-2 peer-focus:ring-amber-400 rounded-full peer peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-amber-500"></div>
            </label>
          </div>

          <!-- Paystack secret key -->
          <div>
            <label class="block text-xs font-semibold text-gray-600 mb-1">Paystack Secret Key</label>
            <input
              type="password"
              name="settings[paystack_secret_key]"
              value={@settings["paystack_secret_key"]}
              placeholder="sk_live_..."
              class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
            />
            <p class="text-xs text-gray-400 mt-1">Your Paystack secret key from the Paystack dashboard.</p>
          </div>

          <div class="border-t border-gray-100 pt-5">
            <h3 class="font-bold text-sm text-gray-700 mb-3">WhatsApp Fallback</h3>
            <.settings_field
              label="WhatsApp Number for Orders (used when Paystack is disabled)"
              name="settings[whatsapp_order_phone]"
              value={@settings["whatsapp_order_phone"]}
              placeholder="+254700123456"
            />
            <p class="text-xs text-gray-400 mt-1">Include country code. Customers will be sent here with a pre-filled order message.</p>
          </div>

          <div class="flex justify-end pt-2">
            <button type="submit" class="bg-amber-500 hover:bg-amber-600 text-white font-bold text-sm px-6 py-2.5 rounded-lg transition">Save Payment Settings</button>
          </div>
        </.form>
      <% end %>

    </div>
    """
  end

  # Private helpers
  defp resolve_banner_product(_map, nil, image), do: image
  defp resolve_banner_product(_map, "", image), do: image

  defp resolve_banner_product(map, pid, image) do
    case Map.get(map, pid) do
      nil -> image
      product -> product.image_url || image
    end
  end

  # Helper components
  attr :label, :string, required: true
  attr :name, :string, required: true
  attr :value, :string, default: ""
  attr :placeholder, :string, default: ""
  attr :type, :string, default: "text"

  defp settings_field(assigns) do
    ~H"""
    <div>
      <label class="block text-xs font-semibold text-gray-600 mb-1">{@label}</label>
      <input
        type={@type}
        name={@name}
        value={@value || ""}
        placeholder={@placeholder}
        class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
      />
    </div>
    """
  end

  attr :label, :string, required: true
  attr :name, :string, required: true
  attr :value, :string, default: ""
  attr :rows, :integer, default: 4

  defp settings_textarea(assigns) do
    ~H"""
    <div>
      <label class="block text-xs font-semibold text-gray-600 mb-1">{@label}</label>
      <textarea
        name={@name}
        rows={@rows}
        class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400 resize-y"
      ><%= @value || "" %></textarea>
    </div>
    """
  end
end

defmodule LiquorWeb.Admin.ProductsLive do
  use LiquorWeb, :live_view

  alias Liquor.Catalog
  alias Liquor.Catalog.{Product, ProductVariant}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: "Admin – Products",
       active_tab: "products",
       search: "",
       category_id: nil,
       # product modal
       show_modal: false,
       editing: nil,
       form: nil,
       # variants panel
       variants_product: nil,
       variants: [],
       # variant form
       editing_variant: nil,
       variant_form: nil,
       show_variant_form: false
     )
     |> allow_upload(:product_image,
       accept: ~w(.jpg .jpeg .png .webp .gif),
       max_entries: 1,
       max_file_size: 10_000_000
     )
     |> load_data(), layout: {LiquorWeb.Layouts, :admin}}
  end

  defp load_data(socket) do
    assign(socket,
      products:
        Catalog.list_products(
          search: socket.assigns.search,
          category_id: socket.assigns.category_id
        ),
      categories: Catalog.list_categories()
    )
  end

  defp reload_variants(socket) do
    case socket.assigns.variants_product do
      nil -> socket
      product -> assign(socket, variants: Catalog.list_variants_for(product.id))
    end
  end

  # ── Product events ─────────────────────────────────────────────────────────

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, socket |> assign(search: q) |> load_data()}
  end

  def handle_event("filter_category", %{"id" => id}, socket) do
    cat_id = if id == "", do: nil, else: String.to_integer(id)
    {:noreply, socket |> assign(category_id: cat_id) |> load_data()}
  end

  def handle_event("new_product", _params, socket) do
    form = to_form(Catalog.change_product(%Product{}), as: :product)
    {:noreply, assign(socket, show_modal: true, editing: nil, form: form)}
  end

  def handle_event("edit_product", %{"id" => id}, socket) do
    product = Catalog.get_product!(id)
    form = to_form(Catalog.change_product(product), as: :product)
    {:noreply, assign(socket, show_modal: true, editing: product, form: form)}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, show_modal: false, editing: nil, form: nil)}
  end

  def handle_event("validate_product", %{"product" => params}, socket) do
    product = socket.assigns.editing || %Product{}
    form = to_form(Catalog.change_product(product, params), as: :product)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save_product", %{"product" => params}, socket) do
    uploaded_url =
      consume_uploaded_entries(socket, :product_image, fn %{path: tmp_path}, entry ->
        dest_dir = Application.app_dir(:liquor, "priv/static/uploads")
        File.mkdir_p!(dest_dir)
        ext = Path.extname(entry.client_name)
        filename = "#{System.unique_integer([:positive, :monotonic])}#{ext}"
        File.cp!(tmp_path, Path.join(dest_dir, filename))
        {:ok, "/uploads/#{filename}"}
      end)
      |> List.first()

    IO.inspect(uploaded_url, label: "Uploaded URL")
    params = if uploaded_url, do: Map.put(params, "image_url", uploaded_url), else: params

    result =
      case socket.assigns.editing do
        nil -> IO.inspect(Catalog.create_product(params))
        product -> IO.inspect(Catalog.update_product(product, params))
      end

    case result do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Product saved.")
         |> assign(show_modal: false, editing: nil, form: nil)
         |> load_data()}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: :product))}
    end
  end

  def handle_event("toggle_active", %{"id" => id}, socket) do
    product = Catalog.get_product!(id)
    {:ok, _} = Catalog.update_product(product, %{is_active: !product.is_active})
    {:noreply, socket |> put_flash(:info, "Product updated.") |> load_data()}
  end

  def handle_event("toggle_featured", %{"id" => id}, socket) do
    product = Catalog.get_product!(id)
    {:ok, _} = Catalog.update_product(product, %{is_featured: !product.is_featured})
    {:noreply, socket |> put_flash(:info, "Product updated.") |> load_data()}
  end

  def handle_event("delete_product", %{"id" => id}, socket) do
    product = Catalog.get_product!(id)
    {:ok, _} = Catalog.delete_product(product)
    {:noreply, socket |> put_flash(:info, "Product deleted.") |> load_data()}
  end

  # ── Variants panel events ───────────────────────────────────────────────────

  def handle_event("open_variants", %{"id" => id}, socket) do
    product = Catalog.get_product!(id)
    variants = Catalog.list_variants_for(product.id)

    {:noreply,
     assign(socket,
       variants_product: product,
       variants: variants,
       editing_variant: nil,
       variant_form: nil,
       show_variant_form: false
     )}
  end

  def handle_event("close_variants", _params, socket) do
    {:noreply,
     assign(socket,
       variants_product: nil,
       variants: [],
       editing_variant: nil,
       variant_form: nil,
       show_variant_form: false
     )}
  end

  def handle_event("new_variant", _params, socket) do
    product = socket.assigns.variants_product

    form =
      to_form(
        Catalog.change_variant(%ProductVariant{product_id: product.id}),
        as: :variant
      )

    {:noreply, assign(socket, show_variant_form: true, editing_variant: nil, variant_form: form)}
  end

  def handle_event("edit_variant", %{"id" => id}, socket) do
    variant = Catalog.get_variant!(id)
    form = to_form(Catalog.change_variant(variant), as: :variant)

    {:noreply,
     assign(socket, show_variant_form: true, editing_variant: variant, variant_form: form)}
  end

  def handle_event("cancel_variant_form", _params, socket) do
    {:noreply, assign(socket, show_variant_form: false, editing_variant: nil, variant_form: nil)}
  end

  def handle_event("validate_variant", %{"variant" => params}, socket) do
    base =
      socket.assigns.editing_variant ||
        %ProductVariant{product_id: socket.assigns.variants_product.id}

    form = to_form(Catalog.change_variant(base, params), as: :variant)
    {:noreply, assign(socket, variant_form: form)}
  end

  def handle_event("save_variant", %{"variant" => params}, socket) do
    product = socket.assigns.variants_product
    params = Map.put(params, "product_id", to_string(product.id))

    result =
      case socket.assigns.editing_variant do
        nil -> Catalog.create_variant(params)
        variant -> Catalog.update_variant(variant, params)
      end

    case result do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Variant saved.")
         |> assign(show_variant_form: false, editing_variant: nil, variant_form: nil)
         |> reload_variants()
         |> load_data()}

      {:error, changeset} ->
        {:noreply, assign(socket, variant_form: to_form(changeset, as: :variant))}
    end
  end

  def handle_event("delete_variant", %{"id" => id}, socket) do
    variant = Catalog.get_variant!(id)
    {:ok, _} = Catalog.delete_variant(variant)

    {:noreply,
     socket
     |> put_flash(:info, "Variant deleted.")
     |> reload_variants()
     |> load_data()}
  end

  def handle_event("set_default_variant", %{"id" => id}, socket) do
    id_int = String.to_integer(id)

    # Clear default on all variants for this product, then set the new one
    Enum.each(socket.assigns.variants, fn v ->
      Catalog.update_variant(v, %{is_default: v.id == id_int})
    end)

    {:noreply,
     socket
     |> put_flash(:info, "Default variant updated.")
     |> reload_variants()
     |> load_data()}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :product_image, ref)}
  end

  # Ignore stray window keydown events that don't match any pattern
  def handle_event(_event, _params, socket), do: {:noreply, socket}

  # ── Render ──────────────────────────────────────────────────────────────────

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-screen-xl mx-auto px-4 py-8">
      <!-- Header -->
      <div class="flex items-center justify-between mb-6 flex-wrap gap-3">
        <div>
          <h1 class="text-2xl font-black text-gray-900">Products</h1>
          <p class="text-sm text-gray-500">{length(@products)} products</p>
        </div>
        <button
          phx-click="new_product"
          class="bg-amber-500 hover:bg-amber-600 text-white font-bold text-sm px-5 py-2.5 rounded-lg transition uppercase tracking-widest"
        >
          + New Product
        </button>
      </div>
      
    <!-- Filters -->
      <div class="flex gap-3 mb-6 flex-wrap">
        <form phx-change="search" class="flex-1 min-w-[200px]">
          <input
            type="text"
            name="q"
            value={@search}
            placeholder="Search products…"
            class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
          />
        </form>
        <form phx-change="filter_category">
          <select
            name="id"
            class="border border-gray-200 rounded-lg px-3 py-2 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-amber-400"
          >
            <option value="">All Categories</option>
            <%= for cat <- @categories do %>
              <option value={cat.id} selected={@category_id == cat.id}>{cat.name}</option>
            <% end %>
          </select>
        </form>
      </div>
      
    <!-- Table -->
      <div class="bg-white border border-gray-200 rounded-xl overflow-hidden">
        <table class="w-full text-sm">
          <thead class="bg-gray-50 border-b border-gray-200">
            <tr>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">
                Product
              </th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">
                Category
              </th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">
                Variants
              </th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">
                Badge
              </th>
              <th class="text-center px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">
                Featured
              </th>
              <th class="text-center px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">
                Active
              </th>
              <th class="text-right px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">
                Actions
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <%= for p <- @products do %>
              <tr class="hover:bg-gray-50 transition">
                <td class="px-5 py-3">
                  <div class="flex items-center gap-3">
                    <div class="w-10 h-10 bg-gray-100 rounded-lg overflow-hidden shrink-0">
                      <%= if p.image_url do %>
                        <img src={p.image_url} class="w-full h-full object-cover" />
                      <% else %>
                        <div class="w-full h-full flex items-center justify-center text-gray-300">
                          <svg
                            class="w-5 h-5"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                            stroke-width="1.5"
                          >
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
                            />
                          </svg>
                        </div>
                      <% end %>
                    </div>
                    <div>
                      <p class="font-semibold text-gray-900 leading-tight">{p.name}</p>
                      <p class="text-xs text-gray-400 font-mono">{p.slug}</p>
                    </div>
                  </div>
                </td>
                <td class="px-5 py-3 text-gray-600">{p.category.name}</td>
                <td class="px-5 py-3">
                  <button
                    phx-click="open_variants"
                    phx-value-id={p.id}
                    class={[
                      "inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-lg border transition",
                      if(length(p.variants) > 0,
                        do: "bg-blue-50 text-blue-700 border-blue-200 hover:bg-blue-100",
                        else: "bg-gray-50 text-gray-500 border-gray-200 hover:bg-gray-100"
                      )
                    ]}
                  >
                    <svg
                      class="w-3 h-3"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      viewBox="0 0 24 24"
                    >
                      <path d="M20 7l-8-4-8 4m16 0v10l-8 4m0-14v14m0 0l-8-4V7" />
                    </svg>
                    {length(p.variants)} variant{if length(p.variants) != 1, do: "s"}
                  </button>
                </td>
                <td class="px-5 py-3">
                  <%= if p.badge do %>
                    <span class={[
                      "text-[9px] font-black uppercase tracking-wide px-2 py-0.5 rounded",
                      if(p.badge == "best_seller",
                        do: "bg-emerald-100 text-emerald-700",
                        else: "bg-amber-100 text-amber-700"
                      )
                    ]}>
                      {String.replace(p.badge, "_", " ")}
                    </span>
                  <% else %>
                    <span class="text-gray-300">—</span>
                  <% end %>
                </td>
                <td class="px-5 py-3 text-center">
                  <button phx-click="toggle_featured" phx-value-id={p.id} class="cursor-pointer">
                    <%= if p.is_featured do %>
                      <svg
                        class="w-5 h-5 text-amber-500 mx-auto"
                        fill="currentColor"
                        viewBox="0 0 20 20"
                      >
                        <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                      </svg>
                    <% else %>
                      <svg
                        class="w-5 h-5 text-gray-300 mx-auto hover:text-amber-400 transition"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                        stroke-width="1.5"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          d="M11.48 3.499a.562.562 0 011.04 0l2.125 5.111a.563.563 0 00.475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 00-.182.557l1.285 5.385a.562.562 0 01-.84.61l-4.725-2.885a.563.563 0 00-.586 0L6.982 20.54a.562.562 0 01-.84-.61l1.285-5.386a.562.562 0 00-.182-.557l-4.204-3.602a.562.562 0 01.321-.988l5.518-.442a.563.563 0 00.475-.345L11.48 3.5z"
                        />
                      </svg>
                    <% end %>
                  </button>
                </td>
                <td class="px-5 py-3 text-center">
                  <button
                    phx-click="toggle_active"
                    phx-value-id={p.id}
                    class={[
                      "relative inline-flex h-5 w-9 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200",
                      if(p.is_active, do: "bg-emerald-500", else: "bg-gray-300")
                    ]}
                  >
                    <span class={[
                      "inline-block h-4 w-4 transform rounded-full bg-white shadow transition duration-200",
                      if(p.is_active, do: "translate-x-4", else: "translate-x-0")
                    ]}>
                    </span>
                  </button>
                </td>
                <td class="px-5 py-3 text-right">
                  <div class="flex items-center justify-end gap-2">
                    <button
                      phx-click="edit_product"
                      phx-value-id={p.id}
                      class="text-xs font-semibold text-gray-600 hover:text-amber-600 transition px-2 py-1 border border-gray-200 rounded-lg hover:border-amber-400"
                    >
                      Edit
                    </button>
                    <button
                      phx-click="delete_product"
                      phx-value-id={p.id}
                      data-confirm={"Delete \"#{p.name}\"? This cannot be undone."}
                      class="text-xs font-semibold text-gray-400 hover:text-red-500 transition px-2 py-1 border border-gray-200 rounded-lg hover:border-red-300"
                    >
                      Delete
                    </button>
                  </div>
                </td>
              </tr>
            <% end %>
            <%= if @products == [] do %>
              <tr>
                <td colspan="7" class="px-5 py-12 text-center text-sm text-gray-400">
                  No products found.
                  <button
                    phx-click="new_product"
                    class="text-amber-600 font-semibold hover:underline ml-1"
                  >
                    Add one?
                  </button>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>

    <!-- ── Product modal ─────────────────────────────────────────── -->
    <%= if @show_modal do %>
      <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
        <div
          class="bg-white rounded-xl shadow-2xl w-full max-w-2xl max-h-[90vh] overflow-y-auto"
          phx-window-keydown="close_modal"
          phx-key="Escape"
        >
          <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200 sticky top-0 bg-white">
            <h2 class="text-lg font-black text-gray-900">
              {if @editing, do: "Edit Product", else: "New Product"}
            </h2>
            <button phx-click="close_modal" class="text-gray-400 hover:text-gray-700 transition">
              <svg
                class="w-5 h-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                stroke-width="2"
              >
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <form phx-change="validate_product" phx-submit="save_product" class="p-6 space-y-5">
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
              <.field form={@form} field={:name} label="Name *" type="text" />
              <.field
                form={@form}
                field={:slug}
                label="Slug"
                type="text"
                placeholder="auto-generated"
              />
            </div>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
              <.select_field
                form={@form}
                field={:category_id}
                label="Category *"
                options={Enum.map(@categories, &{&1.name, &1.id})}
              />
              <.select_field
                form={@form}
                field={:brand_id}
                label="Brand"
                options={[{"— None —", ""}] ++ Enum.map(Catalog.list_brands(), &{&1.name, &1.id})}
              />
            </div>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
              <.select_field
                form={@form}
                field={:badge}
                label="Badge"
                options={[
                  {"— None —", ""},
                  {"Best Seller", "best_seller"},
                  {"Limited Edition", "limited_edition"}
                ]}
              />
              <.field form={@form} field={:year} label="Year" type="number" placeholder="e.g. 2021" />
            </div>
            
    <!-- Image upload -->
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-2">Product Image</label>
              
    <!-- Current/Existing Image Preview -->
              <%= if @uploads.product_image.entries == [] do %>
                <%= if @editing && @editing.image_url && @editing.image_url != "" do %>
                  <div class="mb-2 flex items-center gap-3 p-2 bg-gray-50 rounded-lg border border-gray-200">
                    <img
                      src={@editing.image_url}
                      class="w-16 h-16 object-cover rounded-lg border border-gray-200"
                    />
                    <div class="flex-1">
                      <p class="text-xs text-gray-600 font-semibold">Current image</p>
                      <p class="text-xs text-gray-400 truncate">{@editing.image_url}</p>
                    </div>
                  </div>
                <% end %>
              <% end %>
              
    <!-- File Upload Input -->
              <.live_file_input
                upload={@uploads.product_image}
                class="block w-full text-sm text-gray-700 border border-gray-200 rounded-lg p-2 mb-2"
              />
              
    <!-- Upload Preview (for new uploads) -->
              <%= for entry <- @uploads.product_image.entries do %>
                <div class="mt-2 flex items-center gap-3 p-2 bg-blue-50 rounded-lg border border-blue-200">
                  <.live_img_preview
                    entry={entry}
                    class="w-16 h-16 object-cover rounded-lg border border-gray-200"
                  />
                  <div class="flex-1">
                    <p class="text-xs text-blue-700 truncate font-semibold">{entry.client_name}</p>
                    <div class="mt-1 h-1.5 w-full bg-blue-200 rounded-full overflow-hidden">
                      <div class="h-full bg-blue-500 rounded-full" style={"width: #{entry.progress}%"}>
                      </div>
                    </div>
                    <%= for err <- upload_errors(@uploads.product_image, entry) do %>
                      <p class="text-xs text-red-500 mt-0.5">{err}</p>
                    <% end %>
                  </div>
                  <button
                    type="button"
                    phx-click="cancel_upload"
                    phx-value-ref={entry.ref}
                    class="text-gray-400 hover:text-red-500 text-sm font-bold"
                  >
                    ✕
                  </button>
                </div>
              <% end %>
              
    <!-- URL Input as alternative -->
              <div class="mt-2">
                <.field
                  form={@form}
                  field={:image_url}
                  label=""
                  type="text"
                  placeholder="Or paste an image URL here"
                />
              </div>
            </div>

            <.field form={@form} field={:description} label="Description" type="textarea" />
            <div class="flex gap-6">
              <label class="flex items-center gap-2 text-sm text-gray-700 cursor-pointer">
                <input type="hidden" name="product[is_featured]" value="false" />
                <input
                  type="checkbox"
                  name="product[is_featured]"
                  value="true"
                  checked={Phoenix.HTML.Form.input_value(@form, :is_featured)}
                  class="rounded border-gray-300 text-amber-500 focus:ring-amber-400"
                /> Featured
              </label>
              <label class="flex items-center gap-2 text-sm text-gray-700 cursor-pointer">
                <input type="hidden" name="product[is_active]" value="false" />
                <input
                  type="checkbox"
                  name="product[is_active]"
                  value="true"
                  checked={Phoenix.HTML.Form.input_value(@form, :is_active) != false}
                  class="rounded border-gray-300 text-amber-500 focus:ring-amber-400"
                /> Active
              </label>
            </div>
            <div class="flex justify-end gap-3 pt-2 border-t border-gray-100">
              <button
                type="button"
                phx-click="close_modal"
                class="px-4 py-2 text-sm font-semibold text-gray-600 hover:text-gray-900 border border-gray-200 rounded-lg transition"
              >
                Cancel
              </button>
              <button
                type="submit"
                class="px-5 py-2 bg-amber-500 hover:bg-amber-600 text-white font-bold text-sm rounded-lg transition uppercase tracking-wide"
              >
                Save Product
              </button>
            </div>
          </form>
        </div>
      </div>
    <% end %>

    <!-- ── Variants panel ────────────────────────────────────────── -->
    <%= if @variants_product do %>
      <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
        <div
          class="bg-white rounded-xl shadow-2xl w-full max-w-3xl max-h-[92vh] flex flex-col"
          phx-window-keydown="close_variants"
          phx-key="Escape"
        >
          <!-- Panel header -->
          <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200 shrink-0">
            <div>
              <h2 class="text-lg font-black text-gray-900">Variants</h2>
              <p class="text-xs text-gray-400 mt-0.5">
                {@variants_product.name} · {length(@variants)} variant{if length(@variants) != 1,
                  do: "s"}
              </p>
            </div>
            <div class="flex items-center gap-3">
              <%= if not @show_variant_form do %>
                <button
                  phx-click="new_variant"
                  class="bg-amber-500 hover:bg-amber-600 text-white font-bold text-xs px-4 py-2 rounded-lg transition uppercase tracking-widest"
                >
                  + Add Variant
                </button>
              <% end %>
              <button phx-click="close_variants" class="text-gray-400 hover:text-gray-700">
                <svg
                  class="w-5 h-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  stroke-width="2"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          </div>

          <div class="overflow-y-auto flex-1 p-6 space-y-5">
            
    <!-- ── Variant form ── -->
            <%= if @show_variant_form do %>
              <div class="bg-gray-50 border border-gray-200 rounded-xl p-5">
                <h3 class="font-bold text-gray-800 mb-4">
                  {if @editing_variant, do: "Edit Variant", else: "New Variant"}
                </h3>
                <form phx-change="validate_variant" phx-submit="save_variant" class="space-y-4">
                  <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
                    <div>
                      <label class="block text-xs font-semibold text-gray-500 mb-1">Size *</label>
                      <input
                        type="text"
                        name="variant[size]"
                        value={Phoenix.HTML.Form.input_value(@variant_form, :size)}
                        placeholder="e.g. 750ml"
                        class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
                      />
                      <%= for {msg, _} <- Keyword.get_values(@variant_form.errors, :size) do %>
                        <p class="text-xs text-red-500 mt-0.5">{msg}</p>
                      <% end %>
                    </div>
                    <div>
                      <label class="block text-xs font-semibold text-gray-500 mb-1">
                        Price (KES) *
                      </label>
                      <input
                        type="number"
                        step="0.01"
                        name="variant[price]"
                        value={Phoenix.HTML.Form.input_value(@variant_form, :price)}
                        placeholder="0.00"
                        class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
                      />
                      <%= for {msg, _} <- Keyword.get_values(@variant_form.errors, :price) do %>
                        <p class="text-xs text-red-500 mt-0.5">{msg}</p>
                      <% end %>
                    </div>
                    <div>
                      <label class="block text-xs font-semibold text-gray-500 mb-1">
                        Compare Price (KES)
                      </label>
                      <input
                        type="number"
                        step="0.01"
                        name="variant[compare_price]"
                        value={Phoenix.HTML.Form.input_value(@variant_form, :compare_price)}
                        placeholder="0.00"
                        class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
                      />
                    </div>
                    <div>
                      <label class="block text-xs font-semibold text-gray-500 mb-1">ABV (%)</label>
                      <input
                        type="number"
                        step="0.1"
                        name="variant[abv]"
                        value={Phoenix.HTML.Form.input_value(@variant_form, :abv)}
                        placeholder="e.g. 40.0"
                        class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
                      />
                    </div>
                  </div>
                  <div class="grid grid-cols-2 sm:grid-cols-3 gap-4">
                    <div>
                      <label class="block text-xs font-semibold text-gray-500 mb-1">SKU</label>
                      <input
                        type="text"
                        name="variant[sku]"
                        value={Phoenix.HTML.Form.input_value(@variant_form, :sku)}
                        placeholder="auto-generated"
                        class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm font-mono focus:outline-none focus:ring-2 focus:ring-amber-400"
                      />
                      <%= for {msg, _} <- Keyword.get_values(@variant_form.errors, :sku) do %>
                        <p class="text-xs text-red-500 mt-0.5">{msg}</p>
                      <% end %>
                    </div>
                    <div>
                      <label class="block text-xs font-semibold text-gray-500 mb-1">
                        Stock Quantity
                      </label>
                      <input
                        type="number"
                        min="0"
                        name="variant[stock_quantity]"
                        value={Phoenix.HTML.Form.input_value(@variant_form, :stock_quantity)}
                        placeholder="0"
                        class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
                      />
                    </div>
                    <div class="flex items-end pb-2">
                      <label class="flex items-center gap-2 text-sm text-gray-700 cursor-pointer">
                        <input type="hidden" name="variant[is_default]" value="false" />
                        <input
                          type="checkbox"
                          name="variant[is_default]"
                          value="true"
                          checked={Phoenix.HTML.Form.input_value(@variant_form, :is_default)}
                          class="rounded border-gray-300 text-amber-500 focus:ring-amber-400"
                        />
                        <span class="font-semibold">Default variant</span>
                      </label>
                    </div>
                  </div>
                  <div class="flex justify-end gap-3 pt-1">
                    <button
                      type="button"
                      phx-click="cancel_variant_form"
                      class="px-4 py-2 text-sm font-semibold text-gray-600 border border-gray-200 rounded-lg hover:bg-gray-50 transition"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      class="px-5 py-2 bg-amber-500 hover:bg-amber-600 text-white font-bold text-sm rounded-lg transition"
                    >
                      Save Variant
                    </button>
                  </div>
                </form>
              </div>
            <% end %>
            
    <!-- ── Variants list ── -->
            <%= if @variants == [] and not @show_variant_form do %>
              <div class="py-12 text-center">
                <svg
                  class="w-10 h-10 text-gray-300 mx-auto mb-3"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="1.5"
                  viewBox="0 0 24 24"
                >
                  <path d="M20 7l-8-4-8 4m16 0v10l-8 4m0-14v14m0 0l-8-4V7" />
                </svg>
                <p class="text-sm text-gray-400 mb-3">No variants yet for this product</p>
                <button
                  phx-click="new_variant"
                  class="text-amber-600 font-semibold text-sm hover:underline"
                >
                  Add your first variant →
                </button>
              </div>
            <% end %>

            <%= if @variants != [] do %>
              <div class="space-y-2">
                <!-- Header row -->
                <div class="grid grid-cols-12 gap-2 px-4 py-2">
                  <p class="col-span-2 text-[10px] font-bold uppercase tracking-widest text-gray-400">
                    Size
                  </p>
                  <p class="col-span-2 text-[10px] font-bold uppercase tracking-widest text-gray-400">
                    SKU
                  </p>
                  <p class="col-span-1 text-[10px] font-bold uppercase tracking-widest text-gray-400">
                    ABV
                  </p>
                  <p class="col-span-2 text-[10px] font-bold uppercase tracking-widest text-gray-400">
                    Price
                  </p>
                  <p class="col-span-2 text-[10px] font-bold uppercase tracking-widest text-gray-400">
                    Compare
                  </p>
                  <p class="col-span-1 text-[10px] font-bold uppercase tracking-widest text-gray-400">
                    Stock
                  </p>
                  <p class="col-span-2 text-[10px] font-bold uppercase tracking-widest text-gray-400 text-right">
                    Actions
                  </p>
                </div>

                <%= for v <- @variants do %>
                  <div class={[
                    "grid grid-cols-12 gap-2 items-center px-4 py-3 rounded-xl border transition",
                    if(v.is_default,
                      do: "bg-amber-50 border-amber-200",
                      else: "bg-white border-gray-200 hover:border-gray-300"
                    )
                  ]}>
                    <div class="col-span-2">
                      <p class="text-sm font-bold text-gray-900">{v.size}</p>
                      <%= if v.is_default do %>
                        <span class="text-[9px] font-black uppercase tracking-widest text-amber-600 bg-amber-100 px-1.5 py-0.5 rounded">
                          Default
                        </span>
                      <% end %>
                    </div>
                    <p class="col-span-2 font-mono text-xs text-gray-400 truncate">{v.sku}</p>
                    <p class="col-span-1 text-sm text-gray-600">
                      {if v.abv, do: "#{v.abv}%", else: "—"}
                    </p>
                    <p class="col-span-2 text-sm font-bold text-gray-900">
                      KSh {Decimal.round(v.price, 2)}
                    </p>
                    <p class="col-span-2 text-sm text-gray-400">
                      {if v.compare_price, do: "KSh #{Decimal.round(v.compare_price, 2)}", else: "—"}
                    </p>
                    <p class={[
                      "col-span-1 text-sm font-bold",
                      cond do
                        v.stock_quantity == 0 -> "text-red-600"
                        v.stock_quantity <= 5 -> "text-amber-600"
                        true -> "text-emerald-600"
                      end
                    ]}>
                      {v.stock_quantity}
                    </p>
                    <div class="col-span-2 flex items-center justify-end gap-2">
                      <%= if not v.is_default do %>
                        <button
                          phx-click="set_default_variant"
                          phx-value-id={v.id}
                          title="Set as default"
                          class="text-xs text-gray-400 hover:text-amber-500 transition"
                        >
                          <svg
                            class="w-4 h-4"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            viewBox="0 0 24 24"
                          >
                            <path d="M11.48 3.499a.562.562 0 011.04 0l2.125 5.111a.563.563 0 00.475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 00-.182.557l1.285 5.385a.562.562 0 01-.84.61l-4.725-2.885a.563.563 0 00-.586 0L6.982 20.54a.562.562 0 01-.84-.61l1.285-5.386a.562.562 0 00-.182-.557l-4.204-3.602a.562.562 0 01.321-.988l5.518-.442a.563.563 0 00.475-.345L11.48 3.5z" />
                          </svg>
                        </button>
                      <% end %>
                      <button
                        phx-click="edit_variant"
                        phx-value-id={v.id}
                        class="text-xs font-semibold text-gray-500 hover:text-amber-600 border border-gray-200 rounded px-2 py-0.5 hover:border-amber-400 transition"
                      >
                        Edit
                      </button>
                      <button
                        phx-click="delete_variant"
                        phx-value-id={v.id}
                        data-confirm="Delete this variant? This cannot be undone."
                        class="text-xs font-semibold text-gray-400 hover:text-red-500 border border-gray-200 rounded px-2 py-0.5 hover:border-red-300 transition"
                      >
                        Del
                      </button>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  # ── Private components ──────────────────────────────────────────────────────

  defp field(assigns) do
    assigns = assign_new(assigns, :placeholder, fn -> "" end)
    assigns = assign_new(assigns, :type, fn -> "text" end)

    ~H"""
    <div>
      <label class="block text-xs font-semibold text-gray-600 mb-1">{@label}</label>
      <%= if @type == "textarea" do %>
        <textarea
          name={"product[#{@field}]"}
          rows="3"
          class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400 resize-none"
        ><%= Phoenix.HTML.Form.input_value(@form, @field) %></textarea>
      <% else %>
        <input
          type={@type}
          name={"product[#{@field}]"}
          value={Phoenix.HTML.Form.input_value(@form, @field)}
          placeholder={@placeholder}
          class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
        />
      <% end %>
      <%= for {msg, _} <- Keyword.get_values(@form.errors || [], @field) do %>
        <p class="text-xs text-red-500 mt-0.5">{msg}</p>
      <% end %>
    </div>
    """
  end

  defp select_field(assigns) do
    ~H"""
    <div>
      <label class="block text-xs font-semibold text-gray-600 mb-1">{@label}</label>
      <select
        name={"product[#{@field}]"}
        class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-amber-400"
      >
        <%= for {label, val} <- @options do %>
          <option
            value={val}
            selected={to_string(Phoenix.HTML.Form.input_value(@form, @field)) == to_string(val)}
          >
            {label}
          </option>
        <% end %>
      </select>
    </div>
    """
  end
end

defmodule LiquorWeb.Admin.BrandsLive do
  use LiquorWeb, :live_view

  alias Liquor.Catalog

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Admin – Brands", current_page: "admin", active_tab: "brands",
                show_modal: false, editing: nil, form: nil)
     |> load_brands(),
     layout: {LiquorWeb.Layouts, :admin}}
  end

  defp load_brands(socket), do: assign(socket, brands: Catalog.list_brands())

  @impl true
  def handle_event("new", _params, socket) do
    form = to_form(Catalog.change_brand(%Catalog.Brand{}), as: :brand)
    {:noreply, assign(socket, show_modal: true, editing: nil, form: form)}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    brand = Catalog.get_brand!(id)
    form  = to_form(Catalog.change_brand(brand), as: :brand)
    {:noreply, assign(socket, show_modal: true, editing: brand, form: form)}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, show_modal: false, editing: nil, form: nil)}
  end

  def handle_event("validate", %{"brand" => params}, socket) do
    brand = socket.assigns.editing || %Catalog.Brand{}
    form  = to_form(Catalog.change_brand(brand, params), as: :brand)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"brand" => params}, socket) do
    result =
      case socket.assigns.editing do
        nil   -> Catalog.create_brand(params)
        brand -> Catalog.update_brand(brand, params)
      end

    case result do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Brand saved.")
         |> assign(show_modal: false, editing: nil, form: nil)
         |> load_brands()}

      {:error, cs} ->
        {:noreply, assign(socket, form: to_form(cs, as: :brand))}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    brand = Catalog.get_brand!(id)
    case Catalog.delete_brand(brand) do
      {:ok, _}    -> {:noreply, socket |> put_flash(:info, "Brand deleted.") |> load_brands()}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Cannot delete – products use this brand.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-screen-xl mx-auto px-4 py-8">
      <div class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-black text-zinc-900">Brands</h1>
        <button phx-click="new" class="bg-amber-500 hover:bg-amber-600 text-white font-bold text-sm px-5 py-2.5 transition uppercase tracking-widest">
          + New Brand
        </button>
      </div>

      <div class="border border-zinc-200 rounded-lg overflow-hidden">
        <table class="w-full text-sm">
          <thead class="bg-zinc-50 border-b border-zinc-200">
            <tr>
              <th class="text-left px-5 py-3 text-xs font-semibold text-zinc-500 uppercase tracking-wide">Brand</th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-zinc-500 uppercase tracking-wide">Slug</th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-zinc-500 uppercase tracking-wide">Country</th>
              <th class="text-right px-5 py-3 text-xs font-semibold text-zinc-500 uppercase tracking-wide">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-zinc-100">
            <%= for brand <- @brands do %>
              <tr class="hover:bg-zinc-50 transition">
                <td class="px-5 py-3 font-semibold text-zinc-800"><%= brand.name %></td>
                <td class="px-5 py-3 font-mono text-xs text-zinc-400"><%= brand.slug %></td>
                <td class="px-5 py-3 text-zinc-600"><%= brand.country || "—" %></td>
                <td class="px-5 py-3 text-right">
                  <div class="flex items-center justify-end gap-2">
                    <button phx-click="edit" phx-value-id={brand.id} class="text-xs font-semibold text-zinc-600 hover:text-amber-600 border border-zinc-200 hover:border-amber-400 rounded px-2 py-1 transition">Edit</button>
                    <button phx-click="delete" phx-value-id={brand.id} data-confirm={"Delete \"#{brand.name}\"?"} class="text-xs font-semibold text-zinc-400 hover:text-red-500 border border-zinc-200 hover:border-red-300 rounded px-2 py-1 transition">Delete</button>
                  </div>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>

    <%= if @show_modal do %>
      <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4">
        <div class="bg-white rounded-lg shadow-xl w-full max-w-md" phx-window-keydown="close_modal" phx-key="Escape">
          <div class="flex items-center justify-between px-6 py-4 border-b border-zinc-200">
            <h2 class="text-lg font-black text-zinc-900"><%= if @editing, do: "Edit Brand", else: "New Brand" %></h2>
            <button phx-click="close_modal" class="text-zinc-400 hover:text-zinc-700">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
            </button>
          </div>
          <form phx-change="validate" phx-submit="save" class="p-6 space-y-4">
            <div>
              <label class="block text-xs font-semibold text-zinc-600 mb-1">Name *</label>
              <input type="text" name="brand[name]" value={Phoenix.HTML.Form.input_value(@form, :name)} class="w-full border border-zinc-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-amber-400" />
            </div>
            <div>
              <label class="block text-xs font-semibold text-zinc-600 mb-1">Slug</label>
              <input type="text" name="brand[slug]" value={Phoenix.HTML.Form.input_value(@form, :slug)} placeholder="auto-generated" class="w-full border border-zinc-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-amber-400" />
            </div>
            <div>
              <label class="block text-xs font-semibold text-zinc-600 mb-1">Country</label>
              <input type="text" name="brand[country]" value={Phoenix.HTML.Form.input_value(@form, :country)} class="w-full border border-zinc-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-amber-400" />
            </div>
            <div>
              <label class="block text-xs font-semibold text-zinc-600 mb-1">Description</label>
              <textarea name="brand[description]" rows="2" class="w-full border border-zinc-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-amber-400 resize-none"><%= Phoenix.HTML.Form.input_value(@form, :description) %></textarea>
            </div>
            <div>
              <label class="block text-xs font-semibold text-zinc-600 mb-1">Logo URL</label>
              <input type="url" name="brand[logo_url]" value={Phoenix.HTML.Form.input_value(@form, :logo_url)} class="w-full border border-zinc-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-amber-400" />
            </div>
            <div class="flex justify-end gap-3 pt-2 border-t border-zinc-100">
              <button type="button" phx-click="close_modal" class="px-4 py-2 text-sm font-semibold text-zinc-600 border border-zinc-200 rounded hover:bg-zinc-50 transition">Cancel</button>
              <button type="submit" class="px-5 py-2 bg-amber-500 hover:bg-amber-600 text-white font-bold text-sm rounded transition uppercase tracking-wide">Save</button>
            </div>
          </form>
        </div>
      </div>
    <% end %>
    """
  end
end

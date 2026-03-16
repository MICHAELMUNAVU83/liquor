defmodule LiquorWeb.Admin.CategoriesLive do
  use LiquorWeb, :live_view

  alias Liquor.Catalog

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Admin – Categories", current_page: "admin", active_tab: "categories",
                show_modal: false, editing: nil, form: nil)
     |> load_categories(),
     layout: {LiquorWeb.Layouts, :admin}}
  end

  defp load_categories(socket), do: assign(socket, categories: Catalog.list_categories())

  @impl true
  def handle_event("new", _params, socket) do
    form = to_form(Catalog.change_category(%Catalog.Category{}), as: :category)
    {:noreply, assign(socket, show_modal: true, editing: nil, form: form)}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    cat  = Catalog.get_category!(id)
    form = to_form(Catalog.change_category(cat), as: :category)
    {:noreply, assign(socket, show_modal: true, editing: cat, form: form)}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, show_modal: false, editing: nil, form: nil)}
  end

  def handle_event("validate", %{"category" => params}, socket) do
    cat  = socket.assigns.editing || %Catalog.Category{}
    form = to_form(Catalog.change_category(cat, params), as: :category)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"category" => params}, socket) do
    result =
      case socket.assigns.editing do
        nil -> Catalog.create_category(params)
        cat -> Catalog.update_category(cat, params)
      end

    case result do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Category saved.")
         |> assign(show_modal: false, editing: nil, form: nil)
         |> load_categories()}

      {:error, cs} ->
        {:noreply, assign(socket, form: to_form(cs, as: :category))}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    cat = Catalog.get_category!(id)
    case Catalog.delete_category(cat) do
      {:ok, _}    -> {:noreply, socket |> put_flash(:info, "Deleted.") |> load_categories()}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Cannot delete – products still use this category.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-screen-xl mx-auto px-4 py-8">
      <div class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-black text-zinc-900">Categories</h1>
        <button phx-click="new" class="bg-amber-500 hover:bg-amber-600 text-white font-bold text-sm px-5 py-2.5 transition uppercase tracking-widest">
          + New Category
        </button>
      </div>

      <div class="border border-zinc-200 rounded-lg overflow-hidden">
        <table class="w-full text-sm">
          <thead class="bg-zinc-50 border-b border-zinc-200">
            <tr>
              <th class="text-left px-5 py-3 text-xs font-semibold text-zinc-500 uppercase tracking-wide">Name</th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-zinc-500 uppercase tracking-wide">Slug</th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-zinc-500 uppercase tracking-wide">Position</th>
              <th class="text-right px-5 py-3 text-xs font-semibold text-zinc-500 uppercase tracking-wide">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-zinc-100">
            <%= for cat <- @categories do %>
              <tr class="hover:bg-zinc-50 transition">
                <td class="px-5 py-3 font-semibold text-zinc-800"><%= cat.name %></td>
                <td class="px-5 py-3 font-mono text-xs text-zinc-400"><%= cat.slug %></td>
                <td class="px-5 py-3 text-zinc-600"><%= cat.position %></td>
                <td class="px-5 py-3 text-right">
                  <div class="flex items-center justify-end gap-2">
                    <button phx-click="edit" phx-value-id={cat.id} class="text-xs font-semibold text-zinc-600 hover:text-amber-600 border border-zinc-200 hover:border-amber-400 rounded px-2 py-1 transition">Edit</button>
                    <button phx-click="delete" phx-value-id={cat.id} data-confirm={"Delete \"#{cat.name}\"?"} class="text-xs font-semibold text-zinc-400 hover:text-red-500 border border-zinc-200 hover:border-red-300 rounded px-2 py-1 transition">Delete</button>
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
            <h2 class="text-lg font-black text-zinc-900"><%= if @editing, do: "Edit Category", else: "New Category" %></h2>
            <button phx-click="close_modal" class="text-zinc-400 hover:text-zinc-700">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
            </button>
          </div>
          <form phx-change="validate" phx-submit="save" class="p-6 space-y-4">
            <div>
              <label class="block text-xs font-semibold text-zinc-600 mb-1">Name *</label>
              <input type="text" name="category[name]" value={Phoenix.HTML.Form.input_value(@form, :name)} class="w-full border border-zinc-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-amber-400" />
            </div>
            <div>
              <label class="block text-xs font-semibold text-zinc-600 mb-1">Slug</label>
              <input type="text" name="category[slug]" value={Phoenix.HTML.Form.input_value(@form, :slug)} placeholder="auto-generated" class="w-full border border-zinc-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-amber-400" />
            </div>
            <div>
              <label class="block text-xs font-semibold text-zinc-600 mb-1">Position</label>
              <input type="number" name="category[position]" value={Phoenix.HTML.Form.input_value(@form, :position)} class="w-full border border-zinc-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-amber-400" />
            </div>
            <div>
              <label class="block text-xs font-semibold text-zinc-600 mb-1">Description</label>
              <textarea name="category[description]" rows="2" class="w-full border border-zinc-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-amber-400 resize-none"><%= Phoenix.HTML.Form.input_value(@form, :description) %></textarea>
            </div>
            <div>
              <label class="block text-xs font-semibold text-zinc-600 mb-1">Image URL</label>
              <input type="url" name="category[image_url]" value={Phoenix.HTML.Form.input_value(@form, :image_url)} class="w-full border border-zinc-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-amber-400" />
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

defmodule LiquorWeb.Admin.UsersLive do
  use LiquorWeb, :live_view

  alias Liquor.Accounts
  alias Liquor.Accounts.{User, Permissions}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: "Admin – System Users",
       active_tab: "users",
       search: "",
       show_modal: false,
       editing: nil,
       form: nil
     )
     |> load_users(), layout: {LiquorWeb.Layouts, :admin}}
  end

  defp load_users(socket) do
    users =
      Accounts.list_users(search: socket.assigns.search)
      |> Enum.filter(&User.admin?/1)

    assign(socket, users: users)
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, socket |> assign(search: q) |> load_users()}
  end

  def handle_event("new_user", _params, socket) do
    form = to_form(Accounts.change_user(%User{}), as: :user)
    {:noreply, assign(socket, show_modal: true, editing: nil, form: form)}
  end

  def handle_event("edit_user", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    changeset = User.admin_changeset(user, %{})
    form = to_form(changeset, as: :user)
    {:noreply, assign(socket, show_modal: true, editing: user, form: form)}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, show_modal: false, editing: nil, form: nil)}
  end

  def handle_event("validate_user", %{"user" => params}, socket) do
    changeset =
      case socket.assigns.editing do
        nil -> User.changeset(%User{}, params)
        user -> User.admin_changeset(user, params)
      end

    {:noreply, assign(socket, form: to_form(changeset, as: :user))}
  end

  def handle_event("save_user", %{"user" => params}, socket) do
    result =
      case socket.assigns.editing do
        nil -> Accounts.create_user(params)
        user -> Accounts.update_user(user, params)
      end

    case result do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "User saved.")
         |> assign(show_modal: false, editing: nil, form: nil)
         |> load_users()}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: :user))}
    end
  end

  def handle_event("toggle_active", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    {:ok, _} = Accounts.update_user(user, %{is_active: !user.is_active})
    {:noreply, socket |> put_flash(:info, "User updated.") |> load_users()}
  end

  def handle_event("delete_user", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    {:ok, _} = Accounts.delete_user(user)
    {:noreply, socket |> put_flash(:info, "User deleted.") |> load_users()}
  end

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-screen-xl mx-auto px-4 py-8">
      <!-- Header -->
      <div class="flex items-center justify-between mb-6 flex-wrap gap-3">
        <div>
          <h1 class="text-2xl font-black text-gray-900">System Users</h1>
          <p class="text-sm text-gray-500">Admin accounts with access to this panel</p>
        </div>
        <button
          phx-click="new_user"
          class="bg-amber-500 hover:bg-amber-600 text-white font-bold text-sm px-5 py-2.5 rounded-lg transition uppercase tracking-widest"
        >
          + Add User
        </button>
      </div>

      <!-- Search -->
      <form phx-change="search" class="mb-6">
        <input
          type="text"
          name="q"
          value={@search}
          placeholder="Search by name or email…"
          class="w-full max-w-sm border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
        />
      </form>

      <!-- Table -->
      <div class="bg-white border border-gray-200 rounded-xl overflow-hidden">
        <table class="w-full text-sm">
          <thead class="bg-gray-50 border-b border-gray-200">
            <tr>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">User</th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Email</th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Phone</th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Role</th>
              <th class="text-center px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Active</th>
              <th class="text-right px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <%= for user <- @users do %>
              <tr class="hover:bg-gray-50 transition">
                <td class="px-5 py-3">
                  <div class="flex items-center gap-3">
                    <div class="w-8 h-8 rounded-full bg-amber-500 flex items-center justify-center text-white font-black text-sm shrink-0">
                      {String.first(user.first_name || user.email)}
                    </div>
                    <p class="font-semibold text-gray-900">{user.first_name} {user.last_name}</p>
                  </div>
                </td>
                <td class="px-5 py-3 text-gray-600">{user.email}</td>
                <td class="px-5 py-3 text-gray-500">{user.phone || "—"}</td>
                <td class="px-5 py-3">
                  <span class={"inline-block text-xs font-bold px-2 py-0.5 rounded #{Permissions.role_badge_class(user.role)}"}>
                    {Permissions.role_label(user.role)}
                  </span>
                </td>
                <td class="px-5 py-3 text-center">
                  <button
                    phx-click="toggle_active"
                    phx-value-id={user.id}
                    class={[
                      "relative inline-flex h-5 w-9 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200",
                      if(user.is_active, do: "bg-emerald-500", else: "bg-gray-300")
                    ]}
                  >
                    <span class={[
                      "inline-block h-4 w-4 transform rounded-full bg-white shadow transition duration-200",
                      if(user.is_active, do: "translate-x-4", else: "translate-x-0")
                    ]}></span>
                  </button>
                </td>
                <td class="px-5 py-3 text-right">
                  <div class="flex items-center justify-end gap-2">
                    <button
                      phx-click="edit_user"
                      phx-value-id={user.id}
                      class="text-xs font-semibold text-gray-600 hover:text-amber-600 transition px-2 py-1 border border-gray-200 rounded-lg hover:border-amber-400"
                    >
                      Edit
                    </button>
                    <button
                      phx-click="delete_user"
                      phx-value-id={user.id}
                      data-confirm={"Delete #{user.email}? This cannot be undone."}
                      class="text-xs font-semibold text-gray-400 hover:text-red-500 transition px-2 py-1 border border-gray-200 rounded-lg hover:border-red-300"
                    >
                      Delete
                    </button>
                  </div>
                </td>
              </tr>
            <% end %>
            <%= if @users == [] do %>
              <tr>
                <td colspan="6" class="px-5 py-12 text-center text-sm text-gray-400">
                  No admin users found.
                  <button phx-click="new_user" class="text-amber-600 font-semibold hover:underline ml-1">Add one?</button>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Modal -->
    <%= if @show_modal do %>
      <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
        <div
          class="bg-white rounded-xl shadow-2xl w-full max-w-md"
          phx-window-keydown="close_modal"
          phx-key="Escape"
        >
          <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200">
            <h2 class="text-lg font-black text-gray-900">
              {if @editing, do: "Edit User", else: "New Admin User"}
            </h2>
            <button phx-click="close_modal" class="text-gray-400 hover:text-gray-700">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <form phx-change="validate_user" phx-submit="save_user" class="p-6 space-y-4">
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-xs font-semibold text-gray-600 mb-1">First Name</label>
                <input type="text" name="user[first_name]" value={Phoenix.HTML.Form.input_value(@form, :first_name)} class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400" />
              </div>
              <div>
                <label class="block text-xs font-semibold text-gray-600 mb-1">Last Name</label>
                <input type="text" name="user[last_name]" value={Phoenix.HTML.Form.input_value(@form, :last_name)} class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400" />
              </div>
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-600 mb-1">Email *</label>
              <input type="email" name="user[email]" value={Phoenix.HTML.Form.input_value(@form, :email)} class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400" />
              <%= for {msg, _} <- Keyword.get_values(@form.errors || [], :email) do %>
                <p class="text-xs text-red-500 mt-0.5">{msg}</p>
              <% end %>
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-600 mb-1">Phone</label>
              <input type="text" name="user[phone]" value={Phoenix.HTML.Form.input_value(@form, :phone)} placeholder="+254…" class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400" />
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-600 mb-1">Role *</label>
              <select name="user[role]" class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400">
                <option value="">— Select role —</option>
                <%= for role <- Permissions.roles() do %>
                  <option value={role} selected={Phoenix.HTML.Form.input_value(@form, :role) == role}>
                    {Permissions.role_label(role)}
                  </option>
                <% end %>
              </select>
              <%= for {msg, _} <- Keyword.get_values(@form.errors || [], :role) do %>
                <p class="text-xs text-red-500 mt-0.5">{msg}</p>
              <% end %>
              <p class="text-xs text-gray-400 mt-1">
                Super Admin: full access · Manager: no users/settings · Cashier: orders &amp; customers · Inventory Clerk: products &amp; stock
              </p>
            </div>
            <%= if is_nil(@editing) do %>
              <div>
                <label class="block text-xs font-semibold text-gray-600 mb-1">Password *</label>
                <input type="password" name="user[password]" placeholder="Min 6 characters" class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400" />
                <%= for {msg, _} <- Keyword.get_values(@form.errors || [], :password) do %>
                  <p class="text-xs text-red-500 mt-0.5">{msg}</p>
                <% end %>
              </div>
            <% end %>

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
                Save
              </button>
            </div>
          </form>
        </div>
      </div>
    <% end %>
    """
  end
end

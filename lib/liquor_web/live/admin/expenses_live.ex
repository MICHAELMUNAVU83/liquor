defmodule LiquorWeb.Admin.ExpensesLive do
  use LiquorWeb, :live_view

  alias Liquor.Expenses
  alias Liquor.Expenses.Expense

  @categories ["" | Expense.categories()]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title:       "Admin – Expenses",
       active_tab:       "expenses",
       category_filter:  "",
       search:           "",
       show_form:        false,
       form_changeset:   new_changeset()
     )
     |> load_expenses(),
     layout: {LiquorWeb.Layouts, :admin}}
  end

  defp load_expenses(socket) do
    expenses      = Expenses.list_expenses(category: socket.assigns.category_filter, search: socket.assigns.search)
    total         = Expenses.total_expenses()
    this_month    = Expenses.expenses_this_month()
    by_category   = Expenses.total_by_category()
    assign(socket, expenses: expenses, total: total, this_month: this_month, by_category: by_category)
  end

  defp new_changeset(attrs \\ %{}) do
    Expense.changeset(%Expense{expense_date: Date.utc_today()}, attrs)
  end

  @impl true
  def handle_event("filter_category", %{"category" => cat}, socket) do
    {:noreply, socket |> assign(category_filter: cat) |> load_expenses()}
  end

  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, socket |> assign(search: q) |> load_expenses()}
  end

  def handle_event("show_form", _params, socket) do
    {:noreply, assign(socket, show_form: true, form_changeset: new_changeset())}
  end

  def handle_event("close_form", _params, socket) do
    {:noreply, assign(socket, show_form: false)}
  end

  def handle_event("save_expense", %{"expense" => params}, socket) do
    case Expenses.create_expense(params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Expense recorded.")
         |> assign(show_form: false)
         |> load_expenses()}

      {:error, changeset} ->
        {:noreply, assign(socket, form_changeset: changeset)}
    end
  end

  def handle_event("delete_expense", %{"id" => id}, socket) do
    expense = Expenses.get_expense!(id)
    {:ok, _} = Expenses.delete_expense(expense)
    {:noreply, socket |> put_flash(:info, "Expense deleted.") |> load_expenses()}
  end

  defp category_label("stock_restock"), do: "Stock Restock"
  defp category_label("utilities"),     do: "Utilities"
  defp category_label("wages"),         do: "Wages"
  defp category_label("rent"),          do: "Rent"
  defp category_label("maintenance"),   do: "Maintenance"
  defp category_label("other"),         do: "Other"
  defp category_label(""),              do: "All"
  defp category_label(c),               do: String.capitalize(c)

  defp category_color("stock_restock"), do: "bg-blue-100 text-blue-700"
  defp category_color("utilities"),     do: "bg-purple-100 text-purple-700"
  defp category_color("wages"),         do: "bg-emerald-100 text-emerald-700"
  defp category_color("rent"),          do: "bg-orange-100 text-orange-700"
  defp category_color("maintenance"),   do: "bg-amber-100 text-amber-700"
  defp category_color(_),               do: "bg-gray-100 text-gray-600"

  @impl true
  def render(assigns) do
    categories = @categories
    assigns = assign(assigns, :categories, categories)

    ~H"""
    <div class="max-w-screen-xl mx-auto px-4 py-8">

      <!-- Header -->
      <div class="flex items-center justify-between mb-6 flex-wrap gap-3">
        <div>
          <h1 class="text-2xl font-black text-gray-900">Expenses</h1>
          <p class="text-sm text-gray-500 mt-0.5">Track all business expenses</p>
        </div>
        <button
          phx-click="show_form"
          class="bg-amber-500 hover:bg-amber-600 text-white font-bold text-sm px-5 py-2.5 rounded-lg transition uppercase tracking-widest"
        >
          + Add Expense
        </button>
      </div>

      <!-- Summary cards -->
      <div class="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-6">
        <div class="bg-white border border-gray-200 rounded-xl p-4">
          <p class="text-2xl font-black text-gray-900"><%= length(@expenses) %></p>
          <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide mt-0.5">Records</p>
        </div>
        <div class="bg-red-50 border border-red-200 rounded-xl p-4">
          <p class="text-xl font-black text-red-700">KSh <%= Decimal.round(@total || Decimal.new("0"), 2) %></p>
          <p class="text-xs font-semibold text-red-600 uppercase tracking-wide mt-0.5">Total</p>
        </div>
        <div class="bg-amber-50 border border-amber-200 rounded-xl p-4">
          <p class="text-xl font-black text-amber-700">KSh <%= Decimal.round(@this_month || Decimal.new("0"), 2) %></p>
          <p class="text-xs font-semibold text-amber-600 uppercase tracking-wide mt-0.5">This Month</p>
        </div>
        <div class="bg-blue-50 border border-blue-200 rounded-xl p-4">
          <p class="text-xl font-black text-blue-700">
            KSh <%= Decimal.round(Map.get(@by_category, "stock_restock") || Decimal.new("0"), 2) %>
          </p>
          <p class="text-xs font-semibold text-blue-600 uppercase tracking-wide mt-0.5">Stock Restock</p>
        </div>
      </div>

      <!-- By-category breakdown -->
      <%= if map_size(@by_category) > 0 do %>
        <div class="bg-white border border-gray-200 rounded-xl p-5 mb-6">
          <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-3">Breakdown by Category</p>
          <div class="flex flex-wrap gap-3">
            <%= for {cat, amt} <- @by_category do %>
              <div class="flex items-center gap-2 bg-gray-50 rounded-lg px-3 py-2">
                <span class={["text-[10px] font-bold uppercase tracking-wide px-2 py-0.5 rounded", category_color(cat)]}>
                  <%= category_label(cat) %>
                </span>
                <span class="font-bold text-gray-800 text-sm">KSh <%= Decimal.round(amt, 2) %></span>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>

      <!-- Filters -->
      <div class="flex flex-wrap items-center gap-3 mb-4">
        <input
          type="text"
          placeholder="Search expenses…"
          value={@search}
          phx-keyup="search"
          name="q"
          class="border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400 w-64"
        />
        <div class="flex gap-1 flex-wrap">
          <%= for cat <- @categories do %>
            <button
              phx-click="filter_category"
              phx-value-category={cat}
              class={[
                "text-xs font-semibold px-3 py-1.5 rounded-lg border transition",
                if(@category_filter == cat,
                  do: "bg-amber-500 text-white border-amber-500",
                  else: "border-gray-200 text-gray-600 hover:border-gray-300 bg-white")
              ]}
            >
              <%= category_label(cat) %>
            </button>
          <% end %>
        </div>
      </div>

      <!-- Table -->
      <div class="bg-white border border-gray-200 rounded-xl overflow-hidden">
        <table class="w-full text-sm">
          <thead class="bg-gray-50 border-b border-gray-200">
            <tr>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Date</th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Description</th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Category</th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Details</th>
              <th class="text-right px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Amount</th>
              <th class="px-5 py-3"></th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <%= for exp <- @expenses do %>
              <tr class="hover:bg-gray-50 transition">
                <td class="px-5 py-3 text-gray-400 text-xs font-medium">
                  <%= Calendar.strftime(exp.expense_date, "%b %d, %Y") %>
                </td>
                <td class="px-5 py-3">
                  <p class="font-semibold text-gray-800"><%= exp.description %></p>
                  <%= if exp.notes do %>
                    <p class="text-xs text-gray-400 mt-0.5"><%= exp.notes %></p>
                  <% end %>
                </td>
                <td class="px-5 py-3">
                  <span class={["text-[10px] font-bold uppercase tracking-wide px-2 py-0.5 rounded", category_color(exp.category)]}>
                    <%= category_label(exp.category) %>
                  </span>
                </td>
                <td class="px-5 py-3 text-xs text-gray-500">
                  <%= if exp.category == "stock_restock" and exp.product_name do %>
                    <p class="font-medium text-gray-700"><%= exp.product_name %></p>
                    <%= if exp.variant_sku do %>
                      <p class="font-mono text-gray-400"><%= exp.variant_sku %></p>
                    <% end %>
                    <%= if exp.quantity do %>
                      <p><%= exp.quantity %> units
                        <%= if exp.unit_cost do %>@ KSh <%= Decimal.round(exp.unit_cost, 2) %> each<% end %>
                      </p>
                    <% end %>
                  <% else %>
                    —
                  <% end %>
                </td>
                <td class="px-5 py-3 text-right font-bold text-gray-900">
                  KSh <%= Decimal.round(exp.amount, 2) %>
                </td>
                <td class="px-5 py-3 text-right">
                  <button
                    phx-click="delete_expense"
                    phx-value-id={exp.id}
                    data-confirm="Delete this expense?"
                    class="text-xs font-semibold text-red-400 hover:text-red-600 hover:underline"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            <% end %>
            <%= if @expenses == [] do %>
              <tr><td colspan="6" class="px-5 py-12 text-center text-sm text-gray-400">No expenses found</td></tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Add Expense Modal -->
    <%= if @show_form do %>
      <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
        <div
          class="bg-white rounded-xl shadow-2xl w-full max-w-lg"
          phx-window-keydown="close_form"
          phx-key="Escape"
        >
          <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200">
            <h2 class="text-lg font-black text-gray-900">Add Expense</h2>
            <button phx-click="close_form" class="text-gray-400 hover:text-gray-700">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
              </svg>
            </button>
          </div>
          <.form for={@form_changeset} phx-submit="save_expense" class="p-6 space-y-4">
            <div>
              <label class="block text-xs font-semibold text-gray-600 mb-1">Description *</label>
              <input
                type="text"
                name="expense[description]"
                value={Ecto.Changeset.get_field(@form_changeset, :description) || ""}
                placeholder="e.g. Office supplies, Delivery fee…"
                class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
              />
            </div>
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-xs font-semibold text-gray-600 mb-1">Category *</label>
                <select
                  name="expense[category]"
                  class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-amber-400"
                >
                  <%= for cat <- tl(@categories) do %>
                    <option value={cat}><%= category_label(cat) %></option>
                  <% end %>
                </select>
              </div>
              <div>
                <label class="block text-xs font-semibold text-gray-600 mb-1">Date *</label>
                <input
                  type="date"
                  name="expense[expense_date]"
                  value={to_string(Ecto.Changeset.get_field(@form_changeset, :expense_date) || Date.utc_today())}
                  class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
                />
              </div>
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-600 mb-1">Amount (KSh) *</label>
              <input
                type="number"
                step="0.01"
                min="0"
                name="expense[amount]"
                value={Ecto.Changeset.get_field(@form_changeset, :amount) || ""}
                placeholder="0.00"
                class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
              />
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-600 mb-1">Notes (optional)</label>
              <textarea
                name="expense[notes]"
                rows="2"
                class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
              ><%= Ecto.Changeset.get_field(@form_changeset, :notes) || "" %></textarea>
            </div>
            <%= if @form_changeset.errors != [] do %>
              <div class="bg-red-50 border border-red-200 rounded-lg p-3 text-sm text-red-700">
                <%= for {field, {msg, _}} <- @form_changeset.errors do %>
                  <p><%= Phoenix.Naming.humanize(field) %>: <%= msg %></p>
                <% end %>
              </div>
            <% end %>
            <div class="flex justify-end gap-3 pt-2">
              <button type="button" phx-click="close_form"
                class="px-4 py-2 text-sm font-semibold text-gray-600 border border-gray-200 rounded-lg hover:bg-gray-50 transition">
                Cancel
              </button>
              <button type="submit"
                class="px-5 py-2 text-sm font-bold bg-amber-500 text-white rounded-lg hover:bg-amber-600 transition">
                Save Expense
              </button>
            </div>
          </.form>
        </div>
      </div>
    <% end %>
    """
  end
end

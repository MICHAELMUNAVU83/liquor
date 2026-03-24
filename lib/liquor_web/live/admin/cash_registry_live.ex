defmodule LiquorWeb.Admin.CashRegistryLive do
  use LiquorWeb, :live_view

  alias Liquor.Cash
  alias Liquor.Cash.{CashRegister, CashRegisterExpense}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: "Admin – Cash Registry",
       active_tab: "cash_registry",
       view: :list,
       selected_register: nil,
       show_open_modal: false,
       show_close_modal: false,
       show_expense_modal: false,
       open_form: nil,
       close_form: nil,
       expense_form: nil
     )
     |> load_registers(), layout: {LiquorWeb.Layouts, :admin}}
  end

  defp load_registers(socket) do
    assign(socket, registers: Cash.list_registers())
  end

  defp load_selected(socket) do
    case socket.assigns.selected_register do
      nil -> socket
      reg -> assign(socket, selected_register: Cash.get_register!(reg.id))
    end
  end

  # ---------------------------------------------------------------------------
  # Events
  # ---------------------------------------------------------------------------

  @impl true
  def handle_event("open_register_modal", _params, socket) do
    form = to_form(Ecto.Changeset.change(%CashRegister{}), as: :register)
    {:noreply, assign(socket, show_open_modal: true, open_form: form)}
  end

  def handle_event("close_open_modal", _params, socket) do
    {:noreply, assign(socket, show_open_modal: false, open_form: nil)}
  end

  def handle_event("validate_open", %{"register" => params}, socket) do
    form =
      %CashRegister{}
      |> CashRegister.open_changeset(params)
      |> Map.put(:action, :validate)
      |> then(&to_form(&1, as: :register))

    {:noreply, assign(socket, open_form: form)}
  end

  def handle_event("save_open", %{"register" => params}, socket) do
    user_id = socket.assigns.current_user.id

    case Cash.open_register(params, user_id) do
      {:ok, _register} ->
        {:noreply,
         socket
         |> put_flash(:info, "Cash register opened.")
         |> assign(show_open_modal: false, open_form: nil)
         |> load_registers()}

      {:error, :already_open} ->
        {:noreply, put_flash(socket, :error, "There is already an open cash register. Close it first.")}

      {:error, changeset} ->
        {:noreply, assign(socket, open_form: to_form(changeset, as: :register))}
    end
  end

  def handle_event("view_register", %{"id" => id}, socket) do
    register = Cash.get_register!(id)
    {:noreply, assign(socket, view: :detail, selected_register: register)}
  end

  def handle_event("back_to_list", _params, socket) do
    {:noreply, socket |> assign(view: :list, selected_register: nil) |> load_registers()}
  end

  def handle_event("close_register_modal", _params, socket) do
    form = to_form(Ecto.Changeset.change(%CashRegister{}), as: :close)
    {:noreply, assign(socket, show_close_modal: true, close_form: form)}
  end

  def handle_event("cancel_close_modal", _params, socket) do
    {:noreply, assign(socket, show_close_modal: false, close_form: nil)}
  end

  def handle_event("save_close", %{"close" => params}, socket) do
    register = socket.assigns.selected_register
    close_amount = params["close_amount"]
    notes = params["notes"]

    case Cash.close_register(register, close_amount, notes) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Cash register closed.")
         |> assign(show_close_modal: false, close_form: nil)
         |> load_selected()}

      {:error, changeset} ->
        {:noreply, assign(socket, close_form: to_form(changeset, as: :close))}
    end
  end

  def handle_event("add_expense_modal", _params, socket) do
    form = to_form(Ecto.Changeset.change(%CashRegisterExpense{}), as: :expense)
    {:noreply, assign(socket, show_expense_modal: true, expense_form: form)}
  end

  def handle_event("cancel_expense_modal", _params, socket) do
    {:noreply, assign(socket, show_expense_modal: false, expense_form: nil)}
  end

  def handle_event("validate_expense", %{"expense" => params}, socket) do
    form =
      %CashRegisterExpense{}
      |> CashRegisterExpense.changeset(Map.put(params, "cash_register_id", socket.assigns.selected_register.id))
      |> Map.put(:action, :validate)
      |> then(&to_form(&1, as: :expense))

    {:noreply, assign(socket, expense_form: form)}
  end

  def handle_event("save_expense", %{"expense" => params}, socket) do
    register = socket.assigns.selected_register

    case Cash.add_expense(register, params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Expense added.")
         |> assign(show_expense_modal: false, expense_form: nil)
         |> load_selected()}

      {:error, changeset} ->
        {:noreply, assign(socket, expense_form: to_form(changeset, as: :expense))}
    end
  end

  def handle_event("delete_expense", %{"id" => id}, socket) do
    expense = Cash.get_expense!(id)
    {:ok, _} = Cash.delete_expense(expense)

    {:noreply,
     socket
     |> put_flash(:info, "Expense removed.")
     |> load_selected()}
  end

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  # ---------------------------------------------------------------------------
  # Render
  # ---------------------------------------------------------------------------

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-screen-xl mx-auto px-4 py-8">
      <%= if @view == :list do %>
        <%= render_list(assigns) %>
      <% else %>
        <%= render_detail(assigns) %>
      <% end %>
    </div>

    <%= if @show_open_modal, do: render_open_modal(assigns) %>
    <%= if @show_close_modal, do: render_close_modal(assigns) %>
    <%= if @show_expense_modal, do: render_expense_modal(assigns) %>
    """
  end

  defp render_list(assigns) do
    ~H"""
    <div class="flex items-center justify-between mb-6 flex-wrap gap-3">
      <div>
        <h1 class="text-2xl font-black text-gray-900">Cash Registry</h1>
        <p class="text-sm text-gray-500">Daily cash register sessions</p>
      </div>
      <button
        phx-click="open_register_modal"
        class="bg-amber-500 hover:bg-amber-600 text-white font-bold text-sm px-5 py-2.5 rounded-lg transition uppercase tracking-widest"
      >
        + Open Register
      </button>
    </div>

    <%= if Enum.empty?(@registers) do %>
      <div class="text-center py-20 text-gray-400">
        <svg class="w-12 h-12 mx-auto mb-3 text-gray-300" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 18.75a60.07 60.07 0 0115.797 2.101c.727.198 1.453-.342 1.453-1.096V18.75M3.75 4.5v.75A.75.75 0 013 6h-.75m0 0v-.375c0-.621.504-1.125 1.125-1.125H20.25M2.25 6v9m18-10.5v.75c0 .414.336.75.75.75h.75m-1.5-1.5h.375c.621 0 1.125.504 1.125 1.125v9.75c0 .621-.504 1.125-1.125 1.125h-.375m1.5-1.5H21a.75.75 0 01-.75.75v.75m0 0H3.75m0 0h-.375a1.125 1.125 0 01-1.125-1.125V15m1.5 1.5v-.75A.75.75 0 003 15h-.75"/>
        </svg>
        <p class="font-semibold">No cash registers yet</p>
        <button phx-click="open_register_modal" class="mt-2 text-amber-600 font-semibold hover:underline text-sm">Open today's register</button>
      </div>
    <% else %>
      <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <%= for reg <- @registers do %>
          <% summary = Cash.summary(reg) %>
          <div
            class="bg-white border border-gray-200 rounded-xl p-5 hover:shadow-md transition cursor-pointer"
            phx-click="view_register"
            phx-value-id={reg.id}
          >
            <div class="flex items-center justify-between mb-3">
              <span class={["text-xs font-bold px-2 py-0.5 rounded",
                if(reg.status == "open", do: "bg-emerald-100 text-emerald-700", else: "bg-gray-100 text-gray-500")]}>
                {String.upcase(reg.status)}
              </span>
              <span class="text-xs text-gray-400">{format_datetime(reg.opened_at)}</span>
            </div>

            <div class="space-y-2 text-sm">
              <div class="flex justify-between">
                <span class="text-gray-500">Opening Balance</span>
                <span class="font-semibold">KES {Decimal.round(summary.open_amount, 2)}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-500">Cash Sales</span>
                <span class="font-semibold text-emerald-600">+ KES {Decimal.round(summary.cash_sales, 2)}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-500">Expenses</span>
                <span class="font-semibold text-red-500">- KES {Decimal.round(summary.total_expenses, 2)}</span>
              </div>
              <div class="flex justify-between border-t border-gray-100 pt-2 mt-2">
                <span class="text-gray-700 font-semibold">Expected</span>
                <span class="font-black text-gray-900">KES {Decimal.round(summary.expected_close, 2)}</span>
              </div>
              <%= if reg.status == "closed" && reg.close_amount do %>
                <div class="flex justify-between">
                  <span class="text-gray-500">Actual Close</span>
                  <span class="font-semibold">KES {Decimal.round(reg.close_amount, 2)}</span>
                </div>
              <% end %>
            </div>

            <%= if reg.opened_by do %>
              <p class="text-xs text-gray-400 mt-3">Opened by {reg.opened_by.first_name} {reg.opened_by.last_name}</p>
            <% end %>
          </div>
        <% end %>
      </div>
    <% end %>
    """
  end

  defp render_detail(assigns) do
    ~H"""
    <% reg = @selected_register %>
    <% summary = Cash.summary(reg) %>

    <div class="flex items-center gap-3 mb-6">
      <button phx-click="back_to_list" class="text-gray-400 hover:text-gray-700 transition">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7"/>
        </svg>
      </button>
      <div class="flex-1">
        <h1 class="text-2xl font-black text-gray-900">
          Cash Register – {format_datetime(reg.opened_at)}
        </h1>
        <p class="text-sm text-gray-400">
          Opened by {if reg.opened_by, do: "#{reg.opened_by.first_name} #{reg.opened_by.last_name}", else: "—"}
          <%= if reg.closed_at, do: " · Closed #{format_datetime(reg.closed_at)}" %>
        </p>
      </div>
      <span class={["text-xs font-bold px-2.5 py-1 rounded",
        if(reg.status == "open", do: "bg-emerald-100 text-emerald-700", else: "bg-gray-100 text-gray-500")]}>
        {String.upcase(reg.status)}
      </span>
      <%= if reg.status == "open" do %>
        <button
          phx-click="close_register_modal"
          class="bg-gray-800 hover:bg-gray-900 text-white font-bold text-sm px-4 py-2 rounded-lg transition"
        >
          Close Register
        </button>
      <% end %>
    </div>

    <!-- Summary cards -->
    <div class="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-8">
      <div class="bg-white border border-gray-200 rounded-xl p-4 text-center">
        <p class="text-xs text-gray-400 font-semibold uppercase tracking-wide mb-1">Opening Balance</p>
        <p class="text-xl font-black text-gray-900">KES {Decimal.round(summary.open_amount, 2)}</p>
      </div>
      <div class="bg-white border border-emerald-200 rounded-xl p-4 text-center">
        <p class="text-xs text-emerald-600 font-semibold uppercase tracking-wide mb-1">Cash Sales</p>
        <p class="text-xl font-black text-emerald-600">KES {Decimal.round(summary.cash_sales, 2)}</p>
      </div>
      <div class="bg-white border border-red-200 rounded-xl p-4 text-center">
        <p class="text-xs text-red-500 font-semibold uppercase tracking-wide mb-1">Expenses</p>
        <p class="text-xl font-black text-red-500">KES {Decimal.round(summary.total_expenses, 2)}</p>
      </div>
      <div class="bg-white border border-amber-300 rounded-xl p-4 text-center">
        <p class="text-xs text-amber-600 font-semibold uppercase tracking-wide mb-1">Expected Close</p>
        <p class="text-xl font-black text-amber-600">KES {Decimal.round(summary.expected_close, 2)}</p>
        <%= if reg.close_amount do %>
          <p class="text-xs text-gray-400 mt-0.5">Actual: KES {Decimal.round(reg.close_amount, 2)}</p>
        <% end %>
      </div>
    </div>

    <div class="grid lg:grid-cols-2 gap-6">

      <!-- Cash Sales section -->
      <div class="bg-white border border-gray-200 rounded-xl overflow-hidden">
        <div class="flex items-center justify-between px-5 py-4 border-b border-gray-100">
          <h2 class="font-black text-gray-900">Cash Sales</h2>
          <span class="text-xs font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded">
            {length(reg.orders)} sale{if length(reg.orders) != 1, do: "s"}
          </span>
        </div>
        <table class="w-full text-sm">
          <thead class="bg-gray-50 border-b border-gray-100">
            <tr>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Order</th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Customer</th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Time</th>
              <th class="text-right px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Amount</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <%= for order <- reg.orders do %>
              <tr class="hover:bg-gray-50">
                <td class="px-5 py-3 font-mono text-xs text-gray-500">#<%= order.id %></td>
                <td class="px-5 py-3 text-gray-700 font-medium">{order.shipping_name || "Walk-in"}</td>
                <td class="px-5 py-3 text-gray-400 text-xs">{format_datetime(order.inserted_at)}</td>
                <td class="px-5 py-3 text-right font-semibold text-emerald-600">KES {Decimal.round(order.total_amount, 2)}</td>
              </tr>
            <% end %>
            <%= if reg.orders == [] do %>
              <tr>
                <td colspan="4" class="px-5 py-8 text-center text-sm text-gray-400">No cash sales recorded yet.</td>
              </tr>
            <% end %>
          </tbody>
          <%= if reg.orders != [] do %>
            <tfoot class="bg-gray-50 border-t border-gray-200">
              <tr>
                <td colspan="3" class="px-5 py-3 text-xs font-bold text-gray-500 uppercase">Total</td>
                <td class="px-5 py-3 text-right font-black text-emerald-600">KES {Decimal.round(summary.cash_sales, 2)}</td>
              </tr>
            </tfoot>
          <% end %>
        </table>
      </div>

      <!-- Expenses section -->
      <div class="bg-white border border-gray-200 rounded-xl overflow-hidden">
        <div class="flex items-center justify-between px-5 py-4 border-b border-gray-100">
          <h2 class="font-black text-gray-900">Cash Expenses</h2>
          <%= if reg.status == "open" do %>
            <button
              phx-click="add_expense_modal"
              class="text-sm font-bold text-amber-600 hover:text-amber-700 border border-amber-300 hover:border-amber-500 px-3 py-1.5 rounded-lg transition"
            >
              + Add Expense
            </button>
          <% end %>
        </div>
        <table class="w-full text-sm">
          <thead class="bg-gray-50 border-b border-gray-100">
            <tr>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Description</th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Time</th>
              <th class="text-right px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Amount</th>
              <%= if reg.status == "open" do %>
                <th class="px-5 py-3"></th>
              <% end %>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <%= for exp <- reg.expenses do %>
              <tr class="hover:bg-gray-50">
                <td class="px-5 py-3">
                  <p class="font-medium text-gray-900">{exp.description}</p>
                  <%= if exp.notes do %><p class="text-xs text-gray-400 mt-0.5">{exp.notes}</p><% end %>
                </td>
                <td class="px-5 py-3 text-gray-400 text-xs">{format_datetime(exp.inserted_at)}</td>
                <td class="px-5 py-3 text-right font-semibold text-red-500">KES {Decimal.round(exp.amount, 2)}</td>
                <%= if reg.status == "open" do %>
                  <td class="px-5 py-3 text-right">
                    <button
                      phx-click="delete_expense"
                      phx-value-id={exp.id}
                      data-confirm="Remove this expense?"
                      class="text-xs text-gray-400 hover:text-red-500 transition"
                    >
                      Remove
                    </button>
                  </td>
                <% end %>
              </tr>
            <% end %>
            <%= if reg.expenses == [] do %>
              <tr>
                <td colspan="4" class="px-5 py-8 text-center text-sm text-gray-400">No expenses recorded for this session.</td>
              </tr>
            <% end %>
          </tbody>
          <%= if reg.expenses != [] do %>
            <tfoot class="bg-gray-50 border-t border-gray-200">
              <tr>
                <td colspan="2" class="px-5 py-3 text-xs font-bold text-gray-500 uppercase">Total</td>
                <td class="px-5 py-3 text-right font-black text-red-500">KES {Decimal.round(summary.total_expenses, 2)}</td>
                <%= if reg.status == "open" do %><td></td><% end %>
              </tr>
            </tfoot>
          <% end %>
        </table>
      </div>

    </div>
    """
  end

  defp render_open_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
      <div class="bg-white rounded-xl shadow-2xl w-full max-w-sm" phx-window-keydown="close_open_modal" phx-key="Escape">
        <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200">
          <h2 class="text-lg font-black text-gray-900">Open Cash Register</h2>
          <button phx-click="close_open_modal" class="text-gray-400 hover:text-gray-700">
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
            </svg>
          </button>
        </div>
        <form phx-change="validate_open" phx-submit="save_open" class="p-6 space-y-4">
          <div>
            <label class="block text-xs font-semibold text-gray-600 mb-1">Opening Cash Amount (KES) *</label>
            <input
              type="number"
              step="0.01"
              name="register[open_amount]"
              value={Phoenix.HTML.Form.input_value(@open_form, :open_amount)}
              placeholder="0.00"
              class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
            />
            <%= for {msg, _} <- Keyword.get_values(@open_form.errors || [], :open_amount) do %>
              <p class="text-xs text-red-500 mt-0.5">{msg}</p>
            <% end %>
          </div>
          <div>
            <label class="block text-xs font-semibold text-gray-600 mb-1">Notes</label>
            <input
              type="text"
              name="register[notes]"
              value={Phoenix.HTML.Form.input_value(@open_form, :notes)}
              placeholder="Optional note…"
              class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
            />
          </div>
          <div class="flex justify-end gap-3 pt-2 border-t border-gray-100">
            <button type="button" phx-click="close_open_modal" class="px-4 py-2 text-sm font-semibold text-gray-600 hover:text-gray-900 border border-gray-200 rounded-lg transition">Cancel</button>
            <button type="submit" class="px-5 py-2 bg-amber-500 hover:bg-amber-600 text-white font-bold text-sm rounded-lg transition uppercase tracking-wide">Open Register</button>
          </div>
        </form>
      </div>
    </div>
    """
  end

  defp render_close_modal(assigns) do
    ~H"""
    <% summary = Cash.summary(@selected_register) %>
    <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
      <div class="bg-white rounded-xl shadow-2xl w-full max-w-sm" phx-window-keydown="cancel_close_modal" phx-key="Escape">
        <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200">
          <h2 class="text-lg font-black text-gray-900">Close Cash Register</h2>
          <button phx-click="cancel_close_modal" class="text-gray-400 hover:text-gray-700">
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
            </svg>
          </button>
        </div>
        <div class="px-6 py-4 bg-gray-50 border-b border-gray-100 text-sm space-y-1">
          <div class="flex justify-between"><span class="text-gray-500">Opening Balance</span><span class="font-semibold">KES {Decimal.round(summary.open_amount, 2)}</span></div>
          <div class="flex justify-between"><span class="text-gray-500">Cash Sales</span><span class="font-semibold text-emerald-600">+ KES {Decimal.round(summary.cash_sales, 2)}</span></div>
          <div class="flex justify-between"><span class="text-gray-500">Expenses</span><span class="font-semibold text-red-500">- KES {Decimal.round(summary.total_expenses, 2)}</span></div>
          <div class="flex justify-between border-t border-gray-200 pt-1 mt-1"><span class="font-bold text-gray-700">Expected</span><span class="font-black">KES {Decimal.round(summary.expected_close, 2)}</span></div>
        </div>
        <form phx-submit="save_close" class="p-6 space-y-4">
          <div>
            <label class="block text-xs font-semibold text-gray-600 mb-1">Actual Closing Cash (KES) *</label>
            <input
              type="number"
              step="0.01"
              name="close[close_amount]"
              placeholder={Decimal.round(summary.expected_close, 2)}
              class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
            />
          </div>
          <div>
            <label class="block text-xs font-semibold text-gray-600 mb-1">Notes</label>
            <input type="text" name="close[notes]" placeholder="Optional note…" class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400" />
          </div>
          <div class="flex justify-end gap-3 pt-2 border-t border-gray-100">
            <button type="button" phx-click="cancel_close_modal" class="px-4 py-2 text-sm font-semibold text-gray-600 hover:text-gray-900 border border-gray-200 rounded-lg transition">Cancel</button>
            <button type="submit" class="px-5 py-2 bg-gray-800 hover:bg-gray-900 text-white font-bold text-sm rounded-lg transition uppercase tracking-wide">Close Register</button>
          </div>
        </form>
      </div>
    </div>
    """
  end

  defp render_expense_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
      <div class="bg-white rounded-xl shadow-2xl w-full max-w-sm" phx-window-keydown="cancel_expense_modal" phx-key="Escape">
        <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200">
          <h2 class="text-lg font-black text-gray-900">Add Cash Expense</h2>
          <button phx-click="cancel_expense_modal" class="text-gray-400 hover:text-gray-700">
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
            </svg>
          </button>
        </div>
        <form phx-change="validate_expense" phx-submit="save_expense" class="p-6 space-y-4">
          <div>
            <label class="block text-xs font-semibold text-gray-600 mb-1">Description *</label>
            <input
              type="text"
              name="expense[description]"
              value={Phoenix.HTML.Form.input_value(@expense_form, :description)}
              placeholder="e.g. Bought ice, paid delivery…"
              class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
            />
            <%= for {msg, _} <- Keyword.get_values(@expense_form.errors || [], :description) do %>
              <p class="text-xs text-red-500 mt-0.5">{msg}</p>
            <% end %>
          </div>
          <div>
            <label class="block text-xs font-semibold text-gray-600 mb-1">Amount (KES) *</label>
            <input
              type="number"
              step="0.01"
              name="expense[amount]"
              value={Phoenix.HTML.Form.input_value(@expense_form, :amount)}
              placeholder="0.00"
              class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
            />
            <%= for {msg, _} <- Keyword.get_values(@expense_form.errors || [], :amount) do %>
              <p class="text-xs text-red-500 mt-0.5">{msg}</p>
            <% end %>
          </div>
          <div>
            <label class="block text-xs font-semibold text-gray-600 mb-1">Notes</label>
            <input
              type="text"
              name="expense[notes]"
              value={Phoenix.HTML.Form.input_value(@expense_form, :notes)}
              placeholder="Optional…"
              class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
            />
          </div>
          <div class="flex justify-end gap-3 pt-2 border-t border-gray-100">
            <button type="button" phx-click="cancel_expense_modal" class="px-4 py-2 text-sm font-semibold text-gray-600 hover:text-gray-900 border border-gray-200 rounded-lg transition">Cancel</button>
            <button type="submit" class="px-5 py-2 bg-amber-500 hover:bg-amber-600 text-white font-bold text-sm rounded-lg transition uppercase tracking-wide">Save</button>
          </div>
        </form>
      </div>
    </div>
    """
  end

  defp format_datetime(nil), do: "—"
  defp format_datetime(%DateTime{} = dt) do
    Calendar.strftime(dt, "%d %b %Y, %H:%M")
  end
  defp format_datetime(%NaiveDateTime{} = dt) do
    Calendar.strftime(dt, "%d %b %Y, %H:%M")
  end
end

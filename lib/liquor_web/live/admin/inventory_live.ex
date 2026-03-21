defmodule LiquorWeb.Admin.InventoryLive do
  use LiquorWeb, :live_view

  alias Liquor.Catalog
  alias Liquor.Expenses

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title:     "Admin – Inventory",
       active_tab:     "inventory",
       search:         "",
       low_stock_only: false,
       editing_id:     nil,
       edit_qty:       "",
       expense_modal:  nil
     )
     |> load_variants(),
     layout: {LiquorWeb.Layouts, :admin}}
  end

  defp load_variants(socket) do
    variants = Catalog.list_all_variants(
      search: socket.assigns.search,
      low_stock: socket.assigns.low_stock_only
    )
    stock_value = Catalog.total_stock_value()
    assign(socket, variants: variants, stock_value: stock_value)
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, socket |> assign(search: q) |> load_variants()}
  end

  def handle_event("toggle_low_stock", _params, socket) do
    {:noreply, socket |> assign(low_stock_only: !socket.assigns.low_stock_only) |> load_variants()}
  end

  def handle_event("start_edit", %{"id" => id}, socket) do
    id_int = String.to_integer(id)
    variant = Enum.find(socket.assigns.variants, &(&1.id == id_int))
    {:noreply, assign(socket, editing_id: id_int, edit_qty: to_string(variant.stock_quantity))}
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, editing_id: nil, edit_qty: "")}
  end

  def handle_event("set_edit_qty", %{"qty" => qty}, socket) do
    {:noreply, assign(socket, edit_qty: qty)}
  end

  def handle_event("save_stock", %{"id" => id}, socket) do
    id_int  = String.to_integer(id)
    new_qty = socket.assigns.edit_qty |> String.to_integer() |> max(0)
    variant = Catalog.get_variant!(id_int)
    old_qty = variant.stock_quantity

    case Catalog.update_variant(variant, %{stock_quantity: new_qty}) do
      {:ok, _} ->
        added = new_qty - old_qty

        socket =
          if added > 0 do
            assign(socket,
              expense_modal: %{
                variant: variant,
                qty_added: added,
                unit_cost: ""
              }
            )
          else
            socket |> put_flash(:info, "Stock updated for #{variant.sku}.")
          end

        {:noreply,
         socket
         |> assign(editing_id: nil, edit_qty: "")
         |> load_variants()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update stock.")}
    end
  end

  def handle_event("adjust_stock", %{"id" => id, "delta" => delta}, socket) do
    id_int    = String.to_integer(id)
    delta_int = String.to_integer(delta)
    variant   = Catalog.get_variant!(id_int)

    case Catalog.adjust_stock(variant, delta_int) do
      {:ok, _} ->
        socket =
          if delta_int > 0 do
            assign(socket,
              expense_modal: %{
                variant: variant,
                qty_added: delta_int,
                unit_cost: ""
              }
            )
          else
            put_flash(socket, :info, "Stock adjusted.")
          end

        {:noreply, socket |> load_variants()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to adjust stock.")}
    end
  end

  def handle_event("set_expense_unit_cost", %{"unit_cost" => cost}, socket) do
    modal = %{socket.assigns.expense_modal | unit_cost: cost}
    {:noreply, assign(socket, expense_modal: modal)}
  end

  def handle_event("save_expense", _params, socket) do
    %{variant: variant, qty_added: qty, unit_cost: cost_str} = socket.assigns.expense_modal

    with {unit_cost, _} <- Decimal.parse(cost_str),
         true <- Decimal.compare(unit_cost, Decimal.new("0")) == :gt do
      total = Decimal.mult(unit_cost, Decimal.new(qty))

      Expenses.create_expense(%{
        description:  "Stock restock – #{variant.product.name} (#{variant.size})",
        category:     "stock_restock",
        amount:       total,
        expense_date: Date.utc_today(),
        product_name: variant.product.name,
        variant_sku:  variant.sku,
        quantity:     qty,
        unit_cost:    unit_cost
      })

      {:noreply,
       socket
       |> put_flash(:info, "Stock updated and expense of KSh #{Decimal.round(total, 2)} recorded.")
       |> assign(expense_modal: nil)}
    else
      _ ->
        {:noreply, put_flash(socket, :error, "Please enter a valid unit cost.")}
    end
  end

  def handle_event("skip_expense", _params, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Stock updated. No expense recorded.")
     |> assign(expense_modal: nil)}
  end

  @impl true
  def render(assigns) do
    low_stock_count = Enum.count(assigns.variants, &(&1.stock_quantity <= 5))
    out_of_stock    = Enum.count(assigns.variants, &(&1.stock_quantity == 0))
    total_units     = Enum.sum(Enum.map(assigns.variants, & &1.stock_quantity))

    assigns = assign(assigns,
      low_stock_count: low_stock_count,
      out_of_stock: out_of_stock,
      total_units: total_units
    )

    ~H"""
    <div class="max-w-screen-xl mx-auto px-4 py-8">

      <!-- Header -->
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-2xl font-black text-gray-900">Inventory</h1>
          <p class="text-sm text-gray-500 mt-0.5">Manage stock levels across all product variants</p>
        </div>
      </div>

      <!-- Stats -->
      <div class="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-6">
        <div class="bg-white border border-gray-200 rounded-xl p-4">
          <p class="text-2xl font-black text-gray-900"><%= length(@variants) %></p>
          <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide mt-0.5">SKUs</p>
        </div>
        <div class="bg-blue-50 border border-blue-200 rounded-xl p-4">
          <p class="text-2xl font-black text-blue-700"><%= @total_units %></p>
          <p class="text-xs font-semibold text-blue-600 uppercase tracking-wide mt-0.5">Total Units</p>
        </div>
        <div class="bg-amber-50 border border-amber-200 rounded-xl p-4">
          <p class="text-2xl font-black text-amber-700"><%= @low_stock_count %></p>
          <p class="text-xs font-semibold text-amber-600 uppercase tracking-wide mt-0.5">Low Stock (≤5)</p>
        </div>
        <div class="bg-red-50 border border-red-200 rounded-xl p-4">
          <p class="text-2xl font-black text-red-700"><%= @out_of_stock %></p>
          <p class="text-xs font-semibold text-red-600 uppercase tracking-wide mt-0.5">Out of Stock</p>
        </div>
      </div>

      <!-- Stock value -->
      <div class="bg-gradient-to-r from-amber-50 to-orange-50 border border-amber-200 rounded-xl p-5 mb-6 flex items-center justify-between">
        <div>
          <p class="text-xs font-bold uppercase tracking-widest text-amber-600 mb-1">Total Stock Value</p>
          <p class="text-3xl font-black text-amber-700">
            KSh <%= Decimal.round(@stock_value || Decimal.new("0"), 2) %>
          </p>
        </div>
        <svg class="w-12 h-12 text-amber-300" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
          <path d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4"/>
        </svg>
      </div>

      <!-- Filters -->
      <div class="flex items-center gap-3 mb-4 flex-wrap">
        <input
          type="text"
          placeholder="Search by product or SKU…"
          value={@search}
          phx-keyup="search"
          name="q"
          class="border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400 w-64"
        />
        <button
          phx-click="toggle_low_stock"
          class={[
            "text-sm font-semibold px-4 py-2 rounded-lg border transition",
            if(@low_stock_only,
              do: "bg-amber-500 text-white border-amber-500",
              else: "border-gray-200 text-gray-600 hover:border-amber-300 bg-white")
          ]}
        >
          ⚠ Low Stock Only
        </button>
      </div>

      <!-- Table -->
      <div class="bg-white border border-gray-200 rounded-xl overflow-hidden">
        <table class="w-full text-sm">
          <thead class="bg-gray-50 border-b border-gray-200">
            <tr>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Product</th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">SKU</th>
              <th class="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Size</th>
              <th class="text-right px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Price</th>
              <th class="text-center px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Stock</th>
              <th class="text-center px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Status</th>
              <th class="text-right px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Value</th>
              <th class="px-5 py-3"></th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <%= for v <- @variants do %>
              <tr class={["hover:bg-gray-50 transition", if(v.stock_quantity == 0, do: "bg-red-50/30")]}>
                <td class="px-5 py-3 font-semibold text-gray-800"><%= v.product.name %></td>
                <td class="px-5 py-3 font-mono text-xs text-gray-400"><%= v.sku %></td>
                <td class="px-5 py-3 text-gray-500"><%= v.size %></td>
                <td class="px-5 py-3 text-right text-gray-700">KSh <%= Decimal.round(v.price, 2) %></td>
                <td class="px-5 py-3 text-center">
                  <%= if @editing_id == v.id do %>
                    <div class="flex items-center justify-center gap-1">
                      <input
                        type="number"
                        min="0"
                        value={@edit_qty}
                        phx-keyup="set_edit_qty"
                        name="qty"
                        class="w-20 border border-amber-400 rounded px-2 py-1 text-sm text-center focus:outline-none focus:ring-1 focus:ring-amber-400"
                      />
                      <button
                        phx-click="save_stock"
                        phx-value-id={v.id}
                        class="text-xs bg-emerald-500 text-white px-2 py-1 rounded hover:bg-emerald-600"
                      >✓</button>
                      <button
                        phx-click="cancel_edit"
                        class="text-xs bg-gray-200 text-gray-600 px-2 py-1 rounded hover:bg-gray-300"
                      >✗</button>
                    </div>
                  <% else %>
                    <div class="flex items-center justify-center gap-2">
                      <button
                        phx-click="adjust_stock"
                        phx-value-id={v.id}
                        phx-value-delta="-1"
                        class="w-5 h-5 rounded bg-gray-200 hover:bg-gray-300 text-gray-700 font-bold text-xs flex items-center justify-center"
                      >−</button>
                      <span class={[
                        "font-bold text-base w-10 text-center",
                        cond do
                          v.stock_quantity == 0 -> "text-red-600"
                          v.stock_quantity <= 5 -> "text-amber-600"
                          true -> "text-gray-900"
                        end
                      ]}><%= v.stock_quantity %></span>
                      <button
                        phx-click="adjust_stock"
                        phx-value-id={v.id}
                        phx-value-delta="1"
                        class="w-5 h-5 rounded bg-gray-200 hover:bg-gray-300 text-gray-700 font-bold text-xs flex items-center justify-center"
                      >+</button>
                    </div>
                  <% end %>
                </td>
                <td class="px-5 py-3 text-center">
                  <span class={[
                    "text-[10px] font-bold uppercase tracking-wide px-2 py-0.5 rounded",
                    cond do
                      v.stock_quantity == 0 -> "bg-red-100 text-red-700"
                      v.stock_quantity <= 5 -> "bg-amber-100 text-amber-700"
                      true -> "bg-emerald-100 text-emerald-700"
                    end
                  ]}>
                    <%= cond do
                      v.stock_quantity == 0 -> "Out of stock"
                      v.stock_quantity <= 5 -> "Low stock"
                      true -> "In stock"
                    end %>
                  </span>
                </td>
                <td class="px-5 py-3 text-right text-gray-600">
                  KSh <%= Decimal.round(Decimal.mult(v.price, Decimal.new(v.stock_quantity)), 2) %>
                </td>
                <td class="px-5 py-3 text-right">
                  <button
                    phx-click="start_edit"
                    phx-value-id={v.id}
                    class="text-xs font-semibold text-amber-600 hover:underline"
                  >
                    Edit
                  </button>
                </td>
              </tr>
            <% end %>
            <%= if @variants == [] do %>
              <tr><td colspan="8" class="px-5 py-12 text-center text-sm text-gray-400">No variants found</td></tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Expense modal (shown after adding stock) -->
    <%= if @expense_modal do %>
      <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
        <div class="bg-white rounded-xl shadow-2xl w-full max-w-md">
          <div class="px-6 py-4 border-b border-gray-200">
            <h2 class="text-lg font-black text-gray-900">Record Stock Expense</h2>
            <p class="text-sm text-gray-500 mt-0.5">
              You added <span class="font-bold text-gray-800"><%= @expense_modal.qty_added %> units</span>
              of <span class="font-bold text-gray-800"><%= @expense_modal.variant.product.name %> (<%= @expense_modal.variant.size %>)</span>.
              Enter the cost per unit to log this as an expense.
            </p>
          </div>
          <div class="p-6 space-y-4">
            <div>
              <label class="block text-xs font-semibold text-gray-600 mb-1">Cost per unit (KSh)</label>
              <input
                type="number"
                step="0.01"
                min="0"
                value={@expense_modal.unit_cost}
                phx-keyup="set_expense_unit_cost"
                name="unit_cost"
                placeholder="0.00"
                class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
              />
              <%= if @expense_modal.unit_cost != "" do %>
                <% total = case Decimal.parse(@expense_modal.unit_cost) do
                  {v, _} -> Decimal.mult(v, Decimal.new(@expense_modal.qty_added))
                  _ -> nil
                end %>
                <%= if total && Decimal.compare(total, Decimal.new("0")) == :gt do %>
                  <p class="text-sm text-gray-500 mt-1">
                    Total expense: <span class="font-bold text-gray-800">KSh <%= Decimal.round(total, 2) %></span>
                  </p>
                <% end %>
              <% end %>
            </div>
            <div class="flex justify-end gap-3 pt-1">
              <button phx-click="skip_expense"
                class="px-4 py-2 text-sm font-semibold text-gray-500 border border-gray-200 rounded-lg hover:bg-gray-50 transition">
                Skip
              </button>
              <button phx-click="save_expense"
                class="px-5 py-2 text-sm font-bold bg-amber-500 text-white rounded-lg hover:bg-amber-600 transition">
                Save Expense
              </button>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end
end

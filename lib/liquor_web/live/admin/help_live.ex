defmodule LiquorWeb.Admin.HelpLive do
  use LiquorWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Admin – Help & Guide",
       active_tab: "help",
       active_section: "overview"
     ), layout: {LiquorWeb.Layouts, :admin}}
  end

  @impl true
  def handle_event("set_section", %{"section" => section}, socket) do
    {:noreply, assign(socket, active_section: section)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-screen-xl mx-auto px-4 py-8">
      <div class="mb-6">
        <h1 class="text-2xl font-black text-gray-900">Help & System Guide</h1>
        <p class="text-sm text-gray-500">Everything you need to know about managing this system</p>
      </div>

      <div class="flex gap-8 items-start">

        <!-- Sidebar nav -->
        <aside class="w-52 shrink-0 hidden lg:block">
          <nav class="space-y-1 sticky top-4">
            <%= for {key, label, icon} <- sections() do %>
              <button
                phx-click="set_section"
                phx-value-section={key}
                class={[
                  "w-full flex items-center gap-2.5 px-3 py-2.5 rounded-lg text-sm font-medium text-left transition",
                  if(@active_section == key,
                    do: "bg-amber-500 text-white",
                    else: "text-gray-600 hover:bg-gray-100"
                  )
                ]}
              >
                <span class="text-base">{icon}</span>
                {label}
              </button>
            <% end %>
          </nav>
        </aside>

        <!-- Mobile section picker -->
        <div class="lg:hidden mb-4 w-full">
          <select
            class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm bg-white"
            onchange="this.dispatchEvent(new CustomEvent('phx:click', {bubbles: true, detail: {event: 'set_section', params: {section: this.value}}}))"
          >
            <%= for {key, label, _icon} <- sections() do %>
              <option value={key} selected={@active_section == key}>{label}</option>
            <% end %>
          </select>
        </div>

        <!-- Content -->
        <div class="flex-1 min-w-0">
          <div class="bg-white border border-gray-200 rounded-xl p-6 lg:p-8 prose prose-sm max-w-none prose-headings:font-black prose-headings:text-gray-900 prose-a:text-amber-600">

            <%= case @active_section do %>
              <% "overview" -> %>
                <h2>System Overview</h2>
                <p>Welcome to the <strong>The Mint Liquor Store Admin Panel</strong>. This system gives you full control over your online liquor store — from product listings and inventory to orders, customers, and financial reporting.</p>
                <h3>What you can do here</h3>
                <ul>
                  <li><strong>Commerce</strong> — manage products, categories, brands and customer orders</li>
                  <li><strong>ERP</strong> — track sales, expenses, customers, inventory and generate reports</li>
                  <li><strong>Settings</strong> — customise the storefront appearance, homepage content, and delivery fees</li>
                  <li><strong>System Users</strong> — add or remove admin staff who can log into this panel</li>
                </ul>
                <h3>Getting started checklist</h3>
                <ol>
                  <li>Create your <strong>Categories</strong> (e.g. Whisky, Wine, Beer)</li>
                  <li>Add <strong>Brands</strong> (e.g. Jack Daniel's, Jameson)</li>
                  <li>Add <strong>Products</strong> with images and descriptions</li>
                  <li>Add <strong>Variants</strong> to each product (e.g. 250ml, 750ml, 1L) with prices and stock</li>
                  <li>Configure your <strong>Settings</strong> — store name, homepage hero, delivery fee</li>
                  <li>Share the store link with customers and watch the <strong>Orders</strong> come in</li>
                </ol>

              <% "products" -> %>
                <h2>Products</h2>
                <p>Products are the items you sell. Each product can have multiple <strong>variants</strong> (different sizes/prices).</p>
                <h3>Creating a product</h3>
                <ol>
                  <li>Go to <strong>Products</strong> in the sidebar</li>
                  <li>Click <strong>+ New Product</strong></li>
                  <li>Fill in the name — the slug is auto-generated</li>
                  <li>Select a <strong>Category</strong> and optionally a <strong>Brand</strong></li>
                  <li>Upload a product image or paste an image URL</li>
                  <li>Add a description, badge (Best Seller / Limited Edition), and year if applicable</li>
                  <li>Click <strong>Save Product</strong></li>
                </ol>
                <h3>Adding variants</h3>
                <p>After saving the product, click the <strong>variants button</strong> (shows variant count) in the product row to open the variants panel. Add at least one variant with a size (e.g. 750ml), price, and stock quantity.</p>
                <ul>
                  <li><strong>Default variant</strong> — the one shown first on the shop page</li>
                  <li><strong>Compare price</strong> — shown as a strikethrough to indicate a discount</li>
                  <li><strong>ABV</strong> — alcohol by volume percentage</li>
                  <li><strong>Stock quantity</strong> — when 0, the product shows "Out of Stock"</li>
                </ul>
                <h3>Tips</h3>
                <ul>
                  <li>Toggle <strong>Active</strong> to hide/show a product on the storefront without deleting it</li>
                  <li>Toggle <strong>Featured</strong> to include a product in the Featured section on the homepage</li>
                </ul>

              <% "orders" -> %>
                <h2>Orders</h2>
                <p>Orders are created when customers complete checkout. You can manage the status of each order from the Orders page.</p>
                <h3>Order statuses</h3>
                <ul>
                  <li><strong>Pending</strong> — order placed, payment not yet confirmed</li>
                  <li><strong>Paid</strong> — payment received</li>
                  <li><strong>Processing</strong> — being prepared for delivery</li>
                  <li><strong>Shipped</strong> — dispatched to the customer</li>
                  <li><strong>Delivered</strong> — successfully delivered</li>
                  <li><strong>Cancelled</strong> — order was cancelled</li>
                </ul>
                <h3>Workflow</h3>
                <ol>
                  <li>When an order comes in, it starts as <strong>Pending</strong></li>
                  <li>Once M-Pesa payment is confirmed, it moves to <strong>Paid</strong></li>
                  <li>Mark it <strong>Processing</strong> when you start preparing</li>
                  <li>Mark <strong>Shipped</strong> when handed to delivery</li>
                  <li>Mark <strong>Delivered</strong> once customer confirms receipt</li>
                </ol>

              <% "inventory" -> %>
                <h2>Inventory</h2>
                <p>The Inventory page shows all product variants and their current stock levels.</p>
                <ul>
                  <li>You can adjust stock directly from the inventory table</li>
                  <li>Items with <strong>0 stock</strong> are highlighted — they will show "Out of Stock" on the storefront</li>
                  <li>Stock is automatically decremented when an order is placed (if inventory tracking is enabled)</li>
                </ul>
                <h3>Best practices</h3>
                <ul>
                  <li>Update stock after each physical delivery/restock</li>
                  <li>Review the inventory page weekly to catch low-stock items</li>
                </ul>

              <% "sales_expenses" -> %>
                <h2>Sales & Expenses</h2>
                <h3>Sales</h3>
                <p>The Sales page shows a record of all completed sales transactions. Use it to track daily/monthly revenue.</p>
                <h3>Expenses</h3>
                <p>Log business expenses here (e.g. rent, delivery costs, stock purchases). This feeds into the Reports page to give you a profit/loss view.</p>
                <ul>
                  <li>Always add an <strong>expense category</strong> to keep reports clean</li>
                  <li>Add a <strong>note</strong> for any expense that needs context</li>
                </ul>

              <% "reports" -> %>
                <h2>Reports</h2>
                <p>Reports give you a financial overview of the business.</p>
                <ul>
                  <li><strong>Revenue</strong> — total from paid orders in the selected period</li>
                  <li><strong>Expenses</strong> — total logged expenses in the same period</li>
                  <li><strong>Profit</strong> — Revenue minus Expenses</li>
                  <li><strong>Top products</strong> — which items are selling most</li>
                </ul>
                <p>Use the date filter to switch between daily, weekly, monthly, and custom ranges.</p>

              <% "settings" -> %>
                <h2>Settings</h2>
                <p>Settings control the appearance and behaviour of the storefront.</p>
                <h3>Key settings</h3>
                <ul>
                  <li><strong>Store name & tagline</strong> — displayed in the browser tab and SEO</li>
                  <li><strong>Homepage hero</strong> — the large banner image and tiles on the homepage</li>
                  <li><strong>Featured product IDs</strong> — comma-separated product IDs to show in the homepage highlights carousel</li>
                  <li><strong>Delivery fee</strong> — flat fee applied at checkout</li>
                  <li><strong>Free delivery threshold</strong> — order amount above which delivery is free</li>
                </ul>

              <% "users" -> %>
                <h2>System Users</h2>
                <p>System Users are the staff accounts that can log into this admin panel.</p>
                <h3>Adding a new admin</h3>
                <ol>
                  <li>Go to <strong>System Users</strong> in the sidebar</li>
                  <li>Click <strong>+ Add Admin</strong></li>
                  <li>Enter the person's name, email and a temporary password</li>
                  <li>Click <strong>Save</strong></li>
                  <li>Share the email and password with the new admin — they can log in at <code>/admin/login</code></li>
                </ol>
                <h3>Managing access</h3>
                <ul>
                  <li>Toggle the <strong>Active</strong> switch to suspend access without deleting the account</li>
                  <li>Use <strong>Delete</strong> to permanently remove an admin account</li>
                </ul>
                <div class="bg-amber-50 border border-amber-200 rounded-lg p-4 mt-4">
                  <p class="text-amber-800 font-semibold text-sm">⚠️ Be careful when deleting your own account — you will be logged out immediately.</p>
                </div>

              <% _ -> %>
                <p>Select a section from the left menu.</p>
            <% end %>

          </div>
        </div>
      </div>
    </div>
    """
  end

  defp sections do
    [
      {"overview",       "Overview",         "🏠"},
      {"products",       "Products",         "📦"},
      {"orders",         "Orders",           "🧾"},
      {"inventory",      "Inventory",        "🏭"},
      {"sales_expenses", "Sales & Expenses", "💰"},
      {"reports",        "Reports",          "📊"},
      {"settings",       "Settings",         "⚙️"},
      {"users",          "System Users",     "👥"}
    ]
  end
end

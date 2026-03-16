defmodule LiquorWeb.AboutLive do
  use LiquorWeb, :live_view

  import LiquorWeb.AboutComponents

  alias Liquor.Catalog
  alias Liquor.Orders
  alias Liquor.Accounts

  @team_members [
    {"The Owner",    "CEO · Founder",  nil},
    {"Head Buyer",   "Senior Buyer",   nil},
    {"Head of Sales","Sales Manager",  nil},
    {"Store Manager","Operations",     nil}
  ]

  @impl true
  def mount(_params, _session, socket) do
    product_count  = Catalog.count_products()
    order_count    = Orders.count_paid_orders()
    customer_count = Accounts.count_users()

    stats = [
      {to_string(product_count),  "+", "products in stock"},
      {to_string(order_count),    "+", "orders fulfilled"},
      {to_string(customer_count), "+", "happy customers"},
      {"100",                     "%", "authentic products"}
    ]

    {:ok,
     assign(socket,
       current_page: "about",
       page_title:   "About Us",
       stats:        stats,
       team_members: @team_members
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.about_hero />
    <.stats_row stats={@stats} />
    <.mission_values />
    <.team_section team_members={@team_members} />
    <.subscribe_banner />
    """
  end
end

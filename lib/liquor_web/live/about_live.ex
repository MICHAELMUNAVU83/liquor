defmodule LiquorWeb.AboutLive do
  use LiquorWeb, :live_view

  import LiquorWeb.AboutComponents

  alias Liquor.Catalog
  alias Liquor.Orders
  alias Liquor.Accounts
  alias Liquor.Settings

  @team_members [
    {"The Owner", "CEO · Founder", nil},
    {"Head Buyer", "Senior Buyer", nil},
    {"Head of Sales", "Sales Manager", nil},
    {"Store Manager", "Operations", nil}
  ]

  @impl true
  def mount(_params, _session, socket) do
    product_count = Catalog.count_products()
    order_count = Orders.count_paid_orders()
    customer_count = Accounts.count_users()

    stats = [
      {to_string(product_count), "+", "products in stock"},
      {to_string(order_count), "+", "orders fulfilled"},
      {to_string(customer_count), "+", "happy customers"},
      {"100", "%", "authentic products"}
    ]

    settings = Settings.all()

    {:ok,
     assign(socket,
       current_page:     "about",
       page_title:       "About Us",
       page_description: "Learn about The Mint Liquor Store – Nairobi's trusted premium liquor retailer at TRM Mall, Thika Road. Our story, team & values.",
       canonical_path:   "/about",
       stats: stats,
       team_members: @team_members,
       settings: settings,
       about_heading:   settings["about_hero_heading"],
       about_desc:      settings["about_hero_desc"],
       about_image:     settings["about_hero_image"],
       about_mission:   settings["about_mission"],
       about_values:    settings["about_values"]
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.about_hero heading={@about_heading} desc={@about_desc} image_url={@about_image} />
    <.stats_row stats={@stats} />
    <.mission_values mission={@about_mission} values={@about_values} />
    <.subscribe_banner />
    """
  end
end

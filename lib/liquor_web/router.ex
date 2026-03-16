defmodule LiquorWeb.Router do
  use LiquorWeb, :router

  import LiquorWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LiquorWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # ---------------------------------------------------------------------------
  # Public storefront
  # ---------------------------------------------------------------------------
  scope "/", LiquorWeb do
    pipe_through :browser

    live "/",        HomeLive
    live "/shop",    ShopLive
    live "/about",   AboutLive
    live "/contact", ContactLive
    live "/cart",    CartLive
  end

  # ---------------------------------------------------------------------------
  # Admin – authentication (no login required)
  # ---------------------------------------------------------------------------
  scope "/admin", LiquorWeb.Admin do
    pipe_through :browser

    get    "/login",  SessionController, :new
    post   "/login",  SessionController, :create
    delete "/logout", SessionController, :delete
  end

  # ---------------------------------------------------------------------------
  # Admin – protected LiveViews (require signed-in admin)
  # ---------------------------------------------------------------------------
  scope "/admin", LiquorWeb.Admin do
    pipe_through [:browser, :require_admin_user]

    live_session :require_admin,
      on_mount: [{LiquorWeb.UserAuth, :require_admin}] do
      live "/",           DashboardLive,  :index
      live "/products",   ProductsLive,   :index
      live "/categories", CategoriesLive, :index
      live "/brands",     BrandsLive,     :index
      live "/orders",     OrdersLive,     :index
      live "/sales",      SalesLive,      :index
      live "/invoices",   InvoicesLive,   :index
      live "/customers",  CustomersLive,  :index
      live "/inventory",  InventoryLive,  :index
      live "/reports",    ReportsLive,    :index
    end
  end

  # ---------------------------------------------------------------------------
  # Dev utilities
  # ---------------------------------------------------------------------------
  if Application.compile_env(:liquor, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: LiquorWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end

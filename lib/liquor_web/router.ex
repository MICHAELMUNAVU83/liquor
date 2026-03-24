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
    live "/shop",          ShopLive
    live "/shop/:slug",    ProductLive
    live "/about",   AboutLive
    live "/contact", ContactLive
    live "/cart",             CartLive
    live "/checkout",         CheckoutLive, :index
    live "/checkout/success", CheckoutLive, :success

    get "/payment/callback", PaymentController, :callback
    get "/sitemap.xml",      SitemapController, :index
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

    get "/receipt/:id",         ReceiptController, :show
    get "/reports/download/sales",     ReportController, :sales
    get "/reports/download/expenses",  ReportController, :expenses
    get "/reports/download/cash",      ReportController, :cash
    get "/reports/download/stock",     ReportController, :stock
    get "/reports/download/purchases", ReportController, :purchases

    # All roles: dashboard + help
    live_session :admin_all,
      on_mount: [{LiquorWeb.UserAuth, :require_admin}] do
      live "/",    DashboardLive, :index
      live "/help", HelpLive,     :index
    end

    # Products section: super_admin, manager, inventory_clerk
    live_session :admin_products,
      on_mount: [
        {LiquorWeb.UserAuth, :require_admin},
        {LiquorWeb.UserAuth, {:require_permission, :products}}
      ] do
      live "/products",   ProductsLive,   :index
      live "/categories", CategoriesLive, :index
      live "/brands",     BrandsLive,     :index
      live "/inventory",  InventoryLive,  :index
    end

    # Orders section: super_admin, manager, cashier
    live_session :admin_orders,
      on_mount: [
        {LiquorWeb.UserAuth, :require_admin},
        {LiquorWeb.UserAuth, {:require_permission, :orders}}
      ] do
      live "/orders",    OrdersLive,    :index
      live "/customers", CustomersLive, :index
    end

    # Finance section: super_admin, manager
    live_session :admin_finance,
      on_mount: [
        {LiquorWeb.UserAuth, :require_admin},
        {LiquorWeb.UserAuth, {:require_permission, :sales}}
      ] do
      live "/sales",    SalesLive,    :index
      live "/expenses", ExpensesLive, :index
      live "/reports",  ReportsLive,  :index
    end

    # Cash registry: super_admin, manager, cashier
    live_session :admin_cash,
      on_mount: [
        {LiquorWeb.UserAuth, :require_admin},
        {LiquorWeb.UserAuth, {:require_permission, :cash_registry}}
      ] do
      live "/cash-registry", CashRegistryLive, :index
    end

    # Super admin only: settings + users
    live_session :admin_super,
      on_mount: [
        {LiquorWeb.UserAuth, :require_admin},
        {LiquorWeb.UserAuth, {:require_permission, :settings}}
      ] do
      live "/settings", SettingsLive, :index
      live "/users",    UsersLive,    :index
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

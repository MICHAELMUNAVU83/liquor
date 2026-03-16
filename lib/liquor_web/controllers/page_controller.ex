defmodule LiquorWeb.PageController do
  use LiquorWeb, :controller

  def home(conn, _params) do
    render(conn, :home, current_page: "home")
  end

  def shop(conn, _params) do
    products = [
      %{badge: "BEST SELLER", badge_color: "bg-emerald-500", category: "Tequila",
        name: "Estampa Gran Reserva Sauvignon Blanc Chardonnay Viognier 2021...",
        reviews: 5, price: "$994.03", size: "100ML", abv: "35%",
        in_stock: true, has_options: false, rating: 4},
      %{badge: nil, category: "Brandy",
        name: "Beringer Founders Estate Cabernet Sauvignon",
        reviews: 5, price: "$390.00", size: "1.75L", abv: "35%",
        in_stock: true, has_options: false, rating: 4},
      %{badge: "LIMITED EDITION", badge_color: "bg-amber-500", category: "Tequila",
        name: "Bread And Butter Reserve River Valley Pinot Noir 2021",
        reviews: 5, price: "$10.11–$19.95", size: "1.75L", abv: "35%",
        in_stock: true, has_options: true, rating: 5},
      %{badge: "BEST SELLER", badge_color: "bg-emerald-500", category: "Mezcal",
        name: "Estampa Reserva Carmenere Malbec 2021",
        reviews: 5, price: "$10.26–$19.48", size: "1L", abv: "35%",
        in_stock: true, has_options: true, rating: 4},
      %{badge: "BEST SELLER", badge_color: "bg-emerald-500", category: "Gin",
        name: "Escudo Rojo Reserva Pinot Noir 2021 (PRE-ORDER)",
        reviews: 5, price: "$350.00", size: "1.75L", abv: "40%",
        in_stock: true, has_options: false, rating: 4},
      %{badge: "LIMITED EDITION", badge_color: "bg-amber-500", category: "Gin",
        name: "Estampa Reserva Viognier Chardonnay 2022",
        reviews: 5, price: "$169.12", size: "1.75L", abv: "43%",
        in_stock: true, has_options: false, rating: 5}
    ]

    render(conn, :shop, current_page: "shop", products: products)
  end

  def about(conn, _params) do
    render(conn, :about, current_page: "about")
  end

  def contact(conn, _params) do
    render(conn, :contact, current_page: "contact")
  end
end

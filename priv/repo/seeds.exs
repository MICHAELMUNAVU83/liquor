alias Liquor.{Orders, Repo}
alias Liquor.Catalog.{Category, Brand, Product, ProductVariant}
alias Liquor.Accounts.User
alias Liquor.Orders.Order
import Ecto.Query

IO.puts("🌱  Seeding database...")

# Helper: insert only if the slug doesn't already exist
defmodule Seeds.Helpers do
  def upsert_category(attrs) do
    case Repo.get_by(Category, slug: attrs.slug) do
      nil ->
        %Category{}
        |> Category.changeset(attrs)
        |> Repo.insert!()
      existing -> existing
    end
  end

  def upsert_brand(attrs) do
    case Repo.get_by(Brand, slug: attrs.slug) do
      nil ->
        %Brand{}
        |> Brand.changeset(attrs)
        |> Repo.insert!()
      existing -> existing
    end
  end

  def upsert_product(attrs) do
    case Repo.get_by(Product, slug: attrs.slug) do
      nil ->
        %Product{}
        |> Product.changeset(attrs)
        |> Repo.insert!()
      existing -> existing
    end
  end

  def upsert_variant(product_id, attrs) do
    # Use SKU as idempotency key; if no SKU yet, always insert
    case Map.get(attrs, :sku) do
      nil ->
        %ProductVariant{}
        |> ProductVariant.changeset(Map.put(attrs, :product_id, product_id))
        |> Repo.insert!()
      sku ->
        case Repo.get_by(ProductVariant, sku: sku) do
          nil ->
            %ProductVariant{}
            |> ProductVariant.changeset(Map.put(attrs, :product_id, product_id))
            |> Repo.insert!()
          existing -> existing
        end
    end
  end

  def upsert_user(attrs) do
    case Repo.get_by(User, email: attrs.email) do
      nil ->
        %User{}
        |> User.changeset(attrs)
        |> Repo.insert!()
      existing -> existing
    end
  end
end

# ---------------------------------------------------------------------------
# Categories
# ---------------------------------------------------------------------------

categories =
  for {name, slug, pos} <- [
    {"Spirits",  "spirits",  1},
    {"Whiskey",  "whiskey",  2},
    {"Wine",     "wine",     3},
    {"Beer",     "beer",     4},
    {"Gin",      "gin",      5},
    {"Tequila",  "tequila",  6},
    {"Rum",      "rum",      7},
    {"Vodka",    "vodka",    8},
    {"Cognac",   "cognac",   9},
    {"Mezcal",   "mezcal",  10}
  ] do
    cat = Seeds.Helpers.upsert_category(%{
      name:        name,
      slug:        slug,
      position:    pos,
      description: "Premium selection of #{name} from around the world.",
      image_url:   "https://images.unsplash.com/photo-1569529465841-dfecdab7503b?w=400&auto=format&fit=crop"
    })
    IO.puts("  ✓ Category: #{name}")
    {slug, cat}
  end

cats = Map.new(categories)

# ---------------------------------------------------------------------------
# Brands
# ---------------------------------------------------------------------------

brands =
  for {name, slug, country} <- [
    {"Jameson",        "jameson",        "Ireland"},
    {"Jack Daniel's",  "jack-daniels",   "USA"},
    {"Johnnie Walker", "johnnie-walker", "Scotland"},
    {"Hennessy",       "hennessy",       "France"},
    {"Patron",         "patron",         "Mexico"},
    {"Grey Goose",     "grey-goose",     "France"},
    {"Bacardi",        "bacardi",        "Bermuda"},
    {"Tanqueray",      "tanqueray",      "Scotland"},
    {"Buffalo Trace",  "buffalo-trace",  "USA"},
    {"Glenlivet",      "glenlivet",      "Scotland"},
    {"Heineken",       "heineken",       "Netherlands"},
    {"Jim Beam",       "jim-beam",       "USA"}
  ] do
    brand = Seeds.Helpers.upsert_brand(%{
      name:        name,
      slug:        slug,
      country:     country,
      description: "Premium #{name} – crafted with tradition since generations."
    })
    IO.puts("  ✓ Brand: #{name}")
    {slug, brand}
  end

bs = Map.new(brands)

# ---------------------------------------------------------------------------
# Products + Variants
# ---------------------------------------------------------------------------

products_data = [
  %{
    name: "Jameson Irish Whiskey",
    slug: "jameson-irish-whiskey",
    category: "whiskey", brand: "jameson",
    badge: "best_seller", is_featured: true, year: nil,
    description: "Triple-distilled for exceptional smoothness with notes of toasted wood and vanilla.",
    image_url: "https://images.unsplash.com/photo-1569529465841-dfecdab7503b?w=600&auto=format&fit=crop",
    variants: [
      %{size: "700ML", abv: "40.0", price: "24.99", compare_price: "29.99", stock_quantity: 150, is_default: true,  sku: "JAM-700ML"},
      %{size: "1L",    abv: "40.0", price: "32.99", compare_price: "37.99", stock_quantity: 80,  is_default: false, sku: "JAM-1L"},
      %{size: "1.75L", abv: "40.0", price: "44.99", compare_price: "52.99", stock_quantity: 60,  is_default: false, sku: "JAM-175L"}
    ]
  },
  %{
    name: "Jack Daniel's Old No. 7",
    slug: "jack-daniels-old-no-7",
    category: "whiskey", brand: "jack-daniels",
    badge: "best_seller", is_featured: true, year: nil,
    description: "Charcoal mellowed drop by drop for a uniquely smooth Tennessee Whiskey character.",
    image_url: "https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=600&auto=format&fit=crop",
    variants: [
      %{size: "700ML", abv: "40.0", price: "22.99", stock_quantity: 200, is_default: true,  sku: "JD-700ML"},
      %{size: "1L",    abv: "40.0", price: "29.99", stock_quantity: 120, is_default: false, sku: "JD-1L"},
      %{size: "1.75L", abv: "40.0", price: "39.99", stock_quantity: 75,  is_default: false, sku: "JD-175L"}
    ]
  },
  %{
    name: "Johnnie Walker Black Label",
    slug: "johnnie-walker-black-label",
    category: "whiskey", brand: "johnnie-walker",
    badge: "best_seller", is_featured: false, year: nil,
    description: "Aged at least 12 years. The benchmark of Scotch whisky worldwide.",
    image_url: "https://images.unsplash.com/photo-1527281400683-1aae777175f8?w=600&auto=format&fit=crop",
    variants: [
      %{size: "700ML", abv: "40.0", price: "29.99", stock_quantity: 90, is_default: true,  sku: "JWB-700ML"},
      %{size: "1L",    abv: "40.0", price: "38.99", stock_quantity: 55, is_default: false, sku: "JWB-1L"}
    ]
  },
  %{
    name: "Hennessy VS Cognac",
    slug: "hennessy-vs-cognac",
    category: "cognac", brand: "hennessy",
    badge: nil, is_featured: true, year: nil,
    description: "The world's best-selling Cognac – rich, vibrant and seductive.",
    image_url: "https://images.unsplash.com/photo-1547595628-c61a29f496f0?w=600&auto=format&fit=crop",
    variants: [
      %{size: "700ML", abv: "40.0", price: "35.99", stock_quantity: 70, is_default: true,  sku: "HVS-700ML"},
      %{size: "1L",    abv: "40.0", price: "48.99", stock_quantity: 40, is_default: false, sku: "HVS-1L"}
    ]
  },
  %{
    name: "Patron Silver Tequila",
    slug: "patron-silver-tequila",
    category: "tequila", brand: "patron",
    badge: "limited_edition", is_featured: true, year: nil,
    description: "100% Blue Weber agave. Ultra-premium silver tequila handcrafted in Mexico.",
    image_url: "https://images.unsplash.com/photo-1598373182133-52452f7691ef?w=600&auto=format&fit=crop",
    variants: [
      %{size: "700ML", abv: "40.0", price: "42.99", compare_price: "49.99", stock_quantity: 60, is_default: true,  sku: "PAT-SLV-700ML"},
      %{size: "1.75L", abv: "40.0", price: "79.99", compare_price: "89.99", stock_quantity: 30, is_default: false, sku: "PAT-SLV-175L"}
    ]
  },
  %{
    name: "Grey Goose Vodka",
    slug: "grey-goose-vodka",
    category: "vodka", brand: "grey-goose",
    badge: nil, is_featured: false, year: nil,
    description: "Made from single-origin Picardie wheat and natural spring water from Gensac.",
    image_url: "https://images.unsplash.com/photo-1491553895911-0055eca6402d?w=600&auto=format&fit=crop",
    variants: [
      %{size: "700ML", abv: "40.0", price: "34.99", stock_quantity: 100, is_default: true,  sku: "GG-700ML"},
      %{size: "1L",    abv: "40.0", price: "44.99", stock_quantity: 65,  is_default: false, sku: "GG-1L"},
      %{size: "1.75L", abv: "40.0", price: "64.99", stock_quantity: 40,  is_default: false, sku: "GG-175L"}
    ]
  },
  %{
    name: "Bacardi Superior White Rum",
    slug: "bacardi-superior-white-rum",
    category: "rum", brand: "bacardi",
    badge: "best_seller", is_featured: false, year: nil,
    description: "The world's most-awarded rum. Light, clean and versatile.",
    image_url: "https://images.unsplash.com/photo-1571104508999-893933ded431?w=600&auto=format&fit=crop",
    variants: [
      %{size: "700ML", abv: "37.5", price: "16.99", stock_quantity: 180, is_default: true,  sku: "BAC-700ML"},
      %{size: "1L",    abv: "37.5", price: "20.99", stock_quantity: 110, is_default: false, sku: "BAC-1L"}
    ]
  },
  %{
    name: "Tanqueray London Dry Gin",
    slug: "tanqueray-london-dry-gin",
    category: "gin", brand: "tanqueray",
    badge: nil, is_featured: true, year: nil,
    description: "Perfectly balanced with bold juniper notes and crisp citrus finish.",
    image_url: "https://images.unsplash.com/photo-1551538827-9c037cb4f32a?w=600&auto=format&fit=crop",
    variants: [
      %{size: "700ML", abv: "43.1", price: "21.99", stock_quantity: 95, is_default: true,  sku: "TAN-700ML"},
      %{size: "1L",    abv: "43.1", price: "27.99", stock_quantity: 60, is_default: false, sku: "TAN-1L"}
    ]
  },
  %{
    name: "Buffalo Trace Bourbon",
    slug: "buffalo-trace-bourbon",
    category: "whiskey", brand: "buffalo-trace",
    badge: "best_seller", is_featured: true, year: nil,
    description: "Deep amber colour. Complex aroma of vanilla, mint and molasses.",
    image_url: "https://images.unsplash.com/photo-1569529465841-dfecdab7503b?w=600&auto=format&fit=crop",
    variants: [
      %{size: "700ML", abv: "45.0", price: "28.99", stock_quantity: 55, is_default: true,  sku: "BT-700ML"},
      %{size: "1.75L", abv: "45.0", price: "54.99", stock_quantity: 25, is_default: false, sku: "BT-175L"}
    ]
  },
  %{
    name: "The Glenlivet 12 Year Old",
    slug: "glenlivet-12-year-old",
    category: "whiskey", brand: "glenlivet",
    badge: "limited_edition", is_featured: true, year: 2011,
    description: "The single malt that started it all. Light and floral with orchard fruit notes.",
    image_url: "https://images.unsplash.com/photo-1527281400683-1aae777175f8?w=600&auto=format&fit=crop",
    variants: [
      %{size: "700ML", abv: "40.0", price: "39.99", compare_price: "45.99", stock_quantity: 45, is_default: true,  sku: "GV12-700ML"},
      %{size: "1L",    abv: "40.0", price: "52.99", compare_price: "59.99", stock_quantity: 20, is_default: false, sku: "GV12-1L"}
    ]
  },
  %{
    name: "Jim Beam White Label Bourbon",
    slug: "jim-beam-white-label",
    category: "whiskey", brand: "jim-beam",
    badge: nil, is_featured: false, year: nil,
    description: "America's #1 selling bourbon. Four generations of family craftsmanship.",
    image_url: "https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=600&auto=format&fit=crop",
    variants: [
      %{size: "700ML", abv: "40.0", price: "17.99", stock_quantity: 200, is_default: true,  sku: "JB-700ML"},
      %{size: "1L",    abv: "40.0", price: "22.99", stock_quantity: 140, is_default: false, sku: "JB-1L"},
      %{size: "1.75L", abv: "40.0", price: "32.99", stock_quantity: 80,  is_default: false, sku: "JB-175L"}
    ]
  },
  %{
    name: "Patron Reposado Tequila",
    slug: "patron-reposado-tequila",
    category: "tequila", brand: "patron",
    badge: nil, is_featured: false, year: nil,
    description: "Rested in oak barrels for over two months. Complex with hints of oak and honey.",
    image_url: "https://images.unsplash.com/photo-1598373182133-52452f7691ef?w=600&auto=format&fit=crop",
    variants: [
      %{size: "700ML", abv: "40.0", price: "46.99", stock_quantity: 50, is_default: true, sku: "PAT-REP-700ML"}
    ]
  }
]

products =
  for data <- products_data do
    cat   = cats[data.category]
    brand = bs[data.brand]

    product = Seeds.Helpers.upsert_product(%{
      name:        data.name,
      slug:        data.slug,
      description: data.description,
      category_id: cat.id,
      brand_id:    brand.id,
      badge:       data.badge,
      image_url:   data.image_url,
      is_featured: data.is_featured,
      is_active:   true,
      year:        data.year
    })

    for v <- data.variants do
      Seeds.Helpers.upsert_variant(product.id, v)
    end

    IO.puts("  ✓ Product: #{data.name} (#{length(data.variants)} variants)")
    product
  end

# ---------------------------------------------------------------------------
# Admin user
# ---------------------------------------------------------------------------

Seeds.Helpers.upsert_user(%{
  email:      "admin@gmail.com",
  password:   "password",
  first_name: "Admin",
  last_name:  "Corino",
  is_admin:   true
})

IO.puts("  ✓ Admin user: admin@gmail.com / password")

# ---------------------------------------------------------------------------
# Sample customer + order (only if no orders exist yet)
# ---------------------------------------------------------------------------

customer = Seeds.Helpers.upsert_user(%{
  email:      "jane@example.com",
  password:   "password123",
  first_name: "Jane",
  last_name:  "Cooper"
})

unless Repo.exists?(from o in Order, where: o.payment_reference == "PAY-SEED-001") do
  [first_product | _] = products
  variant = Repo.preload(first_product, :variants).variants |> List.first()

  {:ok, order} =
    Orders.create_order(%{
      user_id:           customer.id,
      status:            "delivered",
      total_amount:      Decimal.mult(variant.price, 2),
      payment_method:    "paystack",
      payment_reference: "PAY-SEED-001",
      payment_status:    "paid",
      shipping_name:     "Jane Cooper",
      shipping_line1:    "7409 Mayfield Rd",
      shipping_city:     "Woodhaven",
      shipping_state:    "NY",
      shipping_zip:      "11421",
      shipping_country:  "US"
    })

  Orders.create_order_item(%{
    order_id:           order.id,
    product_variant_id: variant.id,
    product_name:       first_product.name,
    variant_sku:        variant.sku,
    variant_size:       variant.size,
    quantity:           2,
    unit_price:         variant.price,
    subtotal:           Decimal.mult(variant.price, 2)
  })

  IO.puts("  ✓ Sample customer + order seeded")
end

IO.puts("\n✅  Seeding complete!")
IO.puts("   #{length(products_data)} products · 12 brands · 1 admin · sample order")

alias Liquor.Repo
alias Liquor.Catalog.{Category, Brand}
alias Liquor.Accounts.User
alias Liquor.Settings.SiteSetting

IO.puts("🌱  Seeding database...")

upsert_category = fn attrs ->
  case Repo.get_by(Category, slug: attrs.slug) do
    nil ->
      %Category{}
      |> Category.changeset(attrs)
      |> Repo.insert!()

    existing ->
      existing
  end
end

upsert_brand = fn attrs ->
  case Repo.get_by(Brand, slug: attrs.slug) do
    nil ->
      %Brand{}
      |> Brand.changeset(attrs)
      |> Repo.insert!()

    existing ->
      existing
  end
end

upsert_user = fn attrs ->
  case Repo.get_by(User, email: attrs.email) do
    nil ->
      %User{}
      |> User.changeset(attrs)
      |> Repo.insert!()

    existing ->
      existing
  end
end

upsert_site_setting = fn key, value ->
  case Repo.get_by(SiteSetting, key: key) do
    nil ->
      %SiteSetting{}
      |> SiteSetting.changeset(%{key: key, value: value})
      |> Repo.insert!()

    existing ->
      existing
      |> SiteSetting.changeset(%{value: value})
      |> Repo.update!()
  end
end

# ---------------------------------------------------------------------------
# Categories
# ---------------------------------------------------------------------------

categories =
  for {name, slug, pos} <- [
        {"Spirits", "spirits", 1},
        {"Whiskey", "whiskey", 2},
        {"Wine", "wine", 3},
        {"Beer", "beer", 4},
        {"Gin", "gin", 5},
        {"Tequila", "tequila", 6},
        {"Rum", "rum", 7},
        {"Vodka", "vodka", 8},
        {"Cognac", "cognac", 9},
        {"Mezcal", "mezcal", 10}
      ] do
    cat =
      upsert_category.(%{
        name: name,
        slug: slug,
        position: pos,
        description: "Premium selection of #{name} from around the world.",
        image_url:
          "https://images.unsplash.com/photo-1569529465841-dfecdab7503b?w=400&auto=format&fit=crop"
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
        {"Jameson", "jameson", "Ireland"},
        {"Jack Daniel's", "jack-daniels", "USA"},
        {"Johnnie Walker", "johnnie-walker", "Scotland"},
        {"Hennessy", "hennessy", "France"},
        {"Patron", "patron", "Mexico"},
        {"Grey Goose", "grey-goose", "France"},
        {"Bacardi", "bacardi", "Bermuda"},
        {"Tanqueray", "tanqueray", "Scotland"},
        {"Buffalo Trace", "buffalo-trace", "USA"},
        {"Glenlivet", "glenlivet", "Scotland"},
        {"Heineken", "heineken", "Netherlands"},
        {"Jim Beam", "jim-beam", "USA"}
      ] do
    brand =
      upsert_brand.(%{
        name: name,
        slug: slug,
        country: country,
        description: "Premium #{name} – crafted with tradition since generations."
      })

    IO.puts("  ✓ Brand: #{name}")
    {slug, brand}
  end

_brands_by_slug = Map.new(brands)

# Products and variants intentionally omitted.
# Add your inventory manually or restore product seed data later.

# ---------------------------------------------------------------------------
# Admin user
# ---------------------------------------------------------------------------

upsert_user.(%{
  email: "admin@gmail.com",
  password: "password",
  first_name: "Admin",
  last_name: "User",
  role: "super_admin"
})

IO.puts("  ✓ Admin user: admin@gmail.com / password")

# ---------------------------------------------------------------------------
# Site settings
# ---------------------------------------------------------------------------

for {key, value} <- [
      {"store_till_number", ""},
      {"receipt_delivery_message", "For 24/7 doorstep delivery call 0724261261"}
    ] do
  upsert_site_setting.(key, value)
end

IO.puts("  ✓ Site settings seeded")

# Additional seed data intentionally omitted.
# Leave products and orders out for a fresh catalog setup.

IO.puts("\n✅  Seeding complete!")
IO.puts("   10 categories · 12 brands · 1 admin · site settings")

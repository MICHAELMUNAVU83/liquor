defmodule LiquorWeb.SitemapController do
  use LiquorWeb, :controller

  alias Liquor.Catalog
  alias Liquor.StoreConfig

  def index(conn, _params) do
    products = Catalog.list_products(active: true)
    base     = StoreConfig.site_url()

    static = [
      {base,              "daily",   "1.0"},
      {"#{base}/shop",    "daily",   "0.9"},
      {"#{base}/about",   "monthly", "0.6"},
      {"#{base}/contact", "monthly", "0.6"},
    ]

    product_entries =
      Enum.map(products, fn p ->
        {"#{base}/shop?search=#{URI.encode(p.name)}", "weekly", "0.7"}
      end)

    entries = static ++ product_entries

    url_tags =
      Enum.map_join(entries, "\n", fn {loc, freq, priority} ->
        """
          <url>
            <loc>#{loc}</loc>
            <changefreq>#{freq}</changefreq>
            <priority>#{priority}</priority>
          </url>
        """
      end)

    xml = """
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    #{url_tags}
    </urlset>
    """

    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, xml)
  end
end

defmodule Liquor.Settings do
  alias Liquor.Repo
  alias Liquor.Settings.SiteSetting
  alias Liquor.StoreConfig

  defp defaults do
    %{
      "store_name"          => &StoreConfig.name/0,
      "store_short_name"    => &StoreConfig.short_name/0,
      "store_tagline"       => &StoreConfig.tagline/0,
      "store_phone"         => &StoreConfig.phone/0,
      "store_email"         => &StoreConfig.email/0,
      "store_address"       => &StoreConfig.store_address/0,
      "store_map_query"     => &StoreConfig.map_query/0,
      "hours_weekday"       => &StoreConfig.hours_weekday/0,
      "hours_saturday"      => &StoreConfig.hours_saturday/0,
      "hours_sunday"        => &StoreConfig.hours_sunday/0,
      "site_url"            => &StoreConfig.site_url/0,
      "about_hero_heading"  => fn -> "Nairobi's Home for Premium Spirits & Wine" end,
      "about_hero_desc"     => fn -> "We bring the world's finest spirits, wines, and craft beers straight to your door. Whether you're stocking a home bar or searching for the perfect gift, our curated selection and knowledgeable team are here to help." end,
      "about_hero_image"    => fn -> "https://images.unsplash.com/photo-1566417713940-fe7c737a9ef2?w=900&auto=format&fit=crop" end,
      "about_mission"       => fn -> "Our mission is to connect people with exceptional drinks from around the world. We believe great occasions deserve great bottles, and we're committed to making premium spirits, wines, and beers accessible to everyone.\n\nFrom everyday favourites to rare collector's expressions, we hand-pick every product in our range for quality, provenance, and value — so you can shop with confidence." end,
      "about_values"        => fn -> "Quality first. Every product is verified for authenticity before it reaches our shelves. We work directly with distilleries, wineries, and trusted importers to guarantee provenance.\n\nCustomer obsession. Fast delivery, easy returns, and a team of experts ready to answer your questions — we measure success by how happy you are with every order." end,
      "homepage_featured_ids" => fn -> "" end,
      # Hero banners
      "hero_main_product_id"  => fn -> "" end,
      "hero_tile1_product_id" => fn -> "" end,
      "hero_tile2_product_id" => fn -> "" end,
      "hero_main_label"    => fn -> "Today's Highlights" end,
      "hero_main_title"    => fn -> "Whiskies of The Month" end,
      "hero_main_price"    => fn -> "KSh 3,999" end,
      "hero_main_image"    => fn -> "https://images.unsplash.com/photo-1569529465841-dfecdab7503b?w=900&auto=format&fit=crop" end,
      "hero_main_link"     => fn -> "/shop" end,
      "hero_tile1_label"   => fn -> "Black Friday" end,
      "hero_tile1_title"   => fn -> "Shop & Save" end,
      "hero_tile1_subtitle"=> fn -> "selected bourbons" end,
      "hero_tile1_image"   => fn -> "https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=600&auto=format&fit=crop" end,
      "hero_tile1_link"    => fn -> "/shop" end,
      "hero_tile2_title"   => fn -> "Exclusive Offer" end,
      "hero_tile2_price"   => fn -> "KSh 2,499" end,
      "hero_tile2_image"   => fn -> "https://images.unsplash.com/photo-1527281400683-1aae777175f8?w=600&auto=format&fit=crop" end,
      "hero_tile2_link"    => fn -> "/shop" end,
      "social_instagram"    => fn -> "" end,
      "social_facebook"     => fn -> "" end,
      "social_twitter"      => fn -> "" end,
      "social_whatsapp"     => fn -> "" end,
      # Payments
      "paystack_enabled"    => fn -> "false" end,
      "paystack_secret_key" => fn -> "" end,
      "whatsapp_order_phone" => fn -> "" end,
    }
  end

  def all do
    db = Repo.all(SiteSetting) |> Map.new(fn s -> {s.key, s.value} end)
    Map.new(defaults(), fn {k, default_fn} ->
      v = Map.get(db, k)
      {k, if(is_nil(v) || v == "", do: default_fn.(), else: v)}
    end)
  end

  def get(key, default \\ nil) do
    fallback = case Map.get(defaults(), key) do
      nil -> default
      f   -> f.()
    end
    case Repo.get_by(SiteSetting, key: key) do
      nil               -> fallback
      %{value: nil}     -> fallback
      %{value: ""}      -> fallback
      %{value: v}       -> v
    end
  end

  def set(key, value) do
    case Repo.get_by(SiteSetting, key: key) do
      nil      -> %SiteSetting{} |> SiteSetting.changeset(%{key: key, value: value}) |> Repo.insert()
      existing -> existing |> SiteSetting.changeset(%{value: value}) |> Repo.update()
    end
  end

  def set_many(map) when is_map(map) do
    Enum.each(map, fn {k, v} -> set(k, v) end)
    :ok
  end
end

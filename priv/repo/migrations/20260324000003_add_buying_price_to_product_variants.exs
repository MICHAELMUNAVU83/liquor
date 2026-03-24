defmodule Liquor.Repo.Migrations.AddBuyingPriceToProductVariants do
  use Ecto.Migration

  def change do
    alter table(:product_variants) do
      add :buying_price, :decimal, precision: 10, scale: 2
    end
  end
end

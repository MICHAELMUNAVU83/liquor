defmodule Liquor.Repo.Migrations.CreateProductVariants do
  use Ecto.Migration

  def change do
    create table(:product_variants) do
      add :product_id,     references(:products, on_delete: :delete_all), null: false
      add :sku,            :string,  null: false
      add :size,           :string,  null: false   # e.g. "750ML", "1L", "1.75L"
      add :abv,            :decimal, precision: 5, scale: 2  # alcohol by volume %
      add :price,          :decimal, precision: 10, scale: 2, null: false
      add :compare_price,  :decimal, precision: 10, scale: 2  # original/crossed-out price
      add :stock_quantity, :integer, default: 0, null: false
      add :is_default,     :boolean, default: false, null: false

      timestamps()
    end

    create unique_index(:product_variants, [:sku])
    create index(:product_variants, [:product_id])
  end
end

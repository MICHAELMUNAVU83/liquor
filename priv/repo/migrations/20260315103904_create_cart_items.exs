defmodule Liquor.Repo.Migrations.CreateCartItems do
  use Ecto.Migration

  def change do
    create table(:cart_items) do
      add :cart_id,            references(:carts,            on_delete: :delete_all), null: false
      add :product_variant_id, references(:product_variants, on_delete: :delete_all), null: false
      add :quantity,           :integer, null: false, default: 1

      timestamps()
    end

    create index(:cart_items, [:cart_id])
    create unique_index(:cart_items, [:cart_id, :product_variant_id])
  end
end

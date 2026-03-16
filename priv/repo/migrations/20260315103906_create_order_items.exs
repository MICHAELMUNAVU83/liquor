defmodule Liquor.Repo.Migrations.CreateOrderItems do
  use Ecto.Migration

  def change do
    create table(:order_items) do
      add :order_id,           references(:orders,           on_delete: :delete_all), null: false
      add :product_variant_id, references(:product_variants, on_delete: :nilify_all)
      # Snapshot of product details at time of purchase
      add :product_name,       :string,  null: false
      add :variant_sku,        :string
      add :variant_size,       :string
      add :quantity,           :integer, null: false
      add :unit_price,         :decimal, precision: 10, scale: 2, null: false
      add :subtotal,           :decimal, precision: 10, scale: 2, null: false

      timestamps()
    end

    create index(:order_items, [:order_id])
  end
end

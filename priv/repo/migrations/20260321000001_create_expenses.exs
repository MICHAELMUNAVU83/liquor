defmodule Liquor.Repo.Migrations.CreateExpenses do
  use Ecto.Migration

  def change do
    create table(:expenses) do
      add :description,  :string,  null: false
      add :category,     :string,  null: false, default: "other"
      add :amount,       :decimal, precision: 10, scale: 2, null: false
      add :expense_date, :date,    null: false

      # stock-restock details (optional)
      add :product_name, :string
      add :variant_sku,  :string
      add :quantity,     :integer
      add :unit_cost,    :decimal, precision: 10, scale: 2

      add :notes, :text

      timestamps()
    end

    create index(:expenses, [:category])
    create index(:expenses, [:expense_date])
  end
end

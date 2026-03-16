defmodule Liquor.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name,         :string,  null: false
      add :slug,         :string,  null: false
      add :description,  :text
      add :category_id,  references(:categories, on_delete: :restrict), null: false
      add :brand_id,     references(:brands,     on_delete: :nilify_all)
      add :badge,        :string   # "best_seller" | "limited_edition" | nil
      add :image_url,    :string
      add :is_featured,  :boolean, default: false, null: false
      add :is_active,    :boolean, default: true,  null: false
      add :year,         :integer  # vintage year

      timestamps()
    end

    create unique_index(:products, [:slug])
    create index(:products, [:category_id])
    create index(:products, [:brand_id])
    create index(:products, [:is_featured])
    create index(:products, [:is_active])
  end
end

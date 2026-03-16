defmodule Liquor.Repo.Migrations.CreateReviews do
  use Ecto.Migration

  def change do
    create table(:reviews) do
      add :product_id, references(:products, on_delete: :delete_all), null: false
      add :user_id,    references(:users,    on_delete: :nilify_all)
      add :rating,     :integer, null: false   # 1–5
      add :title,      :string
      add :body,       :text
      add :is_verified, :boolean, default: false, null: false  # verified purchase

      timestamps()
    end

    create index(:reviews, [:product_id])
    create index(:reviews, [:user_id])
    create unique_index(:reviews, [:product_id, :user_id])
  end
end

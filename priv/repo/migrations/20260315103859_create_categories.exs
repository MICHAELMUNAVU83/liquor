defmodule Liquor.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :name,        :string,  null: false
      add :slug,        :string,  null: false
      add :description, :text
      add :image_url,   :string
      add :position,    :integer, default: 0

      timestamps()
    end

    create unique_index(:categories, [:slug])
  end
end

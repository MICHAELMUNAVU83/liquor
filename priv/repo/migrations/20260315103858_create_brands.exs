defmodule Liquor.Repo.Migrations.CreateBrands do
  use Ecto.Migration

  def change do
    create table(:brands) do
      add :name,        :string, null: false
      add :slug,        :string, null: false
      add :description, :text
      add :logo_url,    :string
      add :country,     :string

      timestamps()
    end

    create unique_index(:brands, [:slug])
  end
end

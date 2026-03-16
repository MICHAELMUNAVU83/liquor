defmodule Liquor.Repo.Migrations.CreateAddresses do
  use Ecto.Migration

  def change do
    create table(:addresses) do
      add :user_id,    references(:users, on_delete: :delete_all), null: false
      add :label,      :string, default: "Home"  # "Home" | "Work" | etc.
      add :line1,      :string, null: false
      add :line2,      :string
      add :city,       :string, null: false
      add :state,      :string
      add :zip,        :string
      add :country,    :string, null: false, default: "US"
      add :is_default, :boolean, default: false, null: false

      timestamps()
    end

    create index(:addresses, [:user_id])
  end
end

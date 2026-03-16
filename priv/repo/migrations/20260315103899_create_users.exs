defmodule Liquor.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email,          :string,  null: false
      add :password_hash,  :string,  null: false
      add :first_name,     :string
      add :last_name,      :string
      add :phone,          :string
      add :is_admin,       :boolean, default: false, null: false
      add :is_active,      :boolean, default: true,  null: false

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end

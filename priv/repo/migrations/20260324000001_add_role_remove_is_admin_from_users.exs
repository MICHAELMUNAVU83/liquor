defmodule Liquor.Repo.Migrations.AddRoleRemoveIsAdminFromUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :role, :string
    end

    execute "UPDATE users SET role = 'super_admin' WHERE is_admin = true"

    alter table(:users) do
      remove :is_admin
    end
  end

  def down do
    alter table(:users) do
      add :is_admin, :boolean, default: false, null: false
    end

    execute "UPDATE users SET is_admin = true WHERE role IS NOT NULL"

    alter table(:users) do
      remove :role
    end
  end
end

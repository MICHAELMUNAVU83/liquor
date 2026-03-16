defmodule Liquor.Repo.Migrations.CreateCarts do
  use Ecto.Migration

  def change do
    create table(:carts) do
      add :user_id,    references(:users, on_delete: :delete_all)  # nil = guest
      add :session_id, :string  # used for guest carts

      timestamps()
    end

    create index(:carts, [:user_id])
    create index(:carts, [:session_id])
  end
end

defmodule Liquor.Repo.Migrations.CreateCashRegisters do
  use Ecto.Migration

  def change do
    create table(:cash_registers) do
      add :open_amount,    :decimal, precision: 10, scale: 2, null: false
      add :close_amount,   :decimal, precision: 10, scale: 2
      add :status,         :string,  default: "open", null: false
      add :notes,          :text
      add :opened_at,      :utc_datetime, null: false
      add :closed_at,      :utc_datetime
      add :opened_by_id,   references(:users, on_delete: :nilify_all)

      timestamps()
    end

    create table(:cash_register_expenses) do
      add :cash_register_id, references(:cash_registers, on_delete: :delete_all), null: false
      add :description,      :string, null: false
      add :amount,           :decimal, precision: 10, scale: 2, null: false
      add :notes,            :text

      timestamps()
    end

    create index(:cash_register_expenses, [:cash_register_id])

    alter table(:orders) do
      add :cash_register_id, references(:cash_registers, on_delete: :nilify_all)
    end

    create index(:orders, [:cash_register_id])
  end
end

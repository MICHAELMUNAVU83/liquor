defmodule Liquor.Repo.Migrations.AddCustomerFieldsToOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :customer_email, :string
      add :customer_phone, :string
    end
  end
end

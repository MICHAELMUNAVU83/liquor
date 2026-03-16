defmodule Liquor.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add :user_id,            references(:users, on_delete: :nilify_all)
      add :status,             :string,  null: false, default: "pending"
      # pending | processing | shipped | delivered | cancelled | refunded
      add :total_amount,       :decimal, precision: 10, scale: 2, null: false
      add :shipping_amount,    :decimal, precision: 10, scale: 2, default: "0.00"
      add :discount_amount,    :decimal, precision: 10, scale: 2, default: "0.00"

      # Shipping snapshot (denormalised so address changes don't break history)
      add :shipping_name,      :string
      add :shipping_line1,     :string
      add :shipping_line2,     :string
      add :shipping_city,      :string
      add :shipping_state,     :string
      add :shipping_zip,       :string
      add :shipping_country,   :string

      # Payment
      add :payment_method,     :string   # "paystack" | "stripe" | "cod"
      add :payment_reference,  :string
      add :payment_status,     :string,  default: "unpaid"
      # unpaid | paid | refunded

      add :notes,              :text

      timestamps()
    end

    create index(:orders, [:user_id])
    create index(:orders, [:status])
    create index(:orders, [:payment_reference])
  end
end

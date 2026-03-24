defmodule Liquor.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending processing shipped delivered cancelled refunded)
  @payment_statuses ~w(unpaid paid refunded)

  schema "orders" do
    field :status,           :string, default: "pending"
    field :total_amount,     :decimal
    field :shipping_amount,  :decimal, default: Decimal.new("0.00")
    field :discount_amount,  :decimal, default: Decimal.new("0.00")
    field :shipping_name,    :string
    field :shipping_line1,   :string
    field :shipping_line2,   :string
    field :shipping_city,    :string
    field :shipping_state,   :string
    field :shipping_zip,     :string
    field :shipping_country, :string
    field :payment_method,   :string
    field :payment_reference,:string
    field :payment_status,   :string, default: "unpaid"
    field :customer_email,   :string
    field :customer_phone,   :string
    field :notes,            :string

    belongs_to :user,          Liquor.Accounts.User
    belongs_to :cash_register, Liquor.Cash.CashRegister
    has_many   :items,         Liquor.Orders.OrderItem, foreign_key: :order_id

    timestamps()
  end

  def changeset(order, attrs) do
    order
    |> cast(attrs, [:user_id, :cash_register_id, :status, :total_amount, :shipping_amount, :discount_amount,
                    :shipping_name, :shipping_line1, :shipping_line2, :shipping_city,
                    :shipping_state, :shipping_zip, :shipping_country,
                    :payment_method, :payment_reference, :payment_status,
                    :customer_email, :customer_phone, :notes])
    |> validate_required([:total_amount, :status])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:payment_status, @payment_statuses)
  end

  def status_color("pending"),    do: "bg-yellow-100 text-yellow-700"
  def status_color("processing"), do: "bg-blue-100 text-blue-700"
  def status_color("shipped"),    do: "bg-indigo-100 text-indigo-700"
  def status_color("delivered"),  do: "bg-emerald-100 text-emerald-700"
  def status_color("cancelled"),  do: "bg-red-100 text-red-600"
  def status_color("refunded"),   do: "bg-zinc-100 text-zinc-600"
  def status_color(_),            do: "bg-zinc-100 text-zinc-500"
end

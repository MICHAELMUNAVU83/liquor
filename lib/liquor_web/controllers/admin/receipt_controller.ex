defmodule LiquorWeb.Admin.ReceiptController do
  use LiquorWeb, :controller

  alias Liquor.Orders
  alias Liquor.Settings

  def show(conn, %{"id" => id}) do
    order = Orders.get_order!(id)

    receipt_settings = %{
      store_name: Settings.get("store_name"),
      store_address: Settings.get("store_address"),
      store_phone: Settings.get("store_phone"),
      store_till_number: Settings.get("store_till_number"),
      receipt_delivery_message: Settings.get("receipt_delivery_message")
    }

    render(conn, :show, order: order, receipt_settings: receipt_settings, layout: false)
  end
end

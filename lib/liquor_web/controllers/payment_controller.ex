defmodule LiquorWeb.PaymentController do
  use LiquorWeb, :controller

  alias Liquor.{Paystack, Orders, Gmail}

  @doc "Paystack callback — verifies payment, marks order paid, sends emails."
  def callback(conn, %{"reference" => reference}) do
    case Paystack.verify(reference) do
      {:ok, _data} ->
        case Orders.get_order_by_reference(reference) do
          nil ->
            conn
            |> put_flash(:error, "Order not found for reference #{reference}.")
            |> redirect(to: "/")

          order ->
            {:ok, order} =
              Orders.update_order(order, %{payment_status: "paid", status: "processing"})

            order = Liquor.Repo.preload(order, [:items])

            customer_name  = order.shipping_name  || "Customer"
            customer_phone = order.customer_phone || ""

            # Send customer confirmation email
            if order.customer_email && order.customer_email != "" do
              Task.start(fn ->
                Gmail.send_order_confirmation(order.customer_email, customer_name, order)
              end)
            end

            # Send admin alert email
            Task.start(fn ->
              Gmail.send_admin_order_alert(order, customer_name, customer_phone)
            end)

            conn
            |> redirect(to: "/checkout/success?ref=#{reference}")
        end

      {:error, reason} ->
        conn
        |> put_flash(:error, "Payment verification failed: #{reason}")
        |> redirect(to: "/checkout")
    end
  end

  def callback(conn, _params) do
    conn
    |> put_flash(:error, "Invalid payment callback.")
    |> redirect(to: "/")
  end
end

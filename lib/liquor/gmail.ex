defmodule Liquor.Gmail do
  @moduledoc """
  Sends transactional emails via the Nexus email API.
  All outgoing emails use the shared branded HTML wrapper.
  """

  require Logger

  @api_url "https://app.nexuscale.ai/api/v1/email/send"
  @from_email "notifications@callwisely.ai"
  @brand_color "#f97316"
  @brand_name "The Mint Liquor Store"
  @tagline "Nairobi's Premier Spirits & Wine"
  @support_email "info@themintliquorstore.co.ke"
  @site_url "https://www.themint.co.ke"

  # ── Public API ────────────────────────────────────────────────────────────

  def send_email(to_email, subject, html_body) do
    payload = %{
      from_email: @from_email,
      to: to_email,
      subject: subject,
      body: html_body,
      html_body: html_body
    }

    Logger.info("[Gmail] Sending \"#{subject}\" → #{to_email}")

    case Req.post(@api_url,
           headers: [{"Content-Type", "application/json"}],
           json: payload,
           receive_timeout: 60_000
         ) do
      {:ok, %{status: status}} when status in 200..299 ->
        Logger.info("[Gmail] Delivered \"#{subject}\" → #{to_email} (HTTP #{status})")
        {:ok, status}

      {:ok, %{status: status, body: body}} ->
        Logger.error(
          "[Gmail] API error #{status} for \"#{subject}\" → #{to_email}: #{inspect(body)}"
        )
        {:error, {status, body}}

      {:error, reason} ->
        Logger.error(
          "[Gmail] HTTP error sending \"#{subject}\" → #{to_email}: #{inspect(reason)}"
        )
        {:error, reason}
    end
  end

  # ── Transactional email templates ─────────────────────────────────────────

  @doc "Order confirmation email sent to the customer after payment."
  def send_order_confirmation(to_email, customer_name, order) do
    items = Map.get(order, :items, [])

    items_html =
      items
      |> Enum.map(fn i ->
        qty   = i.quantity || 1
        price = i.unit_price || Decimal.new("0")
        total = Decimal.mult(Decimal.new(to_string(price)), Decimal.new(qty))

        """
        <tr>
          <td style="padding:10px 0;border-bottom:1px solid #f0ede8;font-size:14px;color:#111;">#{i.product_name}<br><span style="font-size:11px;color:#999;">#{i.variant_size || ""}</span></td>
          <td style="padding:10px 0;border-bottom:1px solid #f0ede8;text-align:center;font-size:14px;color:#555;">#{qty}</td>
          <td style="padding:10px 0;border-bottom:1px solid #f0ede8;text-align:right;font-size:14px;font-weight:700;color:#111;">KSh #{Decimal.round(total, 2)}</td>
        </tr>
        """
      end)
      |> Enum.join("")

    reference = order.payment_reference || "—"

    inner = """
    <tr>
      <td style="padding:40px 40px 24px;">
        <p style="margin:0 0 8px;font-size:22px;font-weight:700;color:#111;">Order Confirmed! 🎉</p>
        <p style="margin:0 0 24px;font-size:15px;color:#555;line-height:1.6;">
          Hi #{customer_name}, thank you for your order at The Mint Liquor Store.
          We've received your payment and are processing your order now.
        </p>
        #{info_box([{"Order Reference", reference}, {"Total Amount", "KSh #{Decimal.round(order.total_amount, 2)}"}])}
        <p style="margin:0 0 12px;font-size:14px;font-weight:600;color:#111;">Order Summary</p>
        <table width="100%" cellpadding="0" cellspacing="0" role="presentation"
               style="background:#faf9f7;border-radius:12px;padding:4px 20px;margin:0 0 24px;">
          <thead>
            <tr>
              <th style="padding:10px 0;text-align:left;font-size:11px;text-transform:uppercase;letter-spacing:1px;color:#999;">Product</th>
              <th style="padding:10px 0;text-align:center;font-size:11px;text-transform:uppercase;letter-spacing:1px;color:#999;">Qty</th>
              <th style="padding:10px 0;text-align:right;font-size:11px;text-transform:uppercase;letter-spacing:1px;color:#999;">Total</th>
            </tr>
          </thead>
          <tbody>#{items_html}</tbody>
        </table>
        <p style="margin:0 0 28px;font-size:13px;color:#999;">
          We'll be in touch shortly to confirm delivery details.
          Questions? Reply to this email or reach us at
          <a href="mailto:#{@support_email}" style="color:#{@brand_color};">#{@support_email}</a>.
        </p>
        #{cta_button("Visit Our Store", "#{@site_url}/shop")}
      </td>
    </tr>
    """

    send_email(
      to_email,
      "Order Confirmed — #{reference} | The Mint Liquor Store",
      branded_email(inner, preview: "Your order is confirmed!", header_label: "Order Confirmation")
    )
  end

  @doc "New order alert sent to the admin/store."
  def send_admin_order_alert(order, customer_name, customer_phone) do
    reference = order.payment_reference || "—"
    items = Map.get(order, :items, [])

    items_html =
      items
      |> Enum.map(fn i ->
        """
        <tr>
          <td style="padding:8px 0;border-bottom:1px solid #f0ede8;font-size:13px;color:#111;">#{i.product_name} #{i.variant_size || ""}</td>
          <td style="padding:8px 0;border-bottom:1px solid #f0ede8;text-align:center;font-size:13px;color:#555;">#{i.quantity}</td>
          <td style="padding:8px 0;border-bottom:1px solid #f0ede8;text-align:right;font-size:13px;font-weight:700;color:#111;">KSh #{Decimal.round(i.subtotal, 2)}</td>
        </tr>
        """
      end)
      |> Enum.join("")

    inner = """
    <tr>
      <td style="padding:40px 40px 24px;">
        <p style="margin:0 0 8px;font-size:22px;font-weight:700;color:#111;">New Order Received 🛒</p>
        <p style="margin:0 0 24px;font-size:15px;color:#555;line-height:1.6;">
          A new order has been placed and payment confirmed.
        </p>
        #{info_box([
          {"Reference", reference},
          {"Customer", customer_name},
          {"Phone", customer_phone || "—"},
          {"Delivery", "#{order.shipping_line1 || ""}, #{order.shipping_city || ""}"},
          {"Total", "KSh #{Decimal.round(order.total_amount, 2)}"}
        ])}
        <table width="100%" cellpadding="0" cellspacing="0" role="presentation"
               style="background:#faf9f7;border-radius:12px;padding:4px 20px;margin:0 0 24px;">
          <thead>
            <tr>
              <th style="padding:8px 0;text-align:left;font-size:11px;text-transform:uppercase;letter-spacing:1px;color:#999;">Product</th>
              <th style="padding:8px 0;text-align:center;font-size:11px;text-transform:uppercase;letter-spacing:1px;color:#999;">Qty</th>
              <th style="padding:8px 0;text-align:right;font-size:11px;text-transform:uppercase;letter-spacing:1px;color:#999;">Total</th>
            </tr>
          </thead>
          <tbody>#{items_html}</tbody>
        </table>
        #{cta_button("View in Admin", "#{@site_url}/admin/orders")}
      </td>
    </tr>
    """

    send_email(
      @support_email,
      "New Order #{reference} — The Mint Admin",
      branded_email(inner, preview: "New order received!", header_label: "Admin Alert")
    )
  end

  # ── Branded template helpers ───────────────────────────────────────────────

  @doc "Wraps any inner HTML in the full branded email shell."
  def branded_email(inner_html, opts \\ []) do
    preview_text = Keyword.get(opts, :preview, "")
    header_label = Keyword.get(opts, :header_label, "")
    year = Date.utc_today().year

    """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width,initial-scale=1" />
      <meta http-equiv="X-UA-Compatible" content="IE=edge" />
      <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap');
      </style>
      <title>#{@brand_name}</title>
      #{if preview_text != "", do: "<div style=\"display:none;max-height:0;overflow:hidden;\">#{preview_text}</div>", else: ""}
    </head>
    <body style="margin:0;padding:0;background-color:#f3f4f6;font-family:'Inter',Arial,sans-serif;-webkit-font-smoothing:antialiased;">

    <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="background:#f3f4f6;padding:40px 16px;">
      <tr>
        <td align="center">
          <table width="600" cellpadding="0" cellspacing="0" role="presentation"
                 style="max-width:600px;width:100%;background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">

            <!-- ── HEADER ── -->
            <tr>
              <td style="background:#{@brand_color};padding:32px 40px;text-align:center;">
                #{if header_label != "", do: "<p style=\"margin:0 0 6px;font-size:11px;font-weight:600;letter-spacing:3px;text-transform:uppercase;color:rgba(255,255,255,0.7);\">#{header_label}</p>", else: ""}
                <h1 style="margin:0;font-family:'Inter',Arial,sans-serif;font-size:26px;font-weight:800;color:#ffffff;letter-spacing:-0.5px;">
                  The Mint <span style="color:rgba(255,255,255,0.8);">Liquor Store</span>
                </h1>
                <p style="margin:6px 0 0;font-size:12px;color:rgba(255,255,255,0.7);letter-spacing:1px;text-transform:uppercase;">
                  #{@tagline}
                </p>
              </td>
            </tr>

            <!-- ── BODY ── -->
            #{inner_html}

            <!-- ── FOOTER ── -->
            <tr>
              <td style="background:#111827;padding:32px 40px;">
                <table width="100%" cellpadding="0" cellspacing="0" role="presentation">
                  <tr>
                    <td align="center" style="padding-bottom:16px;">
                      <p style="margin:0;font-size:18px;font-weight:800;color:#ffffff;">
                        The Mint <span style="color:#{@brand_color};">Liquor Store</span>
                      </p>
                      <p style="margin:4px 0 0;font-size:11px;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,0.4);">
                        #{@tagline}
                      </p>
                    </td>
                  </tr>
                  <tr>
                    <td align="center" style="padding-bottom:16px;">
                      <a href="#{@site_url}/shop" style="display:inline-block;margin:0 10px;color:rgba(255,255,255,0.5);font-size:12px;text-decoration:none;">Shop Online</a>
                      <span style="color:rgba(255,255,255,0.2);">·</span>
                      <a href="mailto:#{@support_email}" style="display:inline-block;margin:0 10px;color:rgba(255,255,255,0.5);font-size:12px;text-decoration:none;">Support</a>
                    </td>
                  </tr>
                  <tr>
                    <td align="center">
                      <p style="margin:0;font-size:11px;color:rgba(255,255,255,0.25);">
                        © #{year} #{@brand_name}. All rights reserved.
                      </p>
                      <p style="margin:6px 0 0;font-size:11px;color:rgba(255,255,255,0.2);">TRM Mall, Thika Road, Nairobi, Kenya</p>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>

          </table>
        </td>
      </tr>
    </table>

    </body>
    </html>
    """
  end

  @doc "Renders a prominent CTA button."
  def cta_button(label, url) do
    """
    <table cellpadding="0" cellspacing="0" role="presentation" style="margin:0 auto;">
      <tr>
        <td style="border-radius:50px;background:#{@brand_color};">
          <a href="#{url}"
             style="display:inline-block;padding:14px 36px;font-size:14px;font-weight:700;color:#ffffff;text-decoration:none;letter-spacing:0.5px;border-radius:50px;">
            #{label}
          </a>
        </td>
      </tr>
    </table>
    """
  end

  @doc "Renders a key-value info box."
  def info_box(rows) do
    rows_html =
      rows
      |> Enum.map(fn {label, value} ->
        """
        <tr>
          <td style="padding:10px 0;border-bottom:1px solid #f0ede8;">
            <span style="font-size:12px;color:#999;text-transform:uppercase;letter-spacing:0.8px;">#{label}</span>
          </td>
          <td style="padding:10px 0;border-bottom:1px solid #f0ede8;text-align:right;">
            <span style="font-size:14px;font-weight:700;color:#111;">#{value}</span>
          </td>
        </tr>
        """
      end)
      |> Enum.join("")

    """
    <table width="100%" cellpadding="0" cellspacing="0" role="presentation"
           style="background:#faf9f7;border-radius:12px;padding:4px 20px;margin:0 0 24px;">
      #{rows_html}
    </table>
    """
  end

  @doc "Renders a divider rule."
  def divider do
    """
    <tr>
      <td style="padding:0 40px;">
        <div style="height:1px;background:#f0ede8;"></div>
      </td>
    </tr>
    """
  end
end

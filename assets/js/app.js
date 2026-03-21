import "phoenix_html"
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"
import { CartSync } from "./cart"
import { RevenueChart, StatusChart, TopProductsChart } from "./charts"

// ── LiveSocket ────────────────────────────────────────────────────

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: {
    CartSync,
    RevenueChart,
    StatusChart,
    TopProductsChart,
  }
})

// ── Progress bar ──────────────────────────────────────────────────

topbar.config({ barColors: { 0: "#f59e0b" }, shadowColor: "rgba(0,0,0,.2)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop",  _info => topbar.hide())

// ── Connect ───────────────────────────────────────────────────────

liveSocket.connect()
window.liveSocket = liveSocket

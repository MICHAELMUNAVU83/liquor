import "phoenix_html"
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"
import { CartSync } from "./cart"
import { RevenueChart, StatusChart, TopProductsChart } from "./charts"

// ── Age Gate hook ─────────────────────────────────────────────────
// On mount: if localStorage already has the flag, tell the server to skip the modal.
// On "store_age_verified" event from server: write the flag to localStorage.

const AgeGate = {
  mounted() {
    if (localStorage.getItem("age_verified") === "true") {
      this.pushEvent("age_already_verified", {})
    }
    this.handleEvent("store_age_verified", () => {
      localStorage.setItem("age_verified", "true")
    })
  }
}

// ── LiveSocket ────────────────────────────────────────────────────

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: {
    AgeGate,
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

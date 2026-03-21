import Chart from "../vendor/chartjs"

// ── Revenue Line Chart (last 6 months) ────────────────────────────
export const RevenueChart = {
  mounted() {
    const labels  = JSON.parse(this.el.dataset.labels  || "[]")
    const values  = JSON.parse(this.el.dataset.values  || "[]")

    this.chart = new Chart(this.el, {
      type: "line",
      data: {
        labels,
        datasets: [{
          label: "Revenue (KSh)",
          data: values,
          borderColor: "#f59e0b",
          backgroundColor: "rgba(245,158,11,0.12)",
          borderWidth: 2.5,
          pointBackgroundColor: "#f59e0b",
          pointRadius: 4,
          tension: 0.4,
          fill: true,
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              label: ctx => `KSh ${Number(ctx.raw).toLocaleString()}`
            }
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              callback: v => `KSh ${Number(v).toLocaleString()}`,
              maxTicksLimit: 5,
              font: { size: 11 }
            },
            grid: { color: "rgba(0,0,0,0.05)" }
          },
          x: {
            ticks: { font: { size: 11 } },
            grid: { display: false }
          }
        }
      }
    })
  },

  updated() {
    const labels = JSON.parse(this.el.dataset.labels || "[]")
    const values = JSON.parse(this.el.dataset.values || "[]")
    this.chart.data.labels = labels
    this.chart.data.datasets[0].data = values
    this.chart.update()
  },

  destroyed() { this.chart?.destroy() }
}

// ── Orders by Status Doughnut ──────────────────────────────────────
export const StatusChart = {
  mounted() {
    const labels = JSON.parse(this.el.dataset.labels || "[]")
    const values = JSON.parse(this.el.dataset.values || "[]")

    const palette = ["#f59e0b","#3b82f6","#10b981","#ef4444","#8b5cf6","#06b6d4"]

    this.chart = new Chart(this.el, {
      type: "doughnut",
      data: {
        labels,
        datasets: [{
          data: values,
          backgroundColor: palette.slice(0, labels.length),
          borderWidth: 2,
          borderColor: "#fff",
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        cutout: "65%",
        plugins: {
          legend: {
            position: "bottom",
            labels: { font: { size: 11 }, padding: 12, usePointStyle: true }
          }
        }
      }
    })
  },

  updated() {
    const labels = JSON.parse(this.el.dataset.labels || "[]")
    const values = JSON.parse(this.el.dataset.values || "[]")
    this.chart.data.labels = labels
    this.chart.data.datasets[0].data = values
    this.chart.update()
  },

  destroyed() { this.chart?.destroy() }
}

// ── Top Products Bar Chart ─────────────────────────────────────────
export const TopProductsChart = {
  mounted() {
    const labels = JSON.parse(this.el.dataset.labels || "[]")
    const values = JSON.parse(this.el.dataset.values || "[]")

    this.chart = new Chart(this.el, {
      type: "bar",
      data: {
        labels,
        datasets: [{
          label: "Revenue (KSh)",
          data: values,
          backgroundColor: "rgba(245,158,11,0.8)",
          borderColor: "#f59e0b",
          borderWidth: 1.5,
          borderRadius: 6,
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        indexAxis: "y",
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              label: ctx => `KSh ${Number(ctx.raw).toLocaleString()}`
            }
          }
        },
        scales: {
          x: {
            beginAtZero: true,
            ticks: {
              callback: v => `KSh ${Number(v).toLocaleString()}`,
              maxTicksLimit: 5,
              font: { size: 11 }
            },
            grid: { color: "rgba(0,0,0,0.05)" }
          },
          y: {
            ticks: { font: { size: 11 } },
            grid: { display: false }
          }
        }
      }
    })
  },

  updated() {
    const labels = JSON.parse(this.el.dataset.labels || "[]")
    const values = JSON.parse(this.el.dataset.values || "[]")
    this.chart.data.labels = labels
    this.chart.data.datasets[0].data = values
    this.chart.update()
  },

  destroyed() { this.chart?.destroy() }
}

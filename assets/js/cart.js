// ─────────────────────────────────────────────────────────────────
// Corino Cart  –  localStorage + slide-in drawer + LiveView sync
// ─────────────────────────────────────────────────────────────────

const CART_KEY = "corino_cart";

// ── Storage ───────────────────────────────────────────────────────

export function getCart() {
  try { return JSON.parse(localStorage.getItem(CART_KEY) || "[]"); }
  catch { return []; }
}

export function saveCart(items) {
  localStorage.setItem(CART_KEY, JSON.stringify(items));
  updateAllBadges(items);
}

export function cartCount(items) {
  return (items || getCart()).reduce((s, i) => s + (i.quantity || 1), 0);
}

// ── Badge management ──────────────────────────────────────────────

function updateAllBadges(items) {
  const count = cartCount(items || getCart());
  document.querySelectorAll("[data-cart-count]").forEach(el => {
    el.textContent = String(count);
    el.closest("[data-cart-badge-wrapper]")
      ?.classList.toggle("opacity-0", count === 0);
  });
}

// ── Global add-to-cart ────────────────────────────────────────────
// Accepts a full item object:
//   { variant_id, name, size, price, image_url }
// or just a variant_id integer (legacy)

window.cartAddItem = function (itemOrId, quantity = 1) {
  const isObj = typeof itemOrId === "object" && itemOrId !== null;
  const vid   = isObj ? itemOrId.variant_id : itemOrId;
  if (!vid) return;

  const cart = getCart();
  const idx  = cart.findIndex(i => i.variant_id === vid);

  if (idx >= 0) {
    cart[idx].quantity += quantity;
    // refresh metadata in case it changed
    if (isObj) {
      cart[idx].name      = itemOrId.name      || cart[idx].name;
      cart[idx].size      = itemOrId.size      || cart[idx].size;
      cart[idx].price     = itemOrId.price     || cart[idx].price;
      cart[idx].image_url = itemOrId.image_url || cart[idx].image_url;
    }
  } else {
    cart.push({
      variant_id: vid,
      quantity,
      name:      isObj ? (itemOrId.name      || "") : "",
      size:      isObj ? (itemOrId.size      || "") : "",
      price:     isObj ? (itemOrId.price     || "0") : "0",
      image_url: isObj ? (itemOrId.image_url || "") : ""
    });
  }

  saveCart(cart);
  CartDrawer.open();
};

// ── Data-attribute click handler (product card buttons) ───────────

document.addEventListener("click", e => {
  const btn = e.target.closest("[data-cart-add]");
  if (!btn) return;

  const vid = parseInt(btn.dataset.variantId, 10);
  if (!vid) return;

  e.preventDefault();

  window.cartAddItem({
    variant_id: vid,
    name:      btn.dataset.name  || "",
    size:      btn.dataset.size  || "",
    price:     btn.dataset.price || "0",
    image_url: btn.dataset.image || ""
  });
});

// ── Cart Drawer ───────────────────────────────────────────────────

const CartDrawer = {
  get panel()   { return document.getElementById("cart-drawer-panel"); },
  get backdrop() { return document.getElementById("cart-drawer-backdrop"); },

  init() {
    if (this.panel) return;

    // Backdrop
    const bd = document.createElement("div");
    bd.id = "cart-drawer-backdrop";
    bd.className = [
      "fixed inset-0 z-[998]",
      "bg-black/50 backdrop-blur-sm",
      "opacity-0 pointer-events-none",
      "transition-opacity duration-300"
    ].join(" ");
    bd.addEventListener("click", () => this.close());
    document.body.appendChild(bd);

    // Panel
    const panel = document.createElement("div");
    panel.id = "cart-drawer-panel";
    panel.className = [
      "fixed top-0 right-0 h-full z-[999]",
      "w-full sm:w-[420px]",
      "bg-white shadow-2xl",
      "flex flex-col",
      "translate-x-full",
      "transition-transform duration-300 ease-out"
    ].join(" ");

    panel.innerHTML = `
      <!-- Header -->
      <div class="flex items-center justify-between px-5 py-4 border-b border-zinc-100">
        <div class="flex items-center gap-2.5">
          <svg class="w-5 h-5 text-orange-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round"
              d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-1.5 6h13M9 19.5a.5.5 0 11-1 0 .5.5 0 011 0zm7 0a.5.5 0 11-1 0 .5.5 0 011 0z"/>
          </svg>
          <h2 style="font-family:'Playfair Display',Georgia,serif"
              class="font-black text-zinc-900 text-base leading-none">
            My Cart
          </h2>
          <span id="drawer-count"
                class="text-[11px] font-semibold bg-orange-100 text-orange-700 px-2 py-0.5 rounded-full">
            0 items
          </span>
        </div>
        <button id="cart-drawer-close"
                class="p-1.5 rounded-full hover:bg-zinc-100 transition text-zinc-400 hover:text-zinc-700">
          <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
      </div>

      <!-- Items -->
      <div id="drawer-items" class="flex-1 overflow-y-auto px-4 py-3"></div>

      <!-- Footer -->
      <div id="drawer-footer" class="border-t border-zinc-100 px-5 py-4 space-y-3 bg-white">
        <div class="flex items-center justify-between">
          <span class="text-sm text-zinc-500" style="font-family:'Inter',sans-serif">Subtotal</span>
          <span id="drawer-subtotal" class="text-lg font-black text-zinc-900"
                style="font-family:'Inter',sans-serif">KSh 0.00</span>
        </div>
        <p class="text-[11px] text-zinc-400" style="font-family:'Inter',sans-serif">
          Free delivery within Nairobi on orders over KSh 10,000
        </p>
        <a href="/cart"
           class="flex items-center justify-center gap-2 w-full bg-orange-500 hover:bg-orange-600
                  text-white font-bold text-xs py-4 transition uppercase tracking-widest"
           style="font-family:'Inter',sans-serif">
          View Full Cart
        </a>
        <a href="/checkout"
           class="flex items-center justify-center gap-2 w-full bg-zinc-900 hover:bg-zinc-800
                  text-white font-bold text-xs py-4 transition uppercase tracking-widest"
           style="font-family:'Inter',sans-serif">
          Checkout
          <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M13 7l5 5m0 0l-5 5m5-5H6"/>
          </svg>
        </a>
        <a href="/shop"
           class="block text-center text-[11px] text-zinc-400 hover:text-zinc-600 transition py-0.5"
           style="font-family:'Inter',sans-serif">
          ← Continue Shopping
        </a>
      </div>
    `;

    document.body.appendChild(panel);
    panel.querySelector("#cart-drawer-close").addEventListener("click", () => this.close());

    // Close on Escape
    document.addEventListener("keydown", e => {
      if (e.key === "Escape") this.close();
    });
  },

  // ── Render items ─────────────────────────────────────────────────

  render() {
    const cart = getCart();
    const items    = this.panel?.querySelector("#drawer-items");
    const countEl  = this.panel?.querySelector("#drawer-count");
    const totalEl  = this.panel?.querySelector("#drawer-subtotal");
    if (!items) return;

    const count    = cartCount(cart);
    const subtotal = cart.reduce((s, i) => s + parsePrice(i.price) * i.quantity, 0);

    if (countEl) countEl.textContent = `${count} ${count === 1 ? "item" : "items"}`;
    if (totalEl) totalEl.textContent = `KSh ${subtotal.toFixed(2)}`;

    if (cart.length === 0) {
      items.innerHTML = `
        <div class="flex flex-col items-center justify-center h-full py-16 text-center gap-3">
          <div class="w-14 h-14 rounded-full bg-zinc-100 flex items-center justify-center">
            <svg class="w-7 h-7 text-zinc-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
              <path stroke-linecap="round" stroke-linejoin="round"
                d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-1.5 6h13"/>
            </svg>
          </div>
          <p class="font-bold text-zinc-700 text-sm" style="font-family:'Playfair Display',serif">
            Your cart is empty
          </p>
          <p class="text-xs text-zinc-400" style="font-family:'Inter',sans-serif">
            Add something from the shop
          </p>
        </div>`;
      return;
    }

    items.innerHTML = cart.map(item => {
      const lineTotal = (parsePrice(item.price) * item.quantity).toFixed(2);
      const imgSrc    = item.image_url
        ? `${item.image_url}${item.image_url.includes("?") ? "&" : "?"}w=160&auto=format&fit=crop`
        : "";

      return `
        <div class="flex gap-3.5 py-4 border-b border-zinc-50 last:border-0">
          <!-- Image -->
          <div class="w-[68px] h-[84px] rounded-xl overflow-hidden bg-zinc-50 border border-zinc-100 shrink-0">
            ${imgSrc
              ? `<img src="${imgSrc}" alt="${escHtml(item.name)}" class="w-full h-full object-cover">`
              : `<div class="w-full h-full flex items-center justify-center">
                   <svg class="w-6 h-6 text-zinc-200" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1">
                     <path stroke-linecap="round" stroke-linejoin="round"
                       d="M9 3v1m6-1v1M9 19v1m6-1v1M5 9H4m1 6H4m16-6h-1m1 6h-1M7 4h10l1 4v8a2 2 0 01-2 2H8a2 2 0 01-2-2V8l1-4z"/>
                   </svg>
                 </div>`
            }
          </div>

          <!-- Details -->
          <div class="flex-1 min-w-0">
            <p class="text-[13px] font-semibold text-zinc-900 leading-snug line-clamp-2"
               style="font-family:'Inter',sans-serif">
              ${escHtml(item.name || "Product")}
            </p>
            ${item.size
              ? `<p class="text-[11px] text-zinc-400 mt-0.5" style="font-family:'Inter',sans-serif">
                   ${escHtml(item.size)}
                 </p>`
              : ""}
            <p class="text-sm font-bold text-zinc-900 mt-1.5" style="font-family:'Inter',sans-serif">
              KSh ${lineTotal}
            </p>

            <!-- Controls -->
            <div class="flex items-center justify-between mt-2.5">
              <div class="flex items-center border border-zinc-200 rounded-lg overflow-hidden">
                <button data-drawer-dec="${item.variant_id}"
                        class="w-7 h-7 flex items-center justify-center text-zinc-500 hover:bg-zinc-50 transition text-sm font-light select-none">
                  −
                </button>
                <span class="w-7 h-7 flex items-center justify-center text-xs font-semibold text-zinc-900
                             border-x border-zinc-200 select-none"
                      style="font-family:'Inter',sans-serif">
                  ${item.quantity}
                </span>
                <button data-drawer-inc="${item.variant_id}"
                        class="w-7 h-7 flex items-center justify-center text-zinc-500 hover:bg-zinc-50 transition text-sm font-light select-none">
                  +
                </button>
              </div>
              <button data-drawer-remove="${item.variant_id}"
                      class="text-[11px] text-zinc-400 hover:text-red-500 transition flex items-center gap-1"
                      style="font-family:'Inter',sans-serif">
                <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
                </svg>
                Remove
              </button>
            </div>
          </div>
        </div>
      `;
    }).join("");

    // Bind drawer item controls via event delegation
    items.querySelectorAll("[data-drawer-inc]").forEach(btn => {
      btn.addEventListener("click", () => this.adjustQty(parseInt(btn.dataset.drawerInc), 1));
    });
    items.querySelectorAll("[data-drawer-dec]").forEach(btn => {
      btn.addEventListener("click", () => this.adjustQty(parseInt(btn.dataset.drawerDec), -1));
    });
    items.querySelectorAll("[data-drawer-remove]").forEach(btn => {
      btn.addEventListener("click", () => this.removeItem(parseInt(btn.dataset.drawerRemove)));
    });
  },

  adjustQty(vid, delta) {
    const cart = getCart();
    const idx  = cart.findIndex(i => i.variant_id === vid);
    if (idx < 0) return;
    cart[idx].quantity += delta;
    if (cart[idx].quantity <= 0) cart.splice(idx, 1);
    saveCart(cart);
    this.render();
  },

  removeItem(vid) {
    saveCart(getCart().filter(i => i.variant_id !== vid));
    this.render();
  },

  // ── Open / Close ──────────────────────────────────────────────────

  open() {
    this.init();
    this.render();

    document.body.style.overflow = "hidden";
    requestAnimationFrame(() => {
      this.backdrop.classList.remove("opacity-0", "pointer-events-none");
      this.backdrop.classList.add("opacity-100");
      this.panel.classList.remove("translate-x-full");
      this.panel.classList.add("translate-x-0");
    });
  },

  close() {
    this.backdrop?.classList.add("opacity-0", "pointer-events-none");
    this.backdrop?.classList.remove("opacity-100");
    this.panel?.classList.add("translate-x-full");
    this.panel?.classList.remove("translate-x-0");
    document.body.style.overflow = "";
  }
};

// Also open drawer when clicking the cart icon in the navbar
document.addEventListener("click", e => {
  if (e.target.closest("[data-cart-icon]")) {
    e.preventDefault();
    CartDrawer.open();
  }
});

// ── CartSync LiveView hook ────────────────────────────────────────

export const CartSync = {
  mounted() {
    const stored  = getCart();
    const minimal = stored.map(i => ({ variant_id: i.variant_id, quantity: i.quantity }));
    this.pushEvent("cart:restore", { items: minimal });

    this.handleEvent("cart:sync", ({ items }) => {
      // Merge server-validated quantities back, preserving local rich data
      const current = getCart();
      const updated = items.map(sv => {
        const local = current.find(i => i.variant_id === sv.variant_id);
        return { ...(local || {}), variant_id: sv.variant_id, quantity: sv.quantity };
      });
      saveCart(updated);
    });
  }
};

// ── Utilities ─────────────────────────────────────────────────────

function parsePrice(p) {
  if (typeof p === "number") return p;
  return parseFloat(String(p).replace(/[^0-9.]/g, "").split("–")[0]) || 0;
}

function escHtml(str) {
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

// ── Init ──────────────────────────────────────────────────────────

function initBadges() { updateAllBadges(getCart()); }

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", initBadges);
} else {
  initBadges();
}

window.addEventListener("phx:page-loading-stop", initBadges);

export { CartDrawer };

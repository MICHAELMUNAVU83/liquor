// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/liquor_web.ex",
    "../lib/liquor_web/**/*.*ex"
  ],
  theme: {
    extend: {
      colors: {
        brand: "#3CB7B2",
        // Override amber with The Mint brand teal palette so all amber-* classes
        // automatically render in the brand primary colour across the whole site.
        // PRIMARY #3CB7B2 — brand teal/mint for identity elements, borders, nav accents
        amber: {
          50:  "#f0fdfc",
          100: "#ccfbf7",
          200: "#99f6ee",
          300: "#5ee8e0",
          400: "#2dd4cc",
          500: "#3cb7b2",
          600: "#0e9590",
          700: "#107a76",
          800: "#12615e",
          900: "#134e4c",
          950: "#082d2b",
        },
        // SECONDARY #FF9500 — brand orange for CTA buttons, actions, highlights
        orange: {
          50:  "#fff8ee",
          100: "#ffefd3",
          200: "#ffdba6",
          300: "#ffc170",
          400: "#ffaa38",
          500: "#FF9500",
          600: "#e07800",
          700: "#b85c00",
          800: "#924700",
          900: "#773800",
          950: "#431c00",
        },
        // ACCENT #FFCC00 — brand yellow for stars, badges, special highlights
        yellow: {
          50:  "#fffde7",
          100: "#fff9c4",
          200: "#fff59d",
          300: "#fff176",
          400: "#FFCC00",
          500: "#F5B800",
          600: "#D4A000",
          700: "#B88900",
          800: "#9C7200",
          900: "#7C5D00",
          950: "#4C3800",
        },
      },
      fontFamily: {
        sans:    ["Inter", "ui-sans-serif", "system-ui", "-apple-system", "sans-serif"],
        display: ['"Playfair Display"', "Georgia", "Cambria", "serif"],
      },
      fontSize: {
        "2xs": ["0.625rem", { lineHeight: "1rem" }],
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({addVariant}) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({addVariant}) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({addVariant}) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function({matchComponents, theme}) {
      let iconsDir = path.join(__dirname, "../deps/heroicons/optimized")
      let values = {}
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
        ["-micro", "/16/solid"]
      ]
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach(file => {
          let name = path.basename(file, ".svg") + suffix
          values[name] = {name, fullPath: path.join(iconsDir, dir, file)}
        })
      })
      matchComponents({
        "hero": ({name, fullPath}) => {
          let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
          let size = theme("spacing.6")
          if (name.endsWith("-mini")) {
            size = theme("spacing.5")
          } else if (name.endsWith("-micro")) {
            size = theme("spacing.4")
          }
          return {
            [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
            "-webkit-mask": `var(--hero-${name})`,
            "mask": `var(--hero-${name})`,
            "mask-repeat": "no-repeat",
            "background-color": "currentColor",
            "vertical-align": "middle",
            "display": "inline-block",
            "width": size,
            "height": size
          }
        }
      }, {values})
    })
  ]
}

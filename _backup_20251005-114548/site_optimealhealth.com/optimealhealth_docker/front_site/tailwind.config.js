/** @type {import(''tailwindcss'').Config} */
export default {
  content: ["./src/**/*.{astro,html,md,mdx,js,ts,tsx}", "./public/**/*.html"],
  safelist: [{ pattern: /(bg|text|border)-(green|red|blue|slate)-(100|500|700)/ }]
};
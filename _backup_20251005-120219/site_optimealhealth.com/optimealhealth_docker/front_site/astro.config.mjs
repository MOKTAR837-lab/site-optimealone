import { defineConfig } from "astro/config";
import tailwind from "@astrojs/tailwind";
import sitemap from "@astrojs/sitemap";

export default defineConfig({
  site: import.meta.env.SITE || "https://optimealhealth.com",
  integrations: [tailwind(), sitemap()],
  output: "static",
  vite: {
    define: {
      "import.meta.env.PUBLIC_BACKEND_URL": JSON.stringify(process.env.PUBLIC_BACKEND_URL || process.env.BACKEND_URL || "http://localhost:8000"),
      "import.meta.env.PUBLIC_API_BASE": JSON.stringify(process.env.PUBLIC_API_BASE || process.env.API_BASE || "/api/v1")
    }
  }
});
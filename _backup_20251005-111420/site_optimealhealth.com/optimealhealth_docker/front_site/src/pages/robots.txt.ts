export function GET() {
  const site = import.meta.env.SITE || "https://optimealhealth.com";
  const body = `User-agent: *\nAllow: /\nSitemap: ${site}/sitemap.xml`;
  return new Response(body, { headers: { "Content-Type": "text/plain" } });
}
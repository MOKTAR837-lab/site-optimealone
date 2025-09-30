import type { APIContext } from "astro";
export async function GET(_ctx: APIContext) {
  const url = `${import.meta.env.BACKEND_URL}${import.meta.env.API_BASE}/profile`;
  const res = await fetch(url, { credentials: "include" });
  return new Response(await res.text(), { status: res.status, headers: { "content-type": res.headers.get("content-type") ?? "application/json" } });
}

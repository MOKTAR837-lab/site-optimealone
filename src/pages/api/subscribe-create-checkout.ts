import type { APIContext } from "astro";
export async function POST(_ctx: APIContext) {
  const url = `${import.meta.env.BACKEND_URL}${import.meta.env.API_BASE}/billing/create-checkout`;
  const res = await fetch(url, { method: "POST", credentials: "include" });
  return new Response(await res.text(), { status: res.status, headers: { "content-type": res.headers.get("content-type") ?? "application/json" } });
}

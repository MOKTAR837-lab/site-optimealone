import type { APIContext } from "astro";
export async function POST({ request }: APIContext) {
  const body = await request.json();
  const url = `${import.meta.env.BACKEND_URL}${import.meta.env.API_BASE}/ai/chat`;
  const res = await fetch(url, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body), credentials: "include" });
  return new Response(await res.text(), { status: res.status, headers: { "content-type": res.headers.get("content-type") ?? "application/json" } });
}

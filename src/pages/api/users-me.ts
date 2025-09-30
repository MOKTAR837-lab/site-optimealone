import type { APIContext } from "astro";

export async function GET(ctx: APIContext) {
  const url = `${import.meta.env.BACKEND_URL}${import.meta.env.API_BASE}/users/me`;
  try {
    const cookie = ctx.request.headers.get("cookie") ?? "";
    const res = await fetch(url, { headers: { cookie }, credentials: "include" });
    return new Response(await res.text(), {
      status: res.status,
      headers: { "content-type": res.headers.get("content-type") ?? "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: "backend_unreachable", target: url, details: String(err) }), {
      status: 502,
      headers: { "content-type": "application/json" },
    });
  }
}
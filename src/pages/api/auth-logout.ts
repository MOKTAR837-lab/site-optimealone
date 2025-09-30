import type { APIContext } from "astro";

export async function POST({ request }: APIContext) {
  const url = `${import.meta.env.BACKEND_URL}${import.meta.env.API_BASE}/auth/login`;
  try {
    const res = await fetch(url, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: await request.text(),
      // important: on laisse le backend fixer le cookie
      // et on le renvoie tel quel au navigateur
    });

    const headers = new Headers();
    for (const [k, v] of res.headers.entries()) {
      if (k.toLowerCase() === "set-cookie") headers.append("set-cookie", v);
      if (k.toLowerCase() === "content-type") headers.set("content-type", v);
    }
    if (!headers.has("content-type")) headers.set("content-type", "application/json");

    return new Response(await res.text(), { status: res.status, headers });
  } catch (err) {
    return new Response(JSON.stringify({ error: "backend_unreachable", details: String(err) }), {
      status: 502,
      headers: { "content-type": "application/json" },
    });
  }
}
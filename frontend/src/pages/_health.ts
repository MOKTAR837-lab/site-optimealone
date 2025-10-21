import type { APIRoute } from "astro";
export const GET: APIRoute = async () => new Response("ok", { status: 200 });

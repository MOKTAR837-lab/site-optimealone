import React from "react";

export default function SubscribeButton() {
  async function handleSubscribe() {
    const res = await fetch("/api/subscribe-create-checkout", { method: "POST" });
    const data = await res.json();
    if (data?.url) window.location.href = data.url;
  }
  async function openPortal() {
    const res = await fetch("/api/subscribe-portal", { method: "POST" });
    const data = await res.json();
    if (data?.url) window.location.href = data.url;
  }
  return (
    <div className="flex items-center gap-2">
      <button className="rounded-md bg-green-600 px-3 py-1 text-sm text-white" onClick={handleSubscribe}>S’abonner</button>
      <button className="rounded-md border px-3 py-1 text-sm" onClick={openPortal}>Gérer mon abonnement</button>
    </div>
  );
}

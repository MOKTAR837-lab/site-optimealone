import React, { useState } from "react";

export default function ChatLLM() {
  const [messages, setMessages] = useState<{ role: "user" | "assistant"; content: string }[]>([]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);

  async function send() {
    if (!input.trim()) return;
    const q = input;
    setInput("");
    setMessages((m) => [...m, { role: "user", content: q }]);
    setLoading(true);
    const res = await fetch("/api/llm", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ messages: [{ role: "user", content: q }] }) });
    const data = await res.json();
    setLoading(false);
    if (data?.answer) setMessages((m) => [...m, { role: "assistant", content: data.answer }]);
  }

  return (
    <div>
      <div className="mb-3 space-y-2">
        {messages.map((m, i) => (
          <p key={i} className={m.role === "user" ? "text-slate-800" : "text-slate-600"}>
            <strong>{m.role === "user" ? "Vous" : "Assistant"}:</strong> {m.content}
          </p>
        ))}
        {loading && <p className="text-sm text-slate-500">Réponse en cours…</p>}
      </div>
      <div className="flex gap-2">
        <input value={input} onChange={(e) => setInput(e.target.value)} className="w-full rounded-md border px-3 py-2" placeholder="Pose ta question nutrition…" />
        <button onClick={send} className="rounded-md bg-slate-900 px-4 py-2 text-white">Envoyer</button>
      </div>
    </div>
  );
}

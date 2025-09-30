import React, { useEffect, useState } from "react";

export default function LoginWidget() {
  const [user, setUser] = useState<{ email: string } | null>(null);

  useEffect(() => {
    (async () => {
      try {
        const res = await fetch("/api/users-me");
        if (res.ok) {
          const me = await res.json();
          if (me?.email) setUser({ email: me.email });
        }
      } catch {}
    })();
  }, []);

  async function handleLogin() {
    const email = prompt("Votre email ?");
    if (!email) return;
    const res = await fetch("/api/auth-login", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ email }) });
    if (res.ok) setUser({ email });
  }

  async function handleLogout() {
    await fetch("/api/auth-logout", { method: "POST" });
    setUser(null);
  }

  return (
    <div className="flex items-center gap-2">
      {user ? (
        <>
          <span className="hidden text-sm text-slate-600 sm:block">{user.email}</span>
          <a href="/app" className="rounded-md border px-3 py-1 text-sm">Mon espace</a>
          <button className="rounded-md border px-3 py-1 text-sm" onClick={handleLogout}>Se déconnecter</button>
        </>
      ) : (
        <button className="rounded-md bg-slate-900 px-3 py-1 text-sm text-white" onClick={handleLogin}>Se connecter</button>
      )}
    </div>
  );
}

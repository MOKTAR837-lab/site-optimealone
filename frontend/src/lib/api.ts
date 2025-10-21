export const API_BASE = (import.meta.env.PUBLIC_API_BASE ?? 'http://localhost:8000').replace(/\/$/, '');

export function api(path: string) {
  const p = path.startsWith('/') ? path : `/${path}`;
  return `${API_BASE}${p}`;
}

// Exemples:
// fetch(api('/api/health'))
// fetch(api('/api/me'))

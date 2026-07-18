/**
 * API base URL for browser requests.
 *
 * Prefer a relative `/api` path so the Vite dev server (or production nginx)
 * can proxy to the backend on the same origin. This avoids CORS / CORP issues
 * when passengers open `/verify/:id` from a ticket QR code on their phone.
 */
export function getApiBaseUrl(): string {
  const configured = (import.meta.env.VITE_API_BASE_URL as string | undefined)?.trim();

  if (typeof window !== 'undefined') {
    if (!configured || configured.startsWith('/')) {
      const path = configured?.startsWith('/') ? configured : '/api';
      return `${window.location.origin}${path}`;
    }

    // Verify pages should always use same-origin `/api` (proxied), even if env
    // still points at a bare `:3000` backend URL from an older setup.
    if (window.location.pathname.startsWith('/verify/')) {
      return `${window.location.origin}/api`;
    }

    return configured;
  }

  if (!configured || configured.startsWith('/')) {
    const path = configured?.startsWith('/') ? configured : '/api';
    return `http://localhost:3000${path}`;
  }

  return configured;
}

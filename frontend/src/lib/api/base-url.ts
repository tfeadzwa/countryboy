/**
 * API base URL for browser requests.
 *
 * Prefer a relative `/api` path so Vite (dev) or Nginx (prod) can proxy to the
 * backend on the same origin. Absolute URLs (e.g. https://api.countryboy.co.zw)
 * are used as-is when configured.
 */
export function getApiBaseUrl(): string {
  const configured = (import.meta.env.VITE_API_BASE_URL as string | undefined)?.trim();

  if (typeof window !== 'undefined') {
    if (!configured || configured.startsWith('/')) {
      const path = configured?.startsWith('/') ? configured : '/api';
      return `${window.location.origin}${path}`;
    }

    // Dev leftover pointing at a bare local backend — keep verify on same-origin
    // `/api` (proxied) so phone QR scans don't hit unreachable LAN IPs.
    if (
      window.location.pathname.startsWith('/verify/') &&
      isLocalDevApiUrl(configured)
    ) {
      return `${window.location.origin}/api`;
    }

    return stripTrailingSlash(configured);
  }

  if (!configured || configured.startsWith('/')) {
    const path = configured?.startsWith('/') ? configured : '/api';
    return `http://localhost:3000${path}`;
  }

  return stripTrailingSlash(configured);
}

function isLocalDevApiUrl(url: string): boolean {
  try {
    const { hostname, port } = new URL(url);
    if (hostname === 'localhost' || hostname === '127.0.0.1' || hostname === '10.0.2.2') {
      return true;
    }
    // Private LAN / bare :3000 style used in older mobile/dev setups
    if (/^(10\.|192\.168\.|172\.(1[6-9]|2\d|3[0-1])\.)/.test(hostname)) {
      return true;
    }
    if (port === '3000' && !hostname.includes('countryboy')) {
      return true;
    }
    return false;
  } catch {
    return false;
  }
}

function stripTrailingSlash(value: string): string {
  return value.length > 1 && value.endsWith('/') ? value.slice(0, -1) : value;
}

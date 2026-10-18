const ALLOWED_ORIGIN = "https://truyenvui.github.io";

function corsHeaders(origin) {
  return {
    "Access-Control-Allow-Origin": origin === ALLOWED_ORIGIN ? origin : ALLOWED_ORIGIN,
    "Access-Control-Allow-Methods": "GET, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    "Content-Type": "application/json; charset=utf-8",
    "X-Content-Type-Options": "nosniff",
  };
}

function json(data, status = 200, headers = {}) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8", ...headers },
  });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const origin = request.headers.get("Origin") || "";
    const headers = corsHeaders(origin);

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers });
    }

    if (request.method !== "GET") {
      return json({ ok: false, error: "Method not allowed" }, 405, {
        ...headers,
        Allow: "GET, OPTIONS",
      });
    }

    if (url.pathname === "/" || url.pathname === "/api/health") {
      try {
        const result = await env.DB.prepare("SELECT 1 AS connected").first();
        return json({
          ok: true,
          service: "goc-nghe-truyen-api",
          database: result?.connected === 1 ? "connected" : "unknown",
        }, 200, headers);
      } catch {
        return json({ ok: false, error: "Database connection failed" }, 500, headers);
      }
    }

    if (url.pathname === "/api/schema") {
      try {
        const result = await env.DB.prepare(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name"
        ).all();
        return json({ ok: true, tables: (result.results || []).map((row) => row.name) }, 200, headers);
      } catch {
        return json({ ok: false, error: "Could not read database schema" }, 500, headers);
      }
    }

    return json({ ok: false, error: "Not found" }, 404, headers);
  },
};


const CACHE_NAME = "goc-nghe-truyen-v14";
const BASE = self.registration.scope;

self.addEventListener("install", (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE_NAME);

    const urls = [
      BASE,
      BASE + "index.html",
      BASE + "manifest.json"
    ];

    for (const url of urls) {
      try {
        const response = await fetch(url, { cache: "reload" });
        if (response.ok) {
          await cache.put(url, response);
        }
      } catch (error) {
        console.log("Chưa lưu được:", url);
      }
    }
  })());

  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();

    await Promise.all(
      keys
        .filter((key) =>
          key.startsWith("goc-nghe-truyen-") &&
          key !== CACHE_NAME
        )
        .map((key) => caches.delete(key))
    );

    await self.clients.claim();
  })());
});

self.addEventListener("fetch", (event) => {
  const request = event.request;

  if (request.method !== "GET") return;

  const url = new URL(request.url);

  if (url.origin !== self.location.origin) return;

  event.respondWith((async () => {
    try {
      const response = await fetch(request);

      if (response.ok) {
        const cache = await caches.open(CACHE_NAME);
        await cache.put(request, response.clone());
      }

      return response;
    } catch (error) {
      const cached = await caches.match(request);

      if (cached) return cached;

      if (request.mode === "navigate") {
        return (
          await caches.match(BASE + "index.html") ||
          await caches.match(BASE) ||
          new Response("Ông hãy kết nối mạng để tải Góc Nghe Truyện lần đầu nhé.", {
            status: 503,
            headers: {
              "Content-Type": "text/plain; charset=utf-8"
            }
          })
        );
      }

      return new Response("Tài nguyên chưa được lưu để dùng ngoại tuyến.", {
        status: 503,
        headers: {
          "Content-Type": "text/plain; charset=utf-8"
        }
      });
    }
  })());
});

import type { MediaCache } from '../application/serve_media.ts';

/** Cache API del data center: la key es la URL pública sin la firma. */
export function edgeCache(cache: Cache, origin: string): MediaCache {
  const url = (key: string) => `${origin}/${key}`;
  return {
    match(key, range) {
      return cache.match(
        new Request(url(key), range ? { headers: { Range: range } } : undefined),
      );
    },
    put(key, response) {
      return cache.put(url(key), response);
    },
  };
}

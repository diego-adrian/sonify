// Keys servibles por el CDN. Solo lo transcodificado: `originals/` nunca sale
// del bucket.
const UUID = '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}';
const SERVABLE = new RegExp(
  `^(?:audio/${UUID}/(?:96|128|256)\\.m4a|covers/${UUID}/(?:200|640)\\.webp)$`,
);

export type MediaKey = { key: string; contentType: string };

export function parseMediaKey(pathname: string): MediaKey | null {
  const key = pathname.startsWith('/') ? pathname.slice(1) : pathname;
  if (!SERVABLE.test(key)) return null;
  return {
    key,
    contentType: key.endsWith('.m4a') ? 'audio/mp4' : 'image/webp',
  };
}

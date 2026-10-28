import type { SongStore } from '../application/transcode_song.ts';

/**
 * PostgREST con la llave secreta (`sb_secret_…`, rol service_role). Solo
 * toca canciones en `processing`, así un reintento tardío no pisa nada.
 */
export function supabaseSongStore(url: string, secretKey: string): SongStore {
  const rest = `${url}/rest/v1`;
  const headers = {
    apikey: secretKey,
    'Content-Type': 'application/json',
  };

  async function call(path: string, init: RequestInit = {}): Promise<Response> {
    const res = await fetch(`${rest}/${path}`, {
      ...init,
      headers: { ...headers, ...init.headers },
    });
    if (!res.ok) {
      throw new Error(`Supabase ${init.method ?? 'GET'} ${path}: ${res.status} ${await res.text()}`);
    }
    return res;
  }

  const songFilter = (id: string) =>
    `songs?id=eq.${encodeURIComponent(id)}&status=eq.processing`;

  return {
    async get(songId) {
      const res = await call(
        `songs?id=eq.${encodeURIComponent(songId)}&select=id,status,original_key,cover_original_key`,
      );
      const [row] = (await res.json()) as {
        id: string;
        status: string;
        original_key: string | null;
        cover_original_key: string | null;
      }[];
      return row
        ? {
            id: row.id,
            status: row.status,
            originalKey: row.original_key,
            coverOriginalKey: row.cover_original_key,
          }
        : null;
    },

    async markReady(songId, { durationMs, coverKey, files }) {
      await call('song_files?on_conflict=song_id,quality', {
        method: 'POST',
        headers: { Prefer: 'resolution=merge-duplicates,return=minimal' },
        body: JSON.stringify(
          files.map((f) => ({
            song_id: songId,
            quality: f.quality,
            key: f.key,
            size_bytes: f.sizeBytes,
            sha256: f.sha256,
          })),
        ),
      });
      await call(songFilter(songId), {
        method: 'PATCH',
        headers: { Prefer: 'return=minimal' },
        body: JSON.stringify({
          status: 'ready',
          duration_ms: durationMs,
          cover_key: coverKey,
        }),
      });
    },

    async markFailed(songId) {
      await call(songFilter(songId), {
        method: 'PATCH',
        headers: { Prefer: 'return=minimal' },
        body: JSON.stringify({ status: 'failed' }),
      });
    },
  };
}

// La app avisa que terminó de subir. Se comprueba en B2 que el objeto existe
// y respeta el límite; la canción pasa a "processing" (la transcodificación
// a AAC llega en el paso 7).

import { deleteObject, headSize } from '../_shared/b2.ts';
import { json, serve } from '../_shared/http.ts';
import { admin, authenticate } from '../_shared/supabase.ts';
import { MAX_COVER_BYTES, MAX_ORIGINAL_BYTES } from '../_shared/upload_rules.ts';

serve(async (req) => {
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);

  const userId = await authenticate(req);
  if (!userId) return json({ error: 'unauthorized' }, 401);

  let songId: unknown;
  try {
    songId = (await req.json()).song_id;
  } catch {
    return json({ error: 'invalid_json' }, 400);
  }
  if (typeof songId !== 'string') return json({ error: 'invalid_song' }, 400);

  const { data: song, error } = await admin
    .from('songs')
    .select('id, original_key, cover_original_key, status')
    .eq('id', songId)
    .eq('owner_id', userId)
    .maybeSingle();
  if (error) throw error;
  if (!song) return json({ error: 'not_found' }, 404);
  if (song.status !== 'uploading') return json({ status: song.status });

  const size = await headSize(song.original_key);
  if (size === null) return json({ error: 'not_uploaded' }, 409);

  if (size > MAX_ORIGINAL_BYTES) {
    await deleteObject(song.original_key);
    await admin.from('songs').update({ status: 'failed' }).eq('id', songId);
    return json({ error: 'too_large', max_bytes: MAX_ORIGINAL_BYTES }, 413);
  }

  // La portada es opcional: si no llegó o se pasa del límite, se sigue sin ella.
  let coverKey: string | null = song.cover_original_key;
  if (coverKey) {
    const coverSize = await headSize(coverKey);
    if (coverSize === null || coverSize > MAX_COVER_BYTES) {
      if (coverSize !== null) await deleteObject(coverKey);
      coverKey = null;
    }
  }

  const { error: updateError } = await admin
    .from('songs')
    .update({
      status: 'processing',
      original_size: size,
      cover_original_key: coverKey,
    })
    .eq('id', songId)
    .eq('status', 'uploading');
  if (updateError) throw updateError;

  return json({ status: 'processing' });
});

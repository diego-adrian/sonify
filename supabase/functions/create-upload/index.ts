// Crea la canción (status "uploading") a nombre del usuario autenticado y
// devuelve una URL prefirmada para subir el original directo a B2.
// Las keys las decide el servidor:
//   originals/{user_id}/{song_id}.{ext}         (audio)
//   originals/{user_id}/{song_id}-cover.{ext}   (portada, opcional)

import { presignPut } from '../_shared/b2.ts';
import { json, serve } from '../_shared/http.ts';
import { admin, authenticate } from '../_shared/supabase.ts';
import {
  CONTENT_TYPES,
  COVER_TYPES,
  DAILY_UPLOAD_LIMIT,
  LICENSES,
  MAX_COVER_BYTES,
  MAX_DESCRIPTION_LENGTH,
  MAX_ORIGINAL_BYTES,
  UPLOAD_URL_TTL_SECONDS,
} from '../_shared/upload_rules.ts';

type Body = {
  title?: unknown;
  genre_id?: unknown;
  license?: unknown;
  rights_accepted?: unknown;
  content_type?: unknown;
  size_bytes?: unknown;
  description?: unknown;
  cover_content_type?: unknown;
  cover_size_bytes?: unknown;
};

serve(async (req) => {
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);

  const userId = await authenticate(req);
  if (!userId) return json({ error: 'unauthorized' }, 401);

  let body: Body;
  try {
    body = await req.json();
  } catch {
    return json({ error: 'invalid_json' }, 400);
  }

  const title = typeof body.title === 'string' ? body.title.trim() : '';
  const genreId = body.genre_id ?? null;
  const license = body.license;
  const contentType = body.content_type;
  const size = body.size_bytes;

  if (title.length < 1 || title.length > 120) {
    return json({ error: 'invalid_title' }, 400);
  }
  if (genreId !== null && !Number.isInteger(genreId)) {
    return json({ error: 'invalid_genre' }, 400);
  }
  if (typeof license !== 'string' || !LICENSES.includes(license)) {
    return json({ error: 'invalid_license' }, 400);
  }
  if (body.rights_accepted !== true) {
    return json({ error: 'rights_not_accepted' }, 400);
  }
  if (typeof contentType !== 'string' || !(contentType in CONTENT_TYPES)) {
    return json({ error: 'unsupported_type' }, 415);
  }
  if (!Number.isInteger(size) || (size as number) <= 0) {
    return json({ error: 'invalid_size' }, 400);
  }
  if ((size as number) > MAX_ORIGINAL_BYTES) {
    return json({ error: 'too_large', max_bytes: MAX_ORIGINAL_BYTES }, 413);
  }

  const description =
    typeof body.description === 'string' ? body.description.trim() : '';
  if (description.length > MAX_DESCRIPTION_LENGTH) {
    return json({ error: 'description_too_long' }, 400);
  }

  const coverType = body.cover_content_type ?? null;
  const coverSize = body.cover_size_bytes ?? null;
  const hasCover = coverType !== null;
  if (hasCover) {
    if (typeof coverType !== 'string' || !(coverType in COVER_TYPES)) {
      return json({ error: 'unsupported_cover_type' }, 415);
    }
    if (!Number.isInteger(coverSize) || (coverSize as number) <= 0) {
      return json({ error: 'invalid_cover_size' }, 400);
    }
    if ((coverSize as number) > MAX_COVER_BYTES) {
      return json({ error: 'cover_too_large', max_bytes: MAX_COVER_BYTES }, 413);
    }
  }

  const since = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
  const { count, error: countError } = await admin
    .from('songs')
    .select('id', { count: 'exact', head: true })
    .eq('owner_id', userId)
    .gte('created_at', since);
  if (countError) throw countError;
  if ((count ?? 0) >= DAILY_UPLOAD_LIMIT) {
    return json({ error: 'daily_limit', limit: DAILY_UPLOAD_LIMIT }, 429);
  }

  const songId = crypto.randomUUID();
  const key = `originals/${userId}/${songId}.${CONTENT_TYPES[contentType]}`;
  const coverKey = hasCover
    ? `originals/${userId}/${songId}-cover.${COVER_TYPES[coverType as string]}`
    : null;

  const { error: insertError } = await admin.from('songs').insert({
    id: songId,
    owner_id: userId,
    title,
    genre_id: genreId,
    license,
    rights_accepted_at: new Date().toISOString(),
    original_key: key,
    description: description || null,
    cover_original_key: coverKey,
    status: 'uploading',
  });
  if (insertError) {
    if (insertError.code === '23503') return json({ error: 'invalid_genre' }, 400);
    throw insertError;
  }

  const uploadUrl = await presignPut(key, contentType, UPLOAD_URL_TTL_SECONDS);
  const coverUploadUrl = coverKey
    ? await presignPut(coverKey, coverType as string, UPLOAD_URL_TTL_SECONDS)
    : null;

  return json({
    song_id: songId,
    upload_url: uploadUrl,
    method: 'PUT',
    headers: { 'Content-Type': contentType },
    cover_upload_url: coverUploadUrl,
    cover_headers: coverKey ? { 'Content-Type': coverType } : null,
    expires_in: UPLOAD_URL_TTL_SECONDS,
  });
});

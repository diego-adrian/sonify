-- URLs firmadas del CDN (Worker sonify.diegoadrian.com).
-- El secreto `media_url_secret` vive en Vault (lo crea el dueño del proyecto
-- desde el SQL Editor); nunca pasa por el repo.
create schema if not exists private;
revoke all on schema private from public;

-- Devuelve "{key}?exp=…&sig=…" (la app antepone el dominio del CDN), o null si
-- falta el secreto. exp cae en un límite de día UTC (válida 24–48 h) para que
-- la URL de una portada sea estable durante el día y la caché de imágenes la
-- reutilice. Vive en `private` (no expuesto por la API): solo lo llaman
-- vistas/funciones que ya filtraron por RLS lo que el usuario puede leer.
create or replace function private.media_path(p_key text)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select p_key || '?exp=' || e.exp || '&sig='
    || encode(extensions.hmac(p_key || ':' || e.exp, s.decrypted_secret, 'sha256'), 'hex')
  from vault.decrypted_secrets s,
       lateral (select (floor(extract(epoch from now()) / 86400)::bigint + 2) * 86400 as exp) e
  where s.name = 'media_url_secret'
$$;

revoke all on function private.media_path(text) from public, anon, authenticated;

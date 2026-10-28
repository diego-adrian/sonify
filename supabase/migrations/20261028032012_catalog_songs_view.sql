-- Catálogo para la app en una sola consulta: canciones listas con el nombre
-- del artista y las rutas firmadas del CDN (la app antepone el dominio).
-- security_invoker: aplica la RLS de `songs` del usuario que consulta
-- (públicas, más las propias aunque sean privadas).
create or replace view public.catalog_songs
with (security_invoker = true)
as
select
  s.id,
  s.title,
  p.display_name as artist_name,
  s.genre_id,
  s.duration_ms,
  s.created_at,
  case when s.cover_key is not null
    then private.media_path(s.cover_key || '/200.webp') end as cover_path,
  case when s.cover_key is not null
    then private.media_path(s.cover_key || '/640.webp') end as cover_large_path,
  -- Calidad por defecto ("Alta"); el ajuste de calidad vendrá después.
  private.media_path(f.key) as audio_path,
  f.size_bytes as audio_size_bytes,
  f.sha256 as audio_sha256
from public.songs s
join public.profiles p on p.id = s.owner_id
join public.song_files f on f.song_id = s.id and f.quality = 128
where s.status = 'ready' and s.deleted_at is null;

revoke all on public.catalog_songs from anon, authenticated;
grant select on public.catalog_songs to authenticated;

-- La vista llama al firmador como el usuario: necesita poder ejecutarlo.
-- `private` no está expuesto por la API, así que nadie puede llamarlo
-- directo para firmar keys arbitrarias.
grant usage on schema private to authenticated;
grant execute on function private.media_path(text) to authenticated;

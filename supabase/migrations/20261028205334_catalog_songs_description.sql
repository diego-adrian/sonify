-- La app muestra la descripción bajo el título (o el artista si no tiene).
-- Misma vista, con `description` al final.
create or replace view public.catalog_songs
with (security_invoker = true)
as
with account as materialized (
  select private.current_user_is_premium() as premium
)
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
  case when a.premium or l.song_id is not null
    then private.media_path(f.key) end as audio_path,
  f.size_bytes as audio_size_bytes,
  f.sha256 as audio_sha256,
  l.song_id is not null as in_library,
  l.created_at as saved_at,
  s.description
from public.songs s
join public.profiles p on p.id = s.owner_id
join public.song_files f on f.song_id = s.id and f.quality = 128
cross join account a
left join public.library_songs l
  on l.song_id = s.id and l.user_id = (select auth.uid())
where s.status = 'ready' and s.deleted_at is null;

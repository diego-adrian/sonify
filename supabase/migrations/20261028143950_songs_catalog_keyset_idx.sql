-- Paginación del catálogo por cursor (created_at desc, id desc): cada
-- página arranca justo después de la última canción recibida.
create index if not exists songs_catalog_keyset_idx
  on public.songs (created_at desc, id desc)
  where status = 'ready' and deleted_at is null;

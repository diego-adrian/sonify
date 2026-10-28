-- Descripción del artista y portada original (el transcodificador genera
-- covers/{song_id}/{size}.webp a partir de ella y rellena cover_key).

alter table public.songs
  add column description text check (char_length(description) <= 500),
  add column cover_original_key text unique;

grant update (description) on public.songs to authenticated;

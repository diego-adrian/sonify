-- Canciones: el dueño (owner_id) es el artista. La fila la crea la Edge
-- Function `create-upload` con service role; la app nunca inserta.

create type public.song_status as enum ('uploading', 'processing', 'ready', 'failed', 'removed');
create type public.song_visibility as enum ('public', 'private');
create type public.song_license as enum ('cc0', 'cc_by', 'cc_by_sa', 'cc_by_nc', 'cc_by_nc_sa');

create table public.songs (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  title text not null check (char_length(title) between 1 and 120),
  genre_id smallint references public.genres (id),
  duration_ms integer check (duration_ms > 0),
  status public.song_status not null default 'uploading',
  visibility public.song_visibility not null default 'public',
  license public.song_license not null,
  rights_accepted_at timestamptz not null,
  original_key text unique,
  original_size bigint check (original_size > 0),
  cover_key text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create trigger songs_set_updated_at
  before update on public.songs
  for each row execute function public.set_updated_at();

-- Catálogo público (coincide con la política de lectura).
create index songs_catalog_idx on public.songs (genre_id, created_at desc)
  where status = 'ready' and visibility = 'public' and deleted_at is null;
create index songs_owner_idx on public.songs (owner_id, created_at desc);
create index songs_genre_id_idx on public.songs (genre_id);

alter table public.songs enable row level security;

create policy "Read public ready songs or own songs"
  on public.songs for select
  to authenticated
  using (
    (status = 'ready' and visibility = 'public' and deleted_at is null)
    or owner_id = (select auth.uid())
  );

create policy "Owners can update their song metadata"
  on public.songs for update
  to authenticated
  using (owner_id = (select auth.uid()) and deleted_at is null)
  with check (owner_id = (select auth.uid()));

-- status, keys, tamaños y owner_id solo los cambia el backend.
revoke all on public.songs from anon;
revoke insert, update, delete on public.songs from authenticated;
grant update (title, genre_id, visibility) on public.songs to authenticated;

-- Una fila por calidad generada por el transcodificador.
create table public.song_files (
  song_id uuid not null references public.songs (id) on delete cascade,
  quality smallint not null check (quality in (96, 128, 256)),
  key text not null unique,
  size_bytes bigint not null check (size_bytes > 0),
  sha256 text not null check (sha256 ~ '^[0-9a-f]{64}$'),
  created_at timestamptz not null default now(),
  primary key (song_id, quality)
);

alter table public.song_files enable row level security;

-- Legible si la canción es legible (la subconsulta aplica el RLS de songs).
create policy "Read files of readable songs"
  on public.song_files for select
  to authenticated
  using (exists (select 1 from public.songs s where s.id = song_id));

revoke all on public.song_files from anon;
revoke insert, update, delete on public.song_files from authenticated;

-- Borrado lógico por el dueño; un job borra después los archivos de B2.
create or replace function public.soft_delete_song(p_song_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.songs
  set deleted_at = now()
  where id = p_song_id
    and owner_id = (select auth.uid())
    and deleted_at is null;

  if not found then
    raise exception 'song not found' using errcode = 'P0002';
  end if;
end;
$$;

revoke execute on function public.soft_delete_song(uuid) from public, anon;
grant execute on function public.soft_delete_song(uuid) to authenticated;

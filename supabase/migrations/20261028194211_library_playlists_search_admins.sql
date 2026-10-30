-- Biblioteca, playlists, búsqueda y admins.
--
-- * Solo los admins (`admin_users`) suben canciones; los admins son premium.
-- * Cada usuario guarda canciones del catálogo en su biblioteca
--   (`library_songs`): una canción, n usuarios. Gratis hasta
--   `plans.max_songs` del plan free (5); premium sin límite.
-- * Gratis solo escucha lo que guardó: `catalog_songs` firma el audio solo de
--   esas canciones (o de todas si es premium). Sin URL no hay streaming ni
--   descarga.
-- * Las playlists agrupan canciones de la biblioteca: agregar una canción a
--   una playlist la guarda (y cuenta para el límite); quitarla de la
--   biblioteca la saca de sus playlists.

-- Admins ---------------------------------------------------------------------

create table public.admin_users (
  email text primary key check (email = lower(trim(email)) and email like '%_@_%'),
  created_at timestamptz not null default now()
);

alter table public.admin_users enable row level security;
-- Sin políticas: solo service role / SQL del dashboard.
revoke all on public.admin_users from anon, authenticated;

insert into public.admin_users (email) values ('adry.dabp@gmail.com');

create or replace function private.is_admin(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from auth.users u
    join public.admin_users a on a.email = lower(u.email)
    where u.id = p_user_id
  );
$$;

revoke execute on function private.is_admin(uuid) from public, anon, authenticated;

create or replace function private.is_premium(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.is_admin(p_user_id) or exists (
    select 1
    from auth.users u
    join public.premium_users p on p.email = lower(u.email)
    where u.id = p_user_id
      and (p.expires_at is null or p.expires_at > now())
  );
$$;

-- Lo usa `catalog_songs`, que corre como el usuario. `private` no está
-- expuesto por la API: no se puede llamar directo.
create or replace function private.current_user_is_premium()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.is_premium((select auth.uid()));
$$;

revoke execute on function private.current_user_is_premium() from public, anon;
grant execute on function private.current_user_is_premium() to authenticated;

-- Subir canciones: solo admins (antes era un cupo de 5 por usuario).
drop trigger songs_enforce_song_limit on public.songs;
drop function private.enforce_song_limit();

create or replace function private.enforce_admin_upload()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.is_admin(new.owner_id) then
    raise exception 'not_admin' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

revoke execute on function private.enforce_admin_upload() from public, anon, authenticated;

create trigger songs_enforce_admin_upload
  before insert on public.songs
  for each row execute function private.enforce_admin_upload();

comment on column public.plans.max_songs is
  'Canciones que se pueden guardar en la biblioteca (y escuchar); null = sin límite.';

-- Biblioteca -----------------------------------------------------------------

create table public.library_songs (
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  song_id uuid not null references public.songs (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, song_id)
);

create index library_songs_song_id_idx on public.library_songs (song_id);

alter table public.library_songs enable row level security;

create policy "Users can read their library"
  on public.library_songs for select
  to authenticated
  using (user_id = (select auth.uid()));

-- Solo canciones que el usuario puede ver en el catálogo (la subconsulta
-- aplica la RLS de songs).
create policy "Users can save catalog songs"
  on public.library_songs for insert
  to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.songs s
      where s.id = song_id and s.status = 'ready' and s.deleted_at is null
    )
  );

create policy "Users can remove from their library"
  on public.library_songs for delete
  to authenticated
  using (user_id = (select auth.uid()));

revoke all on public.library_songs from anon;
revoke update on public.library_songs from authenticated;
grant select, delete on public.library_songs to authenticated;
grant insert (song_id) on public.library_songs to authenticated;

-- Cupo de la biblioteca. Lock por usuario para que dos guardados simultáneos
-- no se lo salten. No cuentan las canciones borradas o retiradas.
create or replace function private.enforce_library_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_limit integer;
  v_used integer;
begin
  if private.is_premium(new.user_id) then
    return new;
  end if;

  select max_songs into v_limit from public.plans where id = 'free';
  if v_limit is null then
    return new;
  end if;

  perform pg_advisory_xact_lock(hashtextextended('library:' || new.user_id::text, 0));

  select count(*) into v_used
  from public.library_songs l
  join public.songs s on s.id = l.song_id
  where l.user_id = new.user_id
    and s.status = 'ready'
    and s.deleted_at is null;

  if v_used >= v_limit then
    raise exception 'library_limit' using errcode = 'P0001', detail = v_limit::text;
  end if;

  return new;
end;
$$;

revoke execute on function private.enforce_library_limit() from public, anon, authenticated;

create trigger library_songs_enforce_limit
  before insert on public.library_songs
  for each row execute function private.enforce_library_limit();

-- Playlists ------------------------------------------------------------------

create table public.playlists (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 60),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index playlists_owner_idx on public.playlists (owner_id, created_at);

create trigger playlists_set_updated_at
  before update on public.playlists
  for each row execute function public.set_updated_at();

alter table public.playlists enable row level security;

create policy "Users can read their playlists"
  on public.playlists for select
  to authenticated
  using (owner_id = (select auth.uid()));

create policy "Users can create playlists"
  on public.playlists for insert
  to authenticated
  with check (owner_id = (select auth.uid()));

create policy "Users can rename their playlists"
  on public.playlists for update
  to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create policy "Users can delete their playlists"
  on public.playlists for delete
  to authenticated
  using (owner_id = (select auth.uid()));

revoke all on public.playlists from anon;
revoke insert, update on public.playlists from authenticated;
grant select, delete on public.playlists to authenticated;
grant insert (name), update (name) on public.playlists to authenticated;

create table public.playlist_songs (
  playlist_id uuid not null references public.playlists (id) on delete cascade,
  song_id uuid not null references public.songs (id) on delete cascade,
  added_at timestamptz not null default now(),
  primary key (playlist_id, song_id)
);

create index playlist_songs_song_id_idx on public.playlist_songs (song_id);

alter table public.playlist_songs enable row level security;

create policy "Users can read songs of their playlists"
  on public.playlist_songs for select
  to authenticated
  using (exists (
    select 1 from public.playlists p
    where p.id = playlist_id and p.owner_id = (select auth.uid())
  ));

create policy "Users can add songs to their playlists"
  on public.playlist_songs for insert
  to authenticated
  with check (exists (
    select 1 from public.playlists p
    where p.id = playlist_id and p.owner_id = (select auth.uid())
  ));

create policy "Users can remove songs from their playlists"
  on public.playlist_songs for delete
  to authenticated
  using (exists (
    select 1 from public.playlists p
    where p.id = playlist_id and p.owner_id = (select auth.uid())
  ));

revoke all on public.playlist_songs from anon;
revoke update on public.playlist_songs from authenticated;
grant select, delete on public.playlist_songs to authenticated;
grant insert (playlist_id, song_id) on public.playlist_songs to authenticated;

-- Agregar a una playlist guarda la canción en la biblioteca del dueño (como
-- el usuario: aplica la RLS y el cupo).
create or replace function private.save_playlist_song_to_library()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  -- user_id = auth.uid() por defecto; la RLS de playlist_songs ya exige que
  -- la playlist sea suya.
  insert into public.library_songs (song_id)
  values (new.song_id)
  on conflict do nothing;
  return new;
end;
$$;

create trigger playlist_songs_save_to_library
  before insert on public.playlist_songs
  for each row execute function private.save_playlist_song_to_library();

-- Quitar de la biblioteca la saca de las playlists de ese usuario.
create or replace function private.remove_library_song_from_playlists()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.playlist_songs ps
  using public.playlists p
  where p.id = ps.playlist_id
    and p.owner_id = old.user_id
    and ps.song_id = old.song_id;
  return old;
end;
$$;

revoke execute on function private.remove_library_song_from_playlists() from public, anon, authenticated;

create trigger library_songs_remove_from_playlists
  after delete on public.library_songs
  for each row execute function private.remove_library_song_from_playlists();

-- Catálogo -------------------------------------------------------------------

-- Mismas columnas que antes y al final `in_library` / `saved_at`. El audio
-- solo se firma si el usuario puede escucharlo.
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
  l.created_at as saved_at
from public.songs s
join public.profiles p on p.id = s.owner_id
join public.song_files f on f.song_id = s.id and f.quality = 128
cross join account a
left join public.library_songs l
  on l.song_id = s.id and l.user_id = (select auth.uid())
where s.status = 'ready' and s.deleted_at is null;

-- Búsqueda por título o artista, sin distinguir tildes ni mayúsculas.
create or replace function public.search_songs(p_query text, p_limit integer default 30)
returns setof public.catalog_songs
language sql
stable
set search_path = ''
as $$
  with q as (
    select '%' || replace(replace(replace(
      extensions.unaccent(lower(trim(p_query))),
      '\', '\\'), '%', '\%'), '_', '\_') || '%' as pattern
  )
  select c.*
  from public.catalog_songs c, q
  where char_length(trim(p_query)) > 0
    and (
      extensions.unaccent(lower(c.title)) like q.pattern
      or extensions.unaccent(lower(c.artist_name)) like q.pattern
    )
  order by c.created_at desc, c.id desc
  limit least(greatest(p_limit, 1), 50);
$$;

revoke execute on function public.search_songs(text, integer) from public, anon;
grant execute on function public.search_songs(text, integer) to authenticated;

-- Cuenta del usuario con sesión: lo que la app necesita para mostrar el
-- botón de subir, la pestaña Premium y el cupo de la biblioteca.
create or replace function public.my_account()
returns json
language sql
stable
security definer
set search_path = ''
as $$
  select json_build_object(
    'is_premium', private.is_premium((select auth.uid())),
    'is_admin', private.is_admin((select auth.uid())),
    'library_limit', (select max_songs from public.plans where id = 'free'),
    'premium_price_cents', (select price_cents from public.plans where id = 'premium'),
    'premium_currency', (select currency from public.plans where id = 'premium')
  );
$$;

revoke execute on function public.my_account() from public, anon;
grant execute on function public.my_account() to authenticated;

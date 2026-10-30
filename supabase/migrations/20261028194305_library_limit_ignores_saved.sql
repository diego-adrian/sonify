-- Volver a guardar una canción que ya está en la biblioteca (p. ej. al
-- agregarla a una playlist) no ocupa cupo: el trigger corre antes de que
-- `on conflict` descarte la fila repetida.
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

  if exists (
    select 1 from public.library_songs
    where user_id = new.user_id and song_id = new.song_id
  ) then
    return new;
  end if;

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

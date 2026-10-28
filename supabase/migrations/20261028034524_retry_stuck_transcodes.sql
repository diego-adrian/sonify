-- Reintento automático de canciones trabadas en `processing` (Render se
-- reinició, se perdió el aviso, etc.). Máximo 3 intentos por canción; después
-- queda `failed` para no reintentar para siempre un archivo que rompe ffmpeg.
create extension if not exists pg_cron;

-- Solo backend: los grants por columna de `songs` no incluyen estas.
alter table public.songs
  add column transcode_attempts smallint not null default 0,
  add column transcode_requested_at timestamptz;

create or replace function private.request_transcode(p_song_id uuid)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_url text;
  v_secret text;
begin
  select decrypted_secret into v_url
    from vault.decrypted_secrets where name = 'transcoder_url';
  select decrypted_secret into v_secret
    from vault.decrypted_secrets where name = 'transcoder_secret';
  if v_url is null or v_secret is null then
    raise warning 'transcoder sin configurar: faltan transcoder_url / transcoder_secret en Vault';
    return null;
  end if;

  update public.songs
     set transcode_attempts = transcode_attempts + 1,
         transcode_requested_at = now()
   where id = p_song_id;

  -- Asíncrono: sale al confirmar la transacción. El transcodificador procesa
  -- de a una y responde al terminar (cola incluida), de ahí el timeout largo.
  return net.http_post(
    url := rtrim(v_url, '/') || '/transcode',
    body := jsonb_build_object('song_id', p_song_id),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-transcoder-secret', v_secret
    ),
    timeout_milliseconds := 900000
  );
end;
$$;

revoke all on function private.request_transcode(uuid) from public, anon, authenticated;

create or replace function private.retry_stuck_transcodes()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_song record;
  v_count integer := 0;
begin
  -- Agotó los intentos: falla definitiva.
  update public.songs
     set status = 'failed'
   where status = 'processing'
     and deleted_at is null
     and transcode_attempts >= 3
     and transcode_requested_at < now() - interval '20 minutes';

  for v_song in
    select id from public.songs
     where status = 'processing'
       and deleted_at is null
       and transcode_attempts < 3
       and coalesce(transcode_requested_at, updated_at) < now() - interval '20 minutes'
     order by updated_at
     limit 20
  loop
    perform private.request_transcode(v_song.id);
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

revoke all on function private.retry_stuck_transcodes() from public, anon, authenticated;

select cron.schedule(
  'retry-stuck-transcodes',
  '*/10 * * * *',
  $$select private.retry_stuck_transcodes()$$
);

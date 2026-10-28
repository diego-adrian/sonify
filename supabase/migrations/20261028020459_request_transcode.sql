-- Dispara el transcodificador (Cloud Run) cuando una canción pasa a
-- `processing`. La URL y el secreto compartido viven en Vault
-- (`transcoder_url`, `transcoder_secret`); los crea el dueño del proyecto.
create extension if not exists pg_net with schema extensions;

-- También sirve para reintentar a mano: select private.request_transcode('<song_id>');
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
  -- Asíncrono: sale al confirmar la transacción. Cloud Run responde al
  -- terminar de transcodificar, de ahí el timeout largo.
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

create or replace function private.on_song_processing()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.request_transcode(new.id);
  return new;
end;
$$;

revoke all on function private.on_song_processing() from public, anon, authenticated;

create trigger songs_request_transcode
  after update of status on public.songs
  for each row
  when (new.status = 'processing' and old.status is distinct from 'processing')
  execute function private.on_song_processing();

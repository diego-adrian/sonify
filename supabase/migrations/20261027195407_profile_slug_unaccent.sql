-- Slugs sin tildes: "Cinthia Pérez" -> "cinthia-perez-xxxxxx".

create extension if not exists unaccent with schema extensions;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  name text;
  base_slug text;
  candidate text;
begin
  name := left(coalesce(
    nullif(trim(meta ->> 'full_name'), ''),
    nullif(trim(meta ->> 'name'), ''),
    nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
    'Artista'
  ), 80);

  base_slug := trim(both '-' from regexp_replace(lower(extensions.unaccent(name)), '[^a-z0-9]+', '-', 'g'));
  if char_length(base_slug) < 3 then
    base_slug := 'artista';
  end if;
  base_slug := left(base_slug, 50);

  loop
    candidate := base_slug || '-' || substr(md5(random()::text || new.id::text), 1, 6);
    exit when not exists (select 1 from public.profiles where slug = candidate);
  end loop;

  insert into public.profiles (id, display_name, slug, avatar_url)
  values (
    new.id,
    name,
    candidate,
    coalesce(meta ->> 'avatar_url', meta ->> 'picture')
  );
  return new;
end;
$$;

-- Perfiles: todo usuario es artista de sí mismo. id = auth.users.id.

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 80),
  slug text not null unique
    check (char_length(slug) between 3 and 60 and slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  bio text check (char_length(bio) <= 500),
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;

create policy "Authenticated users can read profiles"
  on public.profiles for select
  to authenticated
  using (true);

create policy "Users can update their own profile"
  on public.profiles for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- La fila la crea el trigger; el usuario solo edita estos campos.
revoke all on public.profiles from anon;
revoke insert, update, delete on public.profiles from authenticated;
grant update (display_name, slug, bio, avatar_url) on public.profiles to authenticated;

-- Crea el perfil al registrarse, con nombre y avatar del proveedor (Google hoy).
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

  base_slug := trim(both '-' from regexp_replace(lower(name), '[^a-z0-9]+', '-', 'g'));
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

revoke execute on function public.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create table public.genres (
  id smallint generated always as identity primary key,
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  name text not null,
  sort_order smallint not null default 0
);

alter table public.genres enable row level security;

create policy "Authenticated users can read genres"
  on public.genres for select
  to authenticated
  using (true);

revoke all on public.genres from anon;
revoke insert, update, delete on public.genres from authenticated;

insert into public.genres (slug, name, sort_order) values
  ('baladas', 'Baladas', 1),
  ('rancheras', 'Rancheras', 2),
  ('cumbia', 'Cumbia', 3),
  ('romanticos', 'Románticos', 4);

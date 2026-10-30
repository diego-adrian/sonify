-- Premium y suscripciones. Un usuario es premium si su correo está en
-- `premium_members` (alta manual) o si tiene una suscripción vigente
-- (`subscriptions`, la llenarán los webhooks de App Store / Google Play / Stripe).
-- Premium sube canciones sin límite; el resto, hasta `plans.max_songs` del plan free.

create table public.plans (
  id text primary key check (id ~ '^[a-z0-9_]+$'),
  name text not null,
  -- null = sin límite de canciones activas.
  max_songs integer check (max_songs >= 0),
  price_cents integer not null default 0 check (price_cents >= 0),
  currency text not null default 'USD' check (currency ~ '^[A-Z]{3}$'),
  billing_interval text check (billing_interval in ('month', 'year')),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

insert into public.plans (id, name, max_songs, price_cents, billing_interval) values
  ('free', 'Gratis', 5, 0, null),
  ('premium', 'Premium', null, 300, 'month');

alter table public.plans enable row level security;

-- La app podrá mostrar el precio; solo el backend los modifica.
create policy "Authenticated users can read active plans"
  on public.plans for select
  to authenticated
  using (active);

revoke all on public.plans from anon;
revoke insert, update, delete on public.plans from authenticated;

-- Altas manuales por correo: sirve aunque la persona todavía no se haya
-- registrado. Se compara con auth.users.email (el de Google hoy).
create table public.premium_members (
  email text primary key check (email = lower(trim(email)) and email like '%_@_%'),
  note text,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.premium_members enable row level security;
-- Sin políticas: solo service role / SQL del dashboard.
revoke all on public.premium_members from anon, authenticated;

create type public.subscription_status as enum (
  'active',    -- pagada y vigente
  'in_grace',  -- falló el cobro; el proveedor sigue reintentando
  'canceled',  -- no se renovará; vale hasta current_period_end
  'expired'    -- terminó o se reembolsó
);

create type public.subscription_provider as enum ('app_store', 'google_play', 'stripe');

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  plan_id text not null references public.plans (id),
  provider public.subscription_provider not null,
  provider_subscription_id text not null,
  status public.subscription_status not null,
  current_period_start timestamptz not null,
  current_period_end timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (provider, provider_subscription_id),
  check (current_period_end > current_period_start)
);

create index subscriptions_user_idx on public.subscriptions (user_id, current_period_end desc);
create index subscriptions_plan_id_idx on public.subscriptions (plan_id);

create trigger subscriptions_set_updated_at
  before update on public.subscriptions
  for each row execute function public.set_updated_at();

alter table public.subscriptions enable row level security;

create policy "Users can read their own subscriptions"
  on public.subscriptions for select
  to authenticated
  using (user_id = (select auth.uid()));

revoke all on public.subscriptions from anon;
revoke insert, update, delete on public.subscriptions from authenticated;

create or replace function private.is_premium(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from auth.users u
    join public.premium_members m on m.email = lower(u.email)
    where u.id = p_user_id
      and (m.expires_at is null or m.expires_at > now())
  ) or exists (
    select 1
    from public.subscriptions s
    where s.user_id = p_user_id
      and s.status in ('active', 'in_grace', 'canceled')
      and s.current_period_end > now()
  );
$$;

revoke execute on function private.is_premium(uuid) from public, anon, authenticated;

-- Cupo de canciones al crear una: lo hace cumplir la base (no solo la Edge
-- Function) para que dos subidas simultáneas no se lo salten. No cuentan las
-- borradas, las fallidas ni las que quedaron en "uploading" más de un día.
create or replace function private.enforce_song_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_limit integer;
  v_used integer;
begin
  if private.is_premium(new.owner_id) then
    return new;
  end if;

  select max_songs into v_limit from public.plans where id = 'free';
  if v_limit is null then
    return new;
  end if;

  perform pg_advisory_xact_lock(hashtextextended(new.owner_id::text, 0));

  select count(*) into v_used
  from public.songs
  where owner_id = new.owner_id
    and deleted_at is null
    and status <> 'failed'
    and not (status = 'uploading' and created_at < now() - interval '1 day');

  if v_used >= v_limit then
    raise exception 'song_limit' using errcode = 'P0001', detail = v_limit::text;
  end if;

  return new;
end;
$$;

revoke execute on function private.enforce_song_limit() from public, anon, authenticated;

create trigger songs_enforce_song_limit
  before insert on public.songs
  for each row execute function private.enforce_song_limit();

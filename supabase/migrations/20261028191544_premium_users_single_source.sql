-- `premium_users` es la única fuente de verdad de quién es premium. Se llena
-- de dos formas:
--   source = 'admin'         alta manual (familia, amigos, promociones)
--   source = 'subscription'  la escribe el trigger de `subscriptions`
-- `private.is_premium` solo mira esta tabla.

alter table public.premium_members rename to premium_users;
alter table public.premium_users rename constraint premium_members_pkey to premium_users_pkey;
alter table public.premium_users rename constraint premium_members_email_check to premium_users_email_check;

create type public.premium_source as enum ('admin', 'subscription');

alter table public.premium_users
  add column source public.premium_source not null default 'admin',
  add column subscription_id uuid references public.subscriptions (id) on delete set null,
  add column updated_at timestamptz not null default now();

create index premium_users_subscription_id_idx on public.premium_users (subscription_id);

create trigger premium_users_set_updated_at
  before update on public.premium_users
  for each row execute function public.set_updated_at();

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
    join public.premium_users p on p.email = lower(u.email)
    where u.id = p_user_id
      and (p.expires_at is null or p.expires_at > now())
  );
$$;

-- Copia a `premium_users` la suscripción vigente del usuario (la que vence
-- más tarde). Nunca pisa un alta de admin vigente; sí una vencida.
create or replace function private.sync_premium_from_subscriptions()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_email text;
  v_subscription_id uuid;
  v_period_end timestamptz;
begin
  select lower(email) into v_email from auth.users where id = new.user_id;
  if v_email is null then
    return new;
  end if;

  select s.id, s.current_period_end into v_subscription_id, v_period_end
  from public.subscriptions s
  where s.user_id = new.user_id
    and s.status in ('active', 'in_grace', 'canceled')
  order by s.current_period_end desc
  limit 1;

  if not found then
    update public.premium_users
    set expires_at = now()
    where email = v_email
      and source = 'subscription'
      and (expires_at is null or expires_at > now());
    return new;
  end if;

  insert into public.premium_users (email, source, subscription_id, expires_at)
  values (v_email, 'subscription', v_subscription_id, v_period_end)
  on conflict (email) do update
    set source = excluded.source,
        subscription_id = excluded.subscription_id,
        expires_at = excluded.expires_at
    where premium_users.source = 'subscription'
       or premium_users.expires_at <= now();

  return new;
end;
$$;

revoke execute on function private.sync_premium_from_subscriptions() from public, anon, authenticated;

create trigger subscriptions_sync_premium
  after insert or update of status, current_period_end on public.subscriptions
  for each row execute function private.sync_premium_from_subscriptions();

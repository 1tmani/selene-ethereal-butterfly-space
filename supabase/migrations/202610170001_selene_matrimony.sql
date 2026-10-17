-- Selene Matrimony initial schema
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 50),
  age smallint not null check (age between 18 and 100),
  gender text not null default 'Prefer not to say' check (gender in ('Woman','Man','Non-binary','Prefer not to say')),
  looking_for text not null default 'Open to discussion' check (looking_for in ('Woman','Man','Open to discussion')),
  city text not null check (char_length(city) between 1 and 80),
  profession text not null default '',
  bio text not null default '' check (char_length(bio) <= 700),
  marriage_timeline text not null default 'Open to discussion' check (marriage_timeline in ('Within a year','1–2 years','Open to discussion')),
  interests text[] not null default '{}',
  is_visible boolean not null default true,
  is_verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.interests (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references auth.users(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','accepted','declined','withdrawn')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint interests_no_self check (sender_id <> recipient_id),
  constraint interests_unique_pair unique (sender_id, recipient_id)
);

create table if not exists public.memberships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  plan text not null check (plan in ('Free','Silver','Gold','Platinum')),
  status text not null default 'pending_payment' check (status in ('pending_payment','active','expired','cancelled','payment_failed')),
  amount_inr integer not null default 0 check (amount_inr >= 0),
  provider text,
  provider_order_id text,
  provider_payment_id text,
  started_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists profiles_visible_city_idx on public.profiles (is_visible, city);
create index if not exists interests_recipient_status_idx on public.interests (recipient_id, status, created_at desc);
create index if not exists memberships_user_status_idx on public.memberships (user_id, status, expires_at desc);

alter table public.profiles enable row level security;
alter table public.interests enable row level security;
alter table public.memberships enable row level security;

drop policy if exists "Visible profiles are discoverable by signed-in members" on public.profiles;
create policy "Visible profiles are discoverable by signed-in members"
  on public.profiles for select to authenticated
  using (is_visible = true or user_id = (select auth.uid()));

drop policy if exists "Members create their own profile" on public.profiles;
create policy "Members create their own profile"
  on public.profiles for insert to authenticated
  with check (user_id = (select auth.uid()));

drop policy if exists "Members update their own profile" on public.profiles;
create policy "Members update their own profile"
  on public.profiles for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists "Participants can view their own interests" on public.interests;
create policy "Participants can view their own interests"
  on public.interests for select to authenticated
  using (sender_id = (select auth.uid()) or recipient_id = (select auth.uid()));

drop policy if exists "Members can send interest" on public.interests;
create policy "Members can send interest"
  on public.interests for insert to authenticated
  with check (sender_id = (select auth.uid()) and recipient_id <> (select auth.uid()));

drop policy if exists "Recipients can respond to interests" on public.interests;
create policy "Recipients can respond to interests"
  on public.interests for update to authenticated
  using (recipient_id = (select auth.uid()))
  with check (recipient_id = (select auth.uid()) and status in ('accepted','declined'));

drop policy if exists "Members can read own memberships" on public.memberships;
create policy "Members can read own memberships"
  on public.memberships for select to authenticated
  using (user_id = (select auth.uid()));

-- Membership writes are intentionally server-only. Never trust a browser to mark a payment as paid.
revoke insert, update, delete on public.memberships from anon, authenticated;
grant select on public.memberships to authenticated;

-- Create a profile from signup metadata without exposing a callable RPC.
create or replace function public.handle_new_matrimony_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (
    user_id, display_name, age, gender, looking_for, city, profession, bio, marriage_timeline
  )
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'display_name',''), 'New member'),
    greatest(18, least(100, coalesce(nullif(new.raw_user_meta_data ->> 'age','')::smallint, 18))),
    coalesce(nullif(new.raw_user_meta_data ->> 'gender',''), 'Prefer not to say'),
    coalesce(nullif(new.raw_user_meta_data ->> 'looking_for',''), 'Open to discussion'),
    coalesce(nullif(new.raw_user_meta_data ->> 'city',''), 'Not specified'),
    coalesce(new.raw_user_meta_data ->> 'profession',''),
    coalesce(new.raw_user_meta_data ->> 'bio',''),
    coalesce(nullif(new.raw_user_meta_data ->> 'marriage_timeline',''), 'Open to discussion')
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

revoke all on function public.handle_new_matrimony_user() from public, anon, authenticated;
drop trigger if exists on_auth_user_created_matrimony on auth.users;
create trigger on_auth_user_created_matrimony
  after insert on auth.users
  for each row execute procedure public.handle_new_matrimony_user();

grant select, insert, update on public.profiles to authenticated;
grant select, insert, update on public.interests to authenticated;

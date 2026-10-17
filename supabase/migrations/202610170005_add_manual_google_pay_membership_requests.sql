create table if not exists public.payment_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  plan text not null check (plan in ('Silver','Gold','Platinum')),
  amount_inr integer not null check (
    (plan = 'Silver' and amount_inr = 499) or
    (plan = 'Gold' and amount_inr = 999) or
    (plan = 'Platinum' and amount_inr = 1999)
  ),
  payment_method text not null default 'Google Pay',
  payee_phone text not null default '7888554681',
  transaction_ref text not null check (char_length(transaction_ref) between 8 and 80),
  status text not null default 'pending' check (status in ('pending','verified','rejected')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  unique (transaction_ref)
);
alter table public.payment_requests enable row level security;
revoke all on table public.payment_requests from anon, authenticated;
grant select on table public.payment_requests to authenticated;
grant insert (user_id, plan, amount_inr, payment_method, payee_phone, transaction_ref)
  on table public.payment_requests to authenticated;
create policy "Members can submit their own payment requests"
  on public.payment_requests for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and status = 'pending'
    and reviewed_at is null
    and payment_method = 'Google Pay'
    and payee_phone = '7888554681'
  );
create policy "Members can view their own payment requests"
  on public.payment_requests for select to authenticated
  using (user_id = (select auth.uid()));

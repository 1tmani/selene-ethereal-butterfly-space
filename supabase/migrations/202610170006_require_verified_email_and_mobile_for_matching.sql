-- Require verified email (Supabase Auth confirmation) and verified mobile before member discovery,
-- matching interactions, and paid membership requests. Supabase only places a confirmed phone
-- number in the authenticated JWT's phone claim.
drop policy if exists "Visible profiles are discoverable by signed-in members" on public.profiles;
create policy "Verified members discover visible profiles"
  on public.profiles for select to authenticated
  using (
    user_id = (select auth.uid())
    or (
      is_visible = true
      and coalesce((select auth.jwt()) ->> 'phone', '') <> ''
    )
  );

drop policy if exists "Members can send interest" on public.interests;
create policy "Verified members can send interest"
  on public.interests for insert to authenticated
  with check (
    sender_id = (select auth.uid())
    and recipient_id <> (select auth.uid())
    and status = 'pending'
    and coalesce((select auth.jwt()) ->> 'phone', '') <> ''
  );

drop policy if exists "Participants can view their own interests" on public.interests;
create policy "Verified participants can view interests"
  on public.interests for select to authenticated
  using (
    (sender_id = (select auth.uid()) or recipient_id = (select auth.uid()))
    and coalesce((select auth.jwt()) ->> 'phone', '') <> ''
  );

drop policy if exists "Recipients can respond to interests" on public.interests;
create policy "Verified recipients can respond to interests"
  on public.interests for update to authenticated
  using (
    recipient_id = (select auth.uid())
    and coalesce((select auth.jwt()) ->> 'phone', '') <> ''
  )
  with check (
    recipient_id = (select auth.uid())
    and status = any (array['accepted','declined'])
    and coalesce((select auth.jwt()) ->> 'phone', '') <> ''
  );

drop policy if exists "Members can submit their own payment requests" on public.payment_requests;
create policy "Verified members can submit payment requests"
  on public.payment_requests for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and status = 'pending'
    and reviewed_at is null
    and payment_method = 'Google Pay'
    and payee_phone = '7888554681'
    and coalesce((select auth.jwt()) ->> 'phone', '') <> ''
  );

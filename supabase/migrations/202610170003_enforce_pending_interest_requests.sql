-- Prevent a sender from inserting an interest already marked accepted or declined.
drop policy if exists "Members can send interest" on public.interests;
create policy "Members can send interest"
  on public.interests for insert to authenticated
  with check (
    sender_id = (select auth.uid())
    and recipient_id <> (select auth.uid())
    and status = 'pending'
  );

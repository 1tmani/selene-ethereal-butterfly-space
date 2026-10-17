-- Tighten public API grants for Selene Matrimony.
-- RLS policies remain the row-level boundary; grants restrict which columns clients can write.
revoke all on table public.profiles from anon;
revoke all on table public.interests from anon;
revoke all on table public.memberships from anon;

revoke all on table public.profiles from authenticated;
grant select on table public.profiles to authenticated;
grant insert (user_id, display_name, age, gender, looking_for, city, profession, bio, marriage_timeline, interests, is_visible)
  on table public.profiles to authenticated;
grant update (display_name, age, gender, looking_for, city, profession, bio, marriage_timeline, interests, is_visible, updated_at)
  on table public.profiles to authenticated;

revoke all on table public.interests from authenticated;
grant select, insert on table public.interests to authenticated;
grant update (status, updated_at) on table public.interests to authenticated;

revoke all on table public.memberships from authenticated;
grant select on table public.memberships to authenticated;

-- This pre-existing event-trigger helper should not be exposed as a callable public API.
revoke all on function public.rls_auto_enable() from public, anon, authenticated;

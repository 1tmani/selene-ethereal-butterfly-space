-- New Selene signups receive a Free membership; paid memberships still require server-verified payment.
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

  insert into public.memberships (user_id, plan, status, amount_inr, started_at)
  values (new.id, 'Free', 'active', 0, now())
  on conflict do nothing;

  return new;
end;
$$;

revoke all on function public.handle_new_matrimony_user() from public, anon, authenticated;

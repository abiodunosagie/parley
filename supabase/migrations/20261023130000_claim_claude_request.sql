-- Rate limits as one atomic step. Counting rows and inserting the new one in separate calls let
-- a burst of parallel requests all see the same count and all pass. This function takes a lock,
-- checks every limit, and only then records the request, so the limits hold under any burst.
-- Token totals are capped too: request counts alone would let one user send only the most
-- expensive calls.

alter table public.claude_requests add column ip_hash text;
create index claude_requests_ip_recent on public.claude_requests (ip_hash, created_at desc);

create function public.claim_claude_request(
  p_user uuid,
  p_ip_hash text,
  p_mode text,
  p_model text,
  p_user_per_minute integer,
  p_user_per_day integer,
  p_ip_per_day integer,
  p_project_per_day integer,
  p_user_tokens_per_day bigint,
  p_project_tokens_per_day bigint
)
returns table (request_id bigint, refusal text)
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_id bigint;
begin
  -- One claim at a time. Parley's traffic is small, so a single lock is simpler than per-user ones
  -- and also keeps the project-wide counts exact.
  perform pg_advisory_xact_lock(hashtext('parley.claim_claude_request'));

  if (select count(*) from public.claude_requests
      where user_id = p_user and created_at > now() - interval '1 minute') >= p_user_per_minute then
    return query select null::bigint, 'user_minute'::text;
    return;
  end if;

  if (select count(*) from public.claude_requests
      where user_id = p_user and created_at > now() - interval '1 day') >= p_user_per_day then
    return query select null::bigint, 'user_day'::text;
    return;
  end if;

  if p_ip_hash is not null and (select count(*) from public.claude_requests
      where ip_hash = p_ip_hash and created_at > now() - interval '1 day') >= p_ip_per_day then
    return query select null::bigint, 'ip_day'::text;
    return;
  end if;

  if (select coalesce(sum(coalesce(input_tokens, 0) + coalesce(output_tokens, 0)), 0)
      from public.claude_requests
      where user_id = p_user and created_at > now() - interval '1 day') >= p_user_tokens_per_day then
    return query select null::bigint, 'user_tokens'::text;
    return;
  end if;

  if (select count(*) from public.claude_requests
      where created_at > now() - interval '1 day') >= p_project_per_day
     or (select coalesce(sum(coalesce(input_tokens, 0) + coalesce(output_tokens, 0)), 0)
         from public.claude_requests
         where created_at > now() - interval '1 day') >= p_project_tokens_per_day then
    return query select null::bigint, 'project_day'::text;
    return;
  end if;

  insert into public.claude_requests (user_id, ip_hash, mode, model)
  values (p_user, p_ip_hash, p_mode, p_model)
  returning id into new_id;

  return query select new_id, null::text;
end;
$$;

revoke execute on function public.claim_claude_request from public, anon, authenticated;
grant execute on function public.claim_claude_request to service_role;

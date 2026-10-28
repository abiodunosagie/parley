-- Requests made with the user's own Anthropic key. The user pays for those, so they are still
-- logged and still held to the per-minute limit and a per-user daily count of their own (the edge
-- function passes a larger p_user_per_day for them), but they never count against the daily
-- request, token, network, search or project budgets that the shared key needs.

alter table public.claude_requests add column own_key boolean not null default false;

drop function public.claim_claude_request(uuid, text, text, text, integer, integer, integer, integer, bigint, bigint);

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
  p_project_tokens_per_day bigint,
  p_own_key boolean default false
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

  -- Every request, on either key, counts toward the per-minute limit.
  if (select count(*) from public.claude_requests
      where user_id = p_user and created_at > now() - interval '1 minute') >= p_user_per_minute then
    return query select null::bigint, 'user_minute'::text;
    return;
  end if;

  -- The daily count is per kind: own-key requests and shared-key requests each have their own.
  if (select count(*) from public.claude_requests
      where user_id = p_user and own_key = p_own_key and created_at > now() - interval '1 day') >= p_user_per_day then
    return query select null::bigint, 'user_day'::text;
    return;
  end if;

  if not p_own_key then
    if p_ip_hash is not null and (select count(*) from public.claude_requests
        where ip_hash = p_ip_hash and not own_key and created_at > now() - interval '1 day') >= p_ip_per_day then
      return query select null::bigint, 'ip_day'::text;
      return;
    end if;

    if (select coalesce(sum(coalesce(input_tokens, 0) + coalesce(output_tokens, 0)), 0)
        from public.claude_requests
        where user_id = p_user and not own_key and created_at > now() - interval '1 day') >= p_user_tokens_per_day then
      return query select null::bigint, 'user_tokens'::text;
      return;
    end if;

    if (select count(*) from public.claude_requests
        where not own_key and created_at > now() - interval '1 day') >= p_project_per_day
       or (select coalesce(sum(coalesce(input_tokens, 0) + coalesce(output_tokens, 0)), 0)
           from public.claude_requests
           where not own_key and created_at > now() - interval '1 day') >= p_project_tokens_per_day then
      return query select null::bigint, 'project_day'::text;
      return;
    end if;
  end if;

  insert into public.claude_requests (user_id, ip_hash, mode, model, own_key)
  values (p_user, p_ip_hash, p_mode, p_model, p_own_key)
  returning id into new_id;

  return query select new_id, null::text;
end;
$$;

revoke execute on function public.claim_claude_request from public, anon, authenticated;
grant execute on function public.claim_claude_request to service_role;

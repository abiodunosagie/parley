-- Web searches are billed per search, apart from tokens, so each logged request records how many
-- it ran. The edge function sums them to cap searches per user per day.
alter table public.claude_requests
  add column web_searches integer not null default 0;

create index claude_requests_user_searches
  on public.claude_requests (user_id, created_at desc)
  where web_searches > 0;

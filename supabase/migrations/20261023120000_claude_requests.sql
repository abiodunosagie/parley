-- Every Claude call the edge function makes is logged here. The function counts recent rows to
-- rate limit each user and the whole project, so a leaked app build cannot drain the API credit.
-- Only the function (service role) touches this table: RLS is on with no policies for clients.

create table public.claude_requests (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  mode text not null check (mode in ('chat', 'vision', 'extract', 'agent')),
  model text not null,
  input_tokens integer,
  output_tokens integer,
  created_at timestamptz not null default now()
);

create index claude_requests_user_recent on public.claude_requests (user_id, created_at desc);
create index claude_requests_recent on public.claude_requests (created_at desc);

alter table public.claude_requests enable row level security;
revoke all on public.claude_requests from anon, authenticated;

-- New Claude modes: documents with citations, rewriting, and receipts.
-- Swaps the mode check on claude_requests; existing rows all use the older four modes.
alter table public.claude_requests drop constraint if exists claude_requests_mode_check;
alter table public.claude_requests
  add constraint claude_requests_mode_check
  check (mode in ('chat', 'vision', 'document', 'rewrite', 'extract', 'receipt', 'agent'));

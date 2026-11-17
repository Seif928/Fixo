-- Optional photos and technician verification documents; server-only Storage API.
-- This creates no public object policies and does not enable billing.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('fixo-private', 'fixo-private', false, 2097152,
        array['image/jpeg','image/png','image/webp','application/pdf'])
on conflict (id) do nothing;

-- Inspect before enabling real uploads; never silently reuse a public bucket.
select id, public, file_size_limit, allowed_mime_types
from storage.buckets where id = 'fixo-private';
select policyname, roles, cmd from pg_policies
where schemaname = 'storage' and tablename = 'objects';

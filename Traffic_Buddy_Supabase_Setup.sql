-- TRAFFIC BUDDY SUPABASE SETUP
-- Run this whole file in Supabase Dashboard -> SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  age integer check (age is null or age between 13 and 120),
  mobile_number text,
  created_at timestamptz not null default now()
);

-- Safe for projects where the profiles table was created by an earlier setup.
alter table public.profiles add column if not exists age integer check (age is null or age between 13 and 120);
alter table public.profiles add column if not exists mobile_number text;

create table if not exists public.vehicles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  vehicle_name text not null,
  registration_number text not null,
  vehicle_type text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.vehicle_documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  vehicle_id uuid not null references public.vehicles(id) on delete cascade,
  document_type text not null,
  document_number text,
  expiry_date date,
  original_file_name text not null,
  storage_path text not null unique,
  mime_type text,
  file_size bigint,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.vehicles enable row level security;
alter table public.vehicle_documents enable row level security;

drop policy if exists "Users can view own profile" on public.profiles;
drop policy if exists "Users can insert own profile" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;

create policy "Users can view own profile" on public.profiles
for select to authenticated using (id = (select auth.uid()));

create policy "Users can insert own profile" on public.profiles
for insert to authenticated with check (id = (select auth.uid()));

create policy "Users can update own profile" on public.profiles
for update to authenticated using (id = (select auth.uid()))
with check (id = (select auth.uid()));

drop policy if exists "Users can view own vehicles" on public.vehicles;
drop policy if exists "Users can insert own vehicles" on public.vehicles;
drop policy if exists "Users can update own vehicles" on public.vehicles;
drop policy if exists "Users can delete own vehicles" on public.vehicles;

create policy "Users can view own vehicles" on public.vehicles
for select to authenticated using (user_id = (select auth.uid()));

create policy "Users can insert own vehicles" on public.vehicles
for insert to authenticated with check (user_id = (select auth.uid()));

create policy "Users can update own vehicles" on public.vehicles
for update to authenticated using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy "Users can delete own vehicles" on public.vehicles
for delete to authenticated using (user_id = (select auth.uid()));

drop policy if exists "Users can view own documents" on public.vehicle_documents;
drop policy if exists "Users can insert own documents" on public.vehicle_documents;
drop policy if exists "Users can update own documents" on public.vehicle_documents;
drop policy if exists "Users can delete own documents" on public.vehicle_documents;

create policy "Users can view own documents" on public.vehicle_documents
for select to authenticated using (user_id = (select auth.uid()));

create policy "Users can insert own documents" on public.vehicle_documents
for insert to authenticated
with check (
  user_id = (select auth.uid())
  and exists (
    select 1 from public.vehicles v
    where v.id = vehicle_id and v.user_id = (select auth.uid())
  )
);

create policy "Users can update own documents" on public.vehicle_documents
for update to authenticated using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy "Users can delete own documents" on public.vehicle_documents
for delete to authenticated using (user_id = (select auth.uid()));

grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.vehicles to authenticated;
grant select, insert, update, delete on public.vehicle_documents to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'vehicle-documents','vehicle-documents',false,10485760,
  array['application/pdf','image/jpeg','image/png','image/webp']
)
on conflict (id) do update set
  public=false,
  file_size_limit=10485760,
  allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists "Users can upload own vehicle documents" on storage.objects;
drop policy if exists "Users can read own vehicle documents" on storage.objects;
drop policy if exists "Users can update own vehicle documents" on storage.objects;
drop policy if exists "Users can delete own vehicle documents" on storage.objects;

create policy "Users can upload own vehicle documents"
on storage.objects for insert to authenticated
with check (
  bucket_id='vehicle-documents'
  and (storage.foldername(name))[1]=(select auth.uid()::text)
);

create policy "Users can read own vehicle documents"
on storage.objects for select to authenticated
using (
  bucket_id='vehicle-documents'
  and owner_id=(select auth.uid()::text)
);

create policy "Users can update own vehicle documents"
on storage.objects for update to authenticated
using (bucket_id='vehicle-documents' and owner_id=(select auth.uid()::text))
with check (bucket_id='vehicle-documents' and owner_id=(select auth.uid()::text));

create policy "Users can delete own vehicle documents"
on storage.objects for delete to authenticated
using (bucket_id='vehicle-documents' and owner_id=(select auth.uid()::text));

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path=public
as $$
begin
  insert into public.profiles(id, full_name, age, mobile_number)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name','Traffic Buddy User'),
    nullif(new.raw_user_meta_data->>'age','')::integer,
    new.raw_user_meta_data->>'mobile_number'
  )
  on conflict (id) do update set
    full_name=excluded.full_name,
    age=excluded.age,
    mobile_number=excluded.mobile_number;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- WAS Seed Cost Management schema
-- Apply only after checking the existing organizations and organization_members tables.
create extension if not exists pgcrypto;
create table if not exists public.cost_seasons (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id) on delete cascade,
 name text not null,
 starts_on date,
 ends_on date,
 is_active boolean not null default false,
 created_by uuid references auth.users(id),
 created_at timestamptz not null default now(),
 unique (organization_id,id)
);
create table if not exists public.cost_fields (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id) on delete cascade,
 season_id uuid not null,
 field_code text not null,
 farmer_name text not null,
 crop_name text not null,
 area_feddan numeric(12,2) not null check(area_feddan > 0),
 village text,
 contract_no text,
 notes text,
 created_by uuid references auth.users(id),
 created_at timestamptz not null default now(),
 unique(organization_id, season_id, field_code),
 unique(organization_id,id),
 foreign key (organization_id,season_id) references public.cost_seasons(organization_id,id) on delete cascade
);
create table if not exists public.cost_entries (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id) on delete cascade,
 season_id uuid not null,
 entry_date date not null default current_date,
 category text not null,
 description text,
 entry_mode text not null check(entry_mode in ('individual','shared')),
 total_amount numeric(14,2) not null check(total_amount > 0),
 quantity numeric(14,3),
 unit text,
 unit_price numeric(14,2),
 vendor text,
 receipt_ref text,
 notes text,
 allocation_basis text check(allocation_basis in ('individual','area','equal','manual')),
 created_by uuid references auth.users(id),
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key (organization_id,season_id) references public.cost_seasons(organization_id,id) on delete cascade
);
create table if not exists public.cost_allocations (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id) on delete cascade,
 cost_entry_id uuid not null,
 field_id uuid not null,
 allocated_amount numeric(14,2) not null check(allocated_amount >= 0),
 allocation_weight numeric(14,4),
 allocation_basis text not null check(allocation_basis in ('individual','area','equal','manual')),
 created_at timestamptz not null default now(),
 unique(cost_entry_id, field_id),
 foreign key (organization_id,cost_entry_id) references public.cost_entries(organization_id,id) on delete cascade,
 foreign key (organization_id,field_id) references public.cost_fields(organization_id,id) on delete cascade
);
create index if not exists cost_fields_search_idx on public.cost_fields(organization_id, field_code, farmer_name);
create index if not exists cost_entries_season_date_idx on public.cost_entries(organization_id, season_id, entry_date desc);
create index if not exists cost_allocations_field_idx on public.cost_allocations(organization_id, field_id);
alter table public.cost_seasons enable row level security;
alter table public.cost_fields enable row level security;
alter table public.cost_entries enable row level security;
alter table public.cost_allocations enable row level security;
do $$
declare t text;
begin
 foreach t in array array['cost_seasons','cost_fields','cost_entries','cost_allocations'] loop
  execute format('drop policy if exists "org members manage %1$s" on public.%1$I',t);
  execute format('create policy "org members manage %1$s" on public.%1$I for all to authenticated using (exists (select 1 from public.organization_members m where m.organization_id = %1$I.organization_id and m.user_id = (select auth.uid()))) with check (exists (select 1 from public.organization_members m where m.organization_id = %1$I.organization_id and m.user_id = (select auth.uid())))',t);
 end loop;
end $$;
grant select,insert,update,delete on public.cost_seasons,public.cost_fields,public.cost_entries,public.cost_allocations to authenticated;

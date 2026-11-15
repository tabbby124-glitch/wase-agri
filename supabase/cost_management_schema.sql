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
create policy "cost_seasons select members" on public.cost_seasons for select to authenticated using (private.is_org_member(organization_id));
create policy "cost_seasons insert editors" on public.cost_seasons for insert to authenticated with check (private.org_role(organization_id) = any (array['owner','admin','manager','engineer']::text[]));
create policy "cost_seasons update editors" on public.cost_seasons for update to authenticated using (private.org_role(organization_id) = any (array['owner','admin','manager','engineer']::text[])) with check (private.org_role(organization_id) = any (array['owner','admin','manager','engineer']::text[]));
create policy "cost_seasons delete editors" on public.cost_seasons for delete to authenticated using (private.org_role(organization_id) = any (array['owner','admin','manager','engineer']::text[]));
create policy "cost_fields select members" on public.cost_fields for select to authenticated using (private.is_org_member(organization_id));
create policy "cost_fields insert editors" on public.cost_fields for insert to authenticated with check (private.org_role(organization_id) = any (array['owner','admin','manager','engineer']::text[]));
create policy "cost_fields update editors" on public.cost_fields for update to authenticated using (private.org_role(organization_id) = any (array['owner','admin','manager','engineer']::text[])) with check (private.org_role(organization_id) = any (array['owner','admin','manager','engineer']::text[]));
create policy "cost_fields delete editors" on public.cost_fields for delete to authenticated using (private.org_role(organization_id) = any (array['owner','admin','manager','engineer']::text[]));
create policy "cost_entries select members" on public.cost_entries for select to authenticated using (private.is_org_member(organization_id));
create policy "cost_entries insert editors" on public.cost_entries for insert to authenticated with check (private.org_role(organization_id) = any (array['owner','admin','manager','engineer']::text[]));
create policy "cost_entries update editors" on public.cost_entries for update to authenticated using (private.org_role(organization_id) = any (array['owner','admin','manager','engineer']::text[])) with check (private.org_role(organization_id) = any (array['owner','admin','manager','engineer']::text[]));
create policy "cost_entries delete editors" on public.cost_entries for delete to authenticated using (private.org_role(organization_id) = any (array['owner','admin','manager','engineer']::text[]));
create policy "cost_allocations select members" on public.cost_allocations for select to authenticated using (private.is_org_member(organization_id));
create policy "cost_allocations insert editors" on public.cost_allocations for insert to authenticated with check (private.org_role(organization_id) = any (array['owner','admin','manager','engineer']::text[]));
create policy "cost_allocations update editors" on public.cost_allocations for update to authenticated using (private.org_role(organization_id) = any (array['owner','admin','manager','engineer']::text[])) with check (private.org_role(organization_id) = any (array['owner','admin','manager','engineer']::text[]));
create policy "cost_allocations delete editors" on public.cost_allocations for delete to authenticated using (private.org_role(organization_id) = any (array['owner','admin','manager','engineer']::text[]));
grant select,insert,update,delete on public.cost_seasons,public.cost_fields,public.cost_entries,public.cost_allocations to authenticated;

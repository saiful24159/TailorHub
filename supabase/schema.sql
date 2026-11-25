-- TailorHub database schema for Supabase PostgreSQL
-- Run in Supabase SQL Editor. Review policies before production.

create extension if not exists pgcrypto;

do $$ begin
  create type public.app_role as enum ('customer','seller','admin');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.seller_status as enum ('pending','approved','rejected','suspended');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.order_status as enum ('placed','measurement_review','confirmed','stitching','quality_check','ready','dispatched','delivered','cancelled');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.payment_status as enum ('unpaid','pending','paid','failed','refunded');
exception when duplicate_object then null; end $$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone text unique,
  district text,
  address text,
  role public.app_role not null default 'customer',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.seller_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  shop_name text not null,
  description text,
  district text not null,
  phone text not null,
  status public.seller_status not null default 'pending',
  commission_percent numeric(5,2) not null default 10 check (commission_percent >= 0 and commission_percent <= 100),
  created_at timestamptz not null default now()
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name_bn text not null,
  name_en text not null,
  slug text unique not null,
  is_active boolean not null default true,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid references public.profiles(id) on delete set null,
  category_id uuid references public.categories(id) on delete set null,
  name_bn text not null,
  name_en text,
  description text,
  base_price numeric(12,2) not null check (base_price >= 0),
  currency text not null default 'BDT',
  image_urls text[] not null default '{}',
  is_customizable boolean not null default true,
  is_active boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.measurements (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete cascade,
  label text not null default 'আমার মাপ',
  unit text not null default 'cm' check (unit in ('cm','inch')),
  values jsonb not null default '{}'::jsonb,
  source text not null default 'manual' check (source in ('manual','ai_estimate')),
  ai_disclaimer text,
  verified_by uuid references public.profiles(id) on delete set null,
  verified_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text unique not null,
  customer_id uuid not null references public.profiles(id),
  seller_id uuid references public.profiles(id),
  measurement_id uuid references public.measurements(id),
  status public.order_status not null default 'placed',
  payment_status public.payment_status not null default 'unpaid',
  subtotal numeric(12,2) not null check (subtotal >= 0),
  delivery_fee numeric(12,2) not null default 0 check (delivery_fee >= 0),
  total numeric(12,2) not null check (total >= 0),
  currency text not null default 'BDT',
  delivery_name text not null,
  delivery_phone text not null,
  delivery_address text not null,
  delivery_district text not null,
  customer_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  quantity int not null default 1 check (quantity > 0),
  unit_price numeric(12,2) not null check (unit_price >= 0),
  customization jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.payment_transactions (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  provider text not null check (provider in ('bkash','nagad','rocket','bank','cod')),
  provider_reference text,
  amount numeric(12,2) not null check (amount >= 0),
  status public.payment_status not null default 'pending',
  gateway_response jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.order_status_history (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  changed_by uuid references public.profiles(id) on delete set null,
  status public.order_status not null,
  note text,
  created_at timestamptz not null default now()
);

create index if not exists products_category_active_idx on public.products(category_id,is_active);
create index if not exists products_seller_idx on public.products(seller_id);
create index if not exists orders_customer_created_idx on public.orders(customer_id,created_at desc);
create index if not exists orders_seller_created_idx on public.orders(seller_id,created_at desc);
create index if not exists order_items_order_idx on public.order_items(order_id);
create index if not exists measurements_customer_idx on public.measurements(customer_id,created_at desc);

-- Automatically create a customer profile for each new Auth user.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, phone)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name',''), nullif(new.phone,''))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public
as $$
  select exists(select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

create or replace function public.is_approved_seller()
returns boolean language sql stable security definer set search_path = public
as $$
  select exists(select 1 from public.seller_profiles where user_id = auth.uid() and status = 'approved');
$$;

alter table public.profiles enable row level security;
alter table public.seller_profiles enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.measurements enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.payment_transactions enable row level security;
alter table public.order_status_history enable row level security;

-- Profiles: users can view/update their own profile; admins can manage all.
drop policy if exists "profile read own or admin" on public.profiles;
create policy "profile read own or admin" on public.profiles for select using (id = auth.uid() or public.is_admin());
drop policy if exists "profile update own or admin" on public.profiles;
create policy "profile update own or admin" on public.profiles for update using (id = auth.uid() or public.is_admin()) with check (id = auth.uid() or public.is_admin());

-- Seller profiles: owner can submit/read own application; admins review; public sees approved seller profile.
drop policy if exists "seller profile visibility" on public.seller_profiles;
create policy "seller profile visibility" on public.seller_profiles for select using (user_id = auth.uid() or status = 'approved' or public.is_admin());
drop policy if exists "seller apply" on public.seller_profiles;
create policy "seller apply" on public.seller_profiles for insert with check (user_id = auth.uid() and status = 'pending');
drop policy if exists "seller owner edit pending" on public.seller_profiles;
create policy "seller owner edit pending" on public.seller_profiles for update using (user_id = auth.uid() and status = 'pending' or public.is_admin()) with check (user_id = auth.uid() and status = 'pending' or public.is_admin());

-- Catalog: everyone can read active categories/products. Admin manages categories; approved sellers manage own products.
drop policy if exists "categories public read" on public.categories;
create policy "categories public read" on public.categories for select using (is_active or public.is_admin());
drop policy if exists "categories admin manage" on public.categories;
create policy "categories admin manage" on public.categories for all using (public.is_admin()) with check (public.is_admin());
drop policy if exists "products public read active" on public.products;
create policy "products public read active" on public.products for select using (is_active or seller_id = auth.uid() or public.is_admin());
drop policy if exists "seller insert products" on public.products;
create policy "seller insert products" on public.products for insert with check (seller_id = auth.uid() and public.is_approved_seller());
drop policy if exists "seller update own products" on public.products;
create policy "seller update own products" on public.products for update using ((seller_id = auth.uid() and public.is_approved_seller()) or public.is_admin()) with check ((seller_id = auth.uid() and public.is_approved_seller()) or public.is_admin());
drop policy if exists "seller delete own products" on public.products;
create policy "seller delete own products" on public.products for delete using ((seller_id = auth.uid() and public.is_approved_seller()) or public.is_admin());

-- Measurements and orders are private to customer, assigned seller, and admins.
drop policy if exists "measurement owner admin read" on public.measurements;
create policy "measurement owner admin read" on public.measurements for select using (customer_id = auth.uid() or public.is_admin() or exists(select 1 from public.orders o where o.measurement_id = id and o.seller_id = auth.uid()));
drop policy if exists "measurement owner insert" on public.measurements;
create policy "measurement owner insert" on public.measurements for insert with check (customer_id = auth.uid());
drop policy if exists "measurement owner update" on public.measurements;
create policy "measurement owner update" on public.measurements for update using (customer_id = auth.uid() or public.is_admin()) with check (customer_id = auth.uid() or public.is_admin());

drop policy if exists "orders participants read" on public.orders;
create policy "orders participants read" on public.orders for select using (customer_id = auth.uid() or seller_id = auth.uid() or public.is_admin());
drop policy if exists "customer create own orders" on public.orders;
create policy "customer create own orders" on public.orders for insert with check (customer_id = auth.uid());
drop policy if exists "order participant update limited" on public.orders;
create policy "order participant update limited" on public.orders for update using (seller_id = auth.uid() or public.is_admin()) with check (seller_id = auth.uid() or public.is_admin());

drop policy if exists "order items participant read" on public.order_items;
create policy "order items participant read" on public.order_items for select using (exists(select 1 from public.orders o where o.id = order_id and (o.customer_id = auth.uid() or o.seller_id = auth.uid() or public.is_admin())));
drop policy if exists "customer add order items" on public.order_items;
create policy "customer add order items" on public.order_items for insert with check (exists(select 1 from public.orders o where o.id = order_id and o.customer_id = auth.uid()));

drop policy if exists "payment participant read" on public.payment_transactions;
create policy "payment participant read" on public.payment_transactions for select using (exists(select 1 from public.orders o where o.id = order_id and (o.customer_id = auth.uid() or o.seller_id = auth.uid() or public.is_admin())));
drop policy if exists "payment admin manage" on public.payment_transactions;
create policy "payment admin manage" on public.payment_transactions for all using (public.is_admin()) with check (public.is_admin());

drop policy if exists "status history participant read" on public.order_status_history;
create policy "status history participant read" on public.order_status_history for select using (exists(select 1 from public.orders o where o.id = order_id and (o.customer_id = auth.uid() or o.seller_id = auth.uid() or public.is_admin())));
drop policy if exists "seller admin add status" on public.order_status_history;
create policy "seller admin add status" on public.order_status_history for insert with check (changed_by = auth.uid() and (public.is_admin() or exists(select 1 from public.orders o where o.id = order_id and o.seller_id = auth.uid())));

-- Seed core categories (safe to re-run).
insert into public.categories(name_bn,name_en,slug,sort_order) values
('শার্ট','Shirts','shirts',1),('প্যান্ট','Trousers','trousers',2),('পাঞ্জাবি','Panjabi','panjabi',3),
('স্যুট ও ব্লেজার','Suits & Blazers','suits-blazers',4),('টি-শার্ট','T-shirts','t-shirts',5),
('নারীদের পোশাক','Women clothing','women',6),('শিশুদের পোশাক','Kids clothing','kids',7)
on conflict (slug) do nothing;

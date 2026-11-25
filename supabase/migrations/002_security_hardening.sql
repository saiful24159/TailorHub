-- Security hardening and trusted order creation for TailorHub.
-- Apply after supabase/schema.sql. Existing demo/test orders are not modified.

drop policy if exists "customer create own orders" on public.orders;
drop policy if exists "order participant update limited" on public.orders;
drop policy if exists "customer add order items" on public.order_items;
drop policy if exists "measurement owner update" on public.measurements;

-- Only this database function can create orders. Prices and seller are read from
-- the active product records; browser-supplied totals and seller IDs are ignored.
create or replace function public.create_customer_order(
  p_items jsonb,
  p_measurement_id uuid,
  p_delivery_name text,
  p_delivery_phone text,
  p_delivery_address text,
  p_delivery_district text,
  p_customer_note text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_customer uuid := auth.uid();
  v_order_id uuid;
  v_order_number text;
  v_seller uuid := null;
  v_item jsonb;
  v_product public.products%rowtype;
  v_qty integer;
  v_subtotal numeric(12,2) := 0;
  v_first boolean := true;
begin
  if v_customer is null then
    raise exception 'Authentication required';
  end if;
  if p_items is null or jsonb_typeof(p_items) is distinct from 'array' or jsonb_array_length(p_items) < 1 or jsonb_array_length(p_items) > 20 then
    raise exception 'Cart must contain between 1 and 20 items';
  end if;
  if coalesce(trim(p_delivery_name),'') = '' or coalesce(trim(p_delivery_phone),'') = ''
     or coalesce(trim(p_delivery_address),'') = '' or coalesce(trim(p_delivery_district),'') = '' then
    raise exception 'Delivery details are required';
  end if;
  if p_measurement_id is not null and not exists (
    select 1 from public.measurements m where m.id = p_measurement_id and m.customer_id = v_customer
  ) then
    raise exception 'Measurement does not belong to this customer';
  end if;

  for v_item in select value from jsonb_array_elements(p_items)
  loop
    if coalesce(v_item->>'product_id','') = '' then
      raise exception 'Each item requires a product_id';
    end if;
    v_qty := coalesce((v_item->>'quantity')::integer, 1);
    if v_qty < 1 or v_qty > 10 then
      raise exception 'Quantity must be between 1 and 10';
    end if;

    select * into v_product
      from public.products
      where id = (v_item->>'product_id')::uuid and is_active = true
      for share;
    if not found then
      raise exception 'A selected product is unavailable';
    end if;

    if v_first then
      v_seller := v_product.seller_id;
      v_first := false;
    elsif v_product.seller_id is distinct from v_seller then
      raise exception 'Please place separate orders for products from different sellers';
    end if;

    v_subtotal := v_subtotal + (v_product.base_price * v_qty);
  end loop;

  v_order_number := 'TH-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,12));
  insert into public.orders (
    order_number, customer_id, seller_id, measurement_id, status, payment_status,
    subtotal, delivery_fee, total, currency, delivery_name, delivery_phone,
    delivery_address, delivery_district, customer_note
  ) values (
    v_order_number, v_customer, v_seller, p_measurement_id, 'placed', 'unpaid',
    v_subtotal, 0, v_subtotal, 'BDT', trim(p_delivery_name), trim(p_delivery_phone),
    trim(p_delivery_address), trim(p_delivery_district), nullif(trim(p_customer_note),'')
  ) returning id into v_order_id;

  for v_item in select value from jsonb_array_elements(p_items)
  loop
    v_qty := coalesce((v_item->>'quantity')::integer, 1);
    select * into v_product from public.products where id = (v_item->>'product_id')::uuid;
    insert into public.order_items(order_id, product_id, product_name, quantity, unit_price, customization)
    values (
      v_order_id, v_product.id, v_product.name_bn, v_qty, v_product.base_price,
      case when jsonb_typeof(v_item->'customization') = 'object' then v_item->'customization' else '{}'::jsonb end
    );
  end loop;

  insert into public.order_status_history(order_id, changed_by, status, note)
  values (v_order_id, v_customer, 'placed', 'Customer order created');
  return v_order_id;
end;
$$;

revoke all on function public.create_customer_order(jsonb,uuid,text,text,text,text,text) from public;
grant execute on function public.create_customer_order(jsonb,uuid,text,text,text,text,text) to authenticated;

-- Sellers may only move an order through the operational workflow. Payment status,
-- totals, seller assignment and customer delivery data are never editable here.
create or replace function public.seller_update_order_status(
  p_order_id uuid,
  p_new_status public.order_status,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_old_status public.order_status;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select status into v_old_status
    from public.orders
    where id = p_order_id and seller_id = auth.uid()
    for update;
  if not found then raise exception 'Order not found for this seller'; end if;
  if p_new_status not in ('measurement_review','confirmed','stitching','quality_check','ready','dispatched','delivered','cancelled') then
    raise exception 'Invalid seller status';
  end if;
  if v_old_status in ('delivered','cancelled') then raise exception 'This order is already closed'; end if;
  update public.orders set status = p_new_status, updated_at = now() where id = p_order_id;
  insert into public.order_status_history(order_id,changed_by,status,note)
  values (p_order_id,auth.uid(),p_new_status,nullif(trim(p_note),''));
end;
$$;

revoke all on function public.seller_update_order_status(uuid,public.order_status,text) from public;
grant execute on function public.seller_update_order_status(uuid,public.order_status,text) to authenticated;

comment on function public.create_customer_order(jsonb,uuid,text,text,text,text,text)
is 'Secure order creation: derives price and seller from active products; never trusts browser totals.';


-- Prevent applicants from setting their own approval state or commission.
create or replace function public.protect_seller_application()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.is_admin() then
    return new;
  end if;
  if tg_op = 'INSERT' then
    new.status := 'pending';
    new.commission_percent := 10;
  else
    if new.user_id is distinct from old.user_id
       or new.status is distinct from old.status
       or new.commission_percent is distinct from old.commission_percent then
      raise exception 'Only an administrator can change seller status or commission';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists protect_seller_application_trigger on public.seller_profiles;
create trigger protect_seller_application_trigger
before insert or update on public.seller_profiles
for each row execute procedure public.protect_seller_application();

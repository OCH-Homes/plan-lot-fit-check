-- ============================================================
-- OCH Lot Map — Supabase backend setup
-- Run this once in Supabase: Dashboard -> SQL Editor -> New query -> paste -> Run
-- ============================================================

-- 1. Current state, one row per lot per community -------------
create table if not exists lot_state (
  community   text  not null,
  block       text  not null,
  lot         int   not null,
  plan_id     text,                       -- e.g. 'campbell_c'; null = unassigned
  excluded    boolean not null default false,
  updated_at  timestamptz not null default now(),
  updated_by  text,
  primary key (community, block, lot)
);

-- 2. Per-community settings (monotony rule, etc.) -------------
create table if not exists community_settings (
  community  text not null,
  key        text not null,
  value      text,
  updated_at timestamptz not null default now(),
  updated_by text,
  primary key (community, key)
);

-- 3. Append-only history — who changed what, when ------------
create table if not exists change_log (
  id          bigserial primary key,
  community   text not null,
  block       text,
  lot         int,
  field       text not null,             -- 'plan_id' | 'excluded' | 'setting'
  old_value   text,
  new_value   text,
  changed_at  timestamptz not null default now(),
  changed_by  text
);

create index if not exists change_log_community_idx on change_log (community, changed_at desc);

-- 4. Log every change to lot_state automatically -------------
create or replace function log_lot_change() returns trigger as $$
begin
  if tg_op = 'UPDATE' then
    if coalesce(old.plan_id,'') <> coalesce(new.plan_id,'') then
      insert into change_log (community, block, lot, field, old_value, new_value, changed_by)
      values (new.community, new.block, new.lot, 'plan_id', old.plan_id, new.plan_id, new.updated_by);
    end if;
    if old.excluded <> new.excluded then
      insert into change_log (community, block, lot, field, old_value, new_value, changed_by)
      values (new.community, new.block, new.lot, 'excluded', old.excluded::text, new.excluded::text, new.updated_by);
    end if;
  elsif tg_op = 'INSERT' then
    insert into change_log (community, block, lot, field, old_value, new_value, changed_by)
    values (new.community, new.block, new.lot, 'created', null,
            coalesce(new.plan_id,'') || case when new.excluded then ' (excluded)' else '' end, new.updated_by);
  end if;
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists lot_state_log on lot_state;
create trigger lot_state_log
  before insert or update on lot_state
  for each row execute function log_lot_change();

-- 5. Row Level Security -------------------------------------
-- The anon key is public by design, so these policies decide what the
-- world can do. As written: anyone with the URL can read and write.
-- That is the trade-off for zero per-person setup. The app adds a shared
-- passphrase on top, which deters casual edits but is NOT security.
alter table lot_state          enable row level security;
alter table community_settings enable row level security;
alter table change_log         enable row level security;

drop policy if exists lot_state_all on lot_state;
create policy lot_state_all on lot_state
  for all to anon using (true) with check (true);

drop policy if exists settings_all on community_settings;
create policy settings_all on community_settings
  for all to anon using (true) with check (true);

-- History is append-only and readable; it must never be edited or deleted.
drop policy if exists log_read on change_log;
create policy log_read on change_log for select to anon using (true);
drop policy if exists log_insert on change_log;
create policy log_insert on change_log for insert to anon with check (true);

-- ============================================================
-- TO LOCK IT DOWN LATER (recommended once the team is settled)
-- Replace the two "for all" policies above with:
--
--   create policy lot_state_read on lot_state
--     for select to anon using (true);
--   create policy lot_state_write on lot_state
--     for all to authenticated using (true) with check (true);
--
-- Then turn on Supabase Auth (magic link is simplest) and invite the
-- people who should be able to edit. Everyone else keeps read access
-- with no sign-in. This is the only way to get real attribution.
-- ============================================================

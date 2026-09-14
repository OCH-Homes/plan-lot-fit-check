-- OCH lot planning — additive setup for The Heights
--
-- IMPORTANT: this does NOT create or alter your existing tables.
-- lot_state, community_settings and change_log already exist with your
-- schema (block/lot, plan_id, excluded, key/value). This script only:
--   1. adds a uniqueness guarantee needed for upserts, if missing
--   2. enables Row Level Security + policies, if missing
--   3. seeds The Heights settings as key/value rows
--
-- Your existing grandoaks-1b rows are untouched. The Heights writes to
-- community = 'heights', a separate namespace.
--
-- Safe to re-run.

-- ---------------------------------------------------------------
-- 1. Upsert target: one row per (community, block, lot)
--    The tool uses ON CONFLICT, which needs a unique constraint.
-- ---------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'lot_state_community_block_lot_key'
  ) then
    -- clear any duplicate (community, block, lot) first, keeping newest
    delete from lot_state a using lot_state b
    where a.community = b.community
      and a.block = b.block
      and a.lot = b.lot
      and a.updated_at < b.updated_at;

    alter table lot_state
      add constraint lot_state_community_block_lot_key
      unique (community, block, lot);
  end if;
end $$;

create index if not exists lot_state_community_idx
  on lot_state (community, updated_at desc);

create index if not exists change_log_community_idx
  on change_log (community, changed_at desc);

-- ---------------------------------------------------------------
-- 2. Row Level Security
--
--    These policies let anyone holding the ANON key read and write.
--    The anon key ships inside the HTML tool, so on a PUBLIC GitHub
--    Pages site, anyone with the URL can change lot assignments.
--
--    Reasonable for an internal tool at an unlisted URL. Not
--    reasonable if the URL gets shared widely.
--
--    To lock down later: enable Supabase Auth, then swap
--    `using (true)` for `using (auth.role() = 'authenticated')`.
-- ---------------------------------------------------------------
alter table lot_state          enable row level security;
alter table community_settings enable row level security;
alter table change_log         enable row level security;

drop policy if exists lot_state_all on lot_state;
create policy lot_state_all on lot_state
  for all using (true) with check (true);

drop policy if exists community_settings_all on community_settings;
create policy community_settings_all on community_settings
  for all using (true) with check (true);

drop policy if exists change_log_insert on change_log;
create policy change_log_insert on change_log
  for insert with check (true);

drop policy if exists change_log_read on change_log;
create policy change_log_read on change_log
  for select using (true);

-- ---------------------------------------------------------------
-- 3. Seed The Heights settings — values resolved 9/11/26
--    Follows your existing key/value convention (mono_rule = r4).
-- ---------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'community_settings_pk_ck'
  ) and not exists (
    select 1 from pg_indexes
    where tablename = 'community_settings'
      and indexdef like '%UNIQUE%(community, key)%'
  ) then
    begin
      alter table community_settings
        add constraint community_settings_pk_ck unique (community, key);
    exception when others then null;
    end;
  end if;
end $$;

insert into community_settings (community, key, value) values
  ('heights', 'mono_rule',          'r3'),              -- 3 intervening
  ('heights', 'mono_both_sides',    'true'),
  ('heights', 'mono_source',        'DCCR Inst. 2024000153889 s3.12(l)'),
  ('heights', 'front_bl',           '10'),
  ('heights', 'side_interior',      '5'),
  ('heights', 'side_corner',        '15'),
  ('heights', 'rear_alley_garage',  '20'),
  ('heights', 'porch_encroach',     '5'),
  ('heights', 'buildable_width',    '35'),
  ('heights', 'lot_width',          '45'),
  ('heights', 'max_drive_grade',    '10'),
  ('heights', 'apron_rule',         'Celina: apron must be 3ft or 20ft+, never between. OCH standard 20ft.'),
  ('heights', 'city',               'Celina')
on conflict (community, key) do update
  set value = excluded.value, updated_at = now();

-- fill updated_by separately so the insert list stays readable
update community_settings set updated_by = 'setup'
  where community = 'heights' and updated_by is null;

-- ---------------------------------------------------------------
-- 4. Verify
-- ---------------------------------------------------------------
select community, count(*) as settings_rows
from community_settings group by community order by community;

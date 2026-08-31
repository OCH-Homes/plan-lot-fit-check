# pl-lot-fit-check

Browser tools for lot planning at Olivia Clarke Homes. No install, no server.

The lot map keeps **one shared plan** — assignments and lot selections save centrally
and are stamped with whoever made them, so everyone opening the link sees the current
planned situation.

## Structure

```
index.html                      community picker + reference links
tools/lot-map.html              ONE map tool, serves every community
tools/driveway-grade-check.html standalone driveway calculator
data/communities.json           registry — which communities exist
data/grandoaks-1b.json          lot data for one community
reference/                      workbook, lot tables, setup standard
supabase-setup.sql              one-time database setup
```

The map is data-driven. `tools/lot-map.html?c=grandoaks-1b` loads
`data/grandoaks-1b.json`. Nothing about the tool is community-specific.

## Adding a community

1. Generate its data file into `data/<id>.json`
2. Add an entry to `data/communities.json` with `status:"active"` and the data path
3. Done — no code changes

Supabase keeps assignments separated by a `community` column, so communities never
collide and no extra database setup is needed per community.

## Setup (already done for this repo)

Database is live at `erszlacysbetmamlpfpm.supabase.co`. Credentials are in the `CFG`
block at the top of `tools/lot-map.html`. The publishable key is designed to sit in
the page — see the note on access below.

To recreate from scratch: create a Supabase project, run `supabase-setup.sql` in the
SQL editor, then paste the Project URL and publishable key into `CFG`.

## Publishing

**Settings → Pages →** Source `main`, folder `/ (root)` → Save.
Site appears at `https://<org>.github.io/pl-lot-fit-check/`.

## How the shared data works

- Opening the map pulls current state, so you always see the latest plan
- Assigning a plan, excluding a lot or changing the monotony rule saves immediately
- The map re-checks every 60 seconds, so an open session stays current
- Every change is logged with name and timestamp; the overview shows recent history
- If the database is unreachable the header shows **sync error** and work is kept
  locally so nothing is lost

## Access

As configured, **anyone with the link can read and change the data.** No sign-in.
That is the trade-off for zero per-person setup — fine for a small team, not fine if
the link travels further than intended.

The bottom of `supabase-setup.sql` has the policy change that makes writing require
a sign-in while reading stays open. Turn on Supabase Auth (magic link), invite the
editors, swap the policies. Attribution then becomes real rather than self-reported.

## Updating lot data

Lot geometry and elevations come from the recorded plat DWG and the grading xref —
not from the database. The database only holds decisions. So a plat or grading
revision means regenerating the community's JSON file. Assignments survive because
they key on block and lot.

## Caveats

Per-community caveats live in each data file under `meta.caveats` and surface on both
the index and the map. For Grand Oaks Phase 1B:

- **Driveway run assumed 21 ft** — shortest measured on a surveyed plot plan, so the
  conservative case. Measured runs ranged 20.9 to 29.4 ft.
- **Monotony rule unsettled** — two source documents conflict; both selectable.
- **6 lots flagged CHECK** — front spot elevation unconfirmed.
- **Lot D-2 outline** drawn ~41% under its platted area; its numbers are fine.

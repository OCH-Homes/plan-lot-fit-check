# OCH Lot Planning — Project Manifest

**This repo is the single source of truth.** If a file isn't here, it isn't current.

Last updated: 2026-09-17 — Heights complete

---

## The rule

Filenames don't identify the current version. Dates don't either.

On 9/11/26 three copies of the workbook were in circulation. The copy with the
newest-looking filename (`__6_`) was **older** on the Grand Oaks tabs and
**newer** on the Heights tabs. The copy that looked older (`__5_`) was the
reverse. Both were legitimately "current" for different work. Choosing either
one would have silently destroyed the other's work — and nearly did.

Only **content** identifies the current file. That's what `check_workbook.py`
tests.

---

## Session protocol

**Start of every session**

1. Pull `OCH_Plan_Library_Template_1.xlsx` from this repo — not from Downloads,
   not from a previous chat.
2. Run the check before editing anything:
   ```
   python3 check_workbook.py OCH_Plan_Library_Template_1.xlsx
   ```
3. If it reports problems, **stop**. Find the copy holding the missing work,
   diff the two, merge. Do not edit a file that fails the check — edits applied
   to an incomplete branch are how forks get created.

**End of every session**

4. Run the check again. It must come back clean.
5. Commit the workbook back to this repo with a one-line note on what changed.
6. Delete the local download. It has no further authority.

**Never** have two chats editing the workbook at the same time. That is the
mechanism that creates forks. Switching topics inside one chat is free; a
second chat on the same workbook is not.

---

## Canonical files

| File | What it is |
|---|---|
| `OCH_Plan_Library_Template_1.xlsx` | Master workbook — 6 tabs. The only live copy. |
| `check_workbook.py` | Integrity check. Run at session start and before commit. |
| `tools/lot-map.html` | **The** lot map. One tool, all communities, via `?c=<id>`. Supabase-wired. |
| `data/<community>.json` | Per-community plat, grading, addresses, adjacency |
| `data/communities.json` | Registry the index page renders from |
| `index.html` | Landing page |
| `supabase_setup.sql` | Additive Supabase setup. Adapts to the existing block/lot/plan_id schema; does not create or replace tables. Safe to re-run. |
| `DEPLOY.md` | Deployment and wiring steps |
| `Heights_OCH_grading_data.csv` | Per-lot pad / wall / slope data, 48 OCH lots |
| `MANIFEST.md` | This file |

**Retired — delete from the repo:**
- `heights_lot_tool.html` — standalone Heights tool, superseded by `tools/lot-map.html`.
  It duplicated the shared tool and would have drifted. Built before checking what
  the repo already had; that was the wrong order.
- `heights_lot_tool.html.html` — double extension, caused a 404
- `supabase-setup.sql` (hyphen) — superseded by `supabase_setup.sql` (underscore)
- any file with a `__N_` suffix — browser download artifacts, not versions

### Workbook tabs
- Read Me
- Plan Library — 19 plans
- Community Offerings
- Community Standards — one column per community
- Lot Constraints — GO Ph1A
- Lot Constraints — Heights — 48 OCH lots

---

## Status by community

### Grand Oaks at Green Meadows (Celina) — Phases 1A, 1B. No 1C.
Lot products: 50' and 60' only. Pads 40×80 (50') and 50×80 (60').

Complete:
- Driveway grade model, validated 6/6 against Roome.
  `grade = (pad + 0.83 − step-down − front spot elev) ÷ run`
  Constants: slab 0.83 ft, step-down 0.58 ft, run 21 ft, max grade 10%.
- 40' front-entry fit matrix — Renner, Shelby, Webber, all 9 elevations.
  Garage storage is a **5'-0" width add** on all three (measured off the
  OPT STOR @ GARAGE inset, not assumed). Fails the 40×80 pad universally;
  fits the 50×80 pad with ~5' side margin.

Blocked on developer lot split:
- Block B Lot 14 — driveway worksheet vs. Lot Constraints conflict. Not yet
  diagnosed; needs the actual driveway worksheet.
- Full Phase 1B lot-level fit run — needs confirmed lot list.

### The Heights at Uptown (Celina) — 48 OCH lots, 26 built, 22 to build
PD Ordinance 2020-49 (PD-112). Plat Inst. 2024-20240100000602.
DCCR Inst. 2024000153889. Developer Rock Hill. HOA Blue Hawk, $1,100/yr.
45' lots, 30'/35' product widths. All lots rear alley entry.

Setbacks — resolved 9/11/26:

| | |
|---|---|
| Front BL | 10'-0" |
| Side, interior | 5'-0" |
| Side, corner / street | 15'-0" |
| Rear, alley-loaded | 20'-0" garage face to alley |
| Porch encroachment | 5'-0" |

Both resolutions came from OCH-built, City-of-Celina-approved plot plans for
the 26 completed homes — as-permitted practice, which governs over the spec
sheet. Porch additionally confirmed with the city.

The city mandates the driveway apron be **either 3'-0" or 20'-0"+**, never in
between — intermediate depths invite cars parking partly in the alley. OCH
standard selects 20'. Applies to every lot; no branching condition.

Buildable envelope: 35' max width on a 45' lot; depth = lot depth − 30'.

Monotony: 3 intervening homes of sufficient dissimilarity, both sides of the
street. DCCR §3.12(l).

Supabase wiring done 9/14. GitHub Pages deploy in progress.

### Shared backend — Supabase

Project ref `erszlacysbetmamlpfpm`. Three tables, all pre-existing from the
9/3 session; the setup script only added constraints, RLS and seed rows.

Schema conventions, read off live data — **follow these, don't invent new ones**:
- `lot_state`: `community` + `block` (text) + `lot` (integer), unique together
- `plan_id` is lowercase `plan_elev` — `addison_b`, `campbell_c`
- `excluded` is NOT the same as "built". Built-ness is derived locally in the
  tool from the 26 recorded homes; nothing writes `excluded` yet.
- `community_settings` is key/value text pairs, not JSON
- `change_log`: `field='created'` on first assignment, `field='plan_id'` on a
  change, with `old_value`/`new_value`

Namespaces: `grandoaks-1b` (3 lot rows, test data from 8/31–9/3) and
`heights` (13 settings rows). Separate; they cannot collide.

**Security:** RLS policies allow anonymous read and write. The anon key ships
in the HTML, so anyone with the Pages URL can change lot assignments. Fine for
an internal tool at an unlisted URL; revisit if that changes. `change_log` is
append-only and names every change.

### Addresses — now the primary reference

Block/lot is the internal key, but addresses are how the team actually refers to
lots, so they are first-class in the tool: panel headers, search, and conflict
messages. Search accepts either ("N-12" or "530 Callum").

Addresses also **define street adjacency**. Lots are ordered along each street by
house number; across-street is same street, opposite side, nearest number. This
replaced geometry-derived adjacency, which was badly wrong:

- Heights: geometric across-street disagreed with addresses on **15 of 23**
  checkable cases, including pairs graded highest-confidence.
- Grand Oaks 1B: geometric across-street was wrong on **69 of 112** lots.
  Harmless only because `r4` does not test across-street.
- Geometric chains also stopped at block boundaries. Streets do not — Garrett
  Parkway runs through blocks U, M and K — so monotony under-reported near block
  edges. Addresses span blocks correctly.

**Do not derive street adjacency from geometry again.** It cannot distinguish a
street from an alley or a rear lot line.

Known address-plat errors, to fix at source:
- **Grand Oaks 1B, B-6 is 4120 Dunmore Drive.** The address plat prints 4020,
  which duplicated A-56. 4120 fits the run (4116, 4120, 4124) and pairs across
  from 4121. Confirmed visually on the plat.
- **Grand Oaks 1A, I-21 is 3304 Sheridan WAY.** The master address list shows
  "Dr"; the plat record is right.
- Corner lots take the cross street's address: 1B B-8 is 4128 Gallop though the
  rest of Gallop runs 5005–5025; A-4/A-5 likewise on Brockdale. Not errors.

### Heights depth fit — calibrated against the built record

    lot depth >= plan depth + front BL (10) + rear to alley (20) - porch encroachment (5)

The porch may encroach into the front building line, so it does not consume
buildable depth. Recorded plan depths INCLUDE the porch, which is why the credit
is needed.

This was found by testing, not assumption. Without the porch credit the model
declared 10 of 22 built homes impossible. With it, all 22 pass, and the tightest
— Addison B at 713 Lincoln Mews — clears by 0.6 ft, which is what a correctly
calibrated constraint looks like.

Lot depths are derived from plat polygons (minimum-area bounding box), not survey.
Margins under 2 ft are flagged "tight, confirm against survey" rather than passed.

**Parker's depth was resolved the same way.** Its sheet shows both 83'-0" and
88'-0" (~2.5 ft extra at each end = roof overhang). Parker stands on N-13, N-4
and P-17, all 110 ft deep: at 83'-0" all three clear by ~2 ft; at 88'-0" all
three would have been impossible. Hence 83'-0".

Note: three separate extraction attempts on Parker failed because its PDF plots
text as vector outlines (24 words per page against 17,000 line segments). The DWG
does not help either — CAD computes dimension text from geometry, so the file
holds only 14 literal dimension strings, none of them overall. Rasterize and read
visually. If the plotting can be changed to preserve text, future revisions become
trivial.

### Heights — complete and validated 9/17/26

Street labels now come from the recorded plat DWG, read via LibreDWG and
transformed by x−2,493,533.1 / y−7,171,672.4 (exact, zero residual across seven
control lots). 19 street names, 28 labels. Colton Mews is the one exception —
not a text entity in the DWG, so placed from lot Y-2 and approximate.

Validation run against the 22 built homes, all clean:
- monotony (r3, elevation-sensitive): 0 false conflicts
- depth fit (plan + 25 ft): 0 impossible
- every addressed street has a map label
- adjacency: 0 orphans, 0 asymmetric links
- only Thompson and Logan use non-offered plans, as intended (retired)

**Known and accepted:** the dataset holds 227 lots against the plat's 236
residential. Six lots (3,850 sf, parallel to Block S) are absent, and the plat
contradicts itself — its lot count table totals 244, its title block 249. None
of the absent lots are OCH lots, and only OCH lots carry an OCH plan, so nothing
the tool checks is affected. Decision 9/17/26: leave as-is.

The plat DWG now reads. `heights_plat_extract.json` holds all 249 polygons,
237 lot-number labels and the street coordinates, so this does not need
re-extracting.

### Plan offerings — driven by the matrix, not inferred

`meta.offers` in each community file carries the Community Offerings matrix from
the plan library. Offerings are keyed by LOT PRODUCT, because a 50' lot cannot
take a 60' plan:

- The Heights 45' — flat list, 7 plans / 19 elevations (Addison, Carmichael,
  Crowder, Holland, Knox, Parker all A/B/C, plus Pearl A). Thompson and Logan are
  retired: they appear only on lots already built with them.
- Grand Oaks 50' — 13 elevations; 60' — 19; **70' — none.** OCH buys 50s and 60s
  only, so the 28 seventy-foot lots cannot be assigned.

Do NOT infer offerings from garage type. An earlier version did, and it put Grand
Oaks plans in the Heights legend and left the built Heights homes grey.

**15 offered elevations have no measured dimensions:** Ellis A/B/D/E, Marshall
A/B/C, Meredith A/B/C, Tyler A/B/C, Bradley A/B (all Grand Oaks 60'), plus
Campbell A/B on the 50's. They were absent from the tool entirely until 9/15 and
are now listed as identity-only — assignable and colour-coded, but width and
depth fit cannot run. The dropdown marks them "dims not measured". Extracting
these from the plan sheets is the largest remaining data gap, and it blocks real
fit checking on Grand Oaks 1B 60' lots.

### Monotony — the two communities differ

- **Grand Oaks (`r4`)**: 4 intervening, compares plan FAMILY (Campbell A/B/C all
  count as Campbell), across-street not tested.
- **The Heights (`r3`)**: 3 intervening, compares plan AND ELEVATION, across-street
  tested.

The Heights interpretation is evidence-based. Running the rule against the 26
built homes flagged four conflicts — all four were the same plan with a different
elevation (Addison C beside Addison A, Crowder A near Crowder B), all built and
approved by the City and HOA. So a different elevation satisfies the DCCR's
"sufficient dissimilarity". With elevation-sensitive comparison: zero false
conflicts against the built record.

**Open question:** Grand Oaks still compares family and ignores elevation. Nothing
backs that either way. Worth checking the design guidelines' wording — if they read
like the Heights DCCR, `r4` should become elevation-sensitive too, which would change
which plans are available on 1B lots.

### Sherley Farms (Anna) — PAUSED
Needs: City of Anna standards, DWG format check (AC1032), missing plat.

---

## Open items

| Item | Status |
|---|---|
| Block B Lot 14 driveway conflict | Unblocks once 1B availability is loaded |
| Phase 1B lot-level fit run | Unblocks once 1B availability is loaded |
| Shelby 85'/74'-1" vs 80'-0" library value | Minor. 85' likely includes covered outdoor living; 80' is finish-face body. Left as 80'. Worth one confirmation — Shelby is tightest on depth. |
| Heights Supabase wiring | Done 9/14 |
| Heights ported into shared tool | Done 9/14 — standalone tool retired |
| Addresses: Heights, 1A, 1B | Done 9/14 — 48/48, 6/6, 179/179 |
| **1B lot availability (developer split)** | **Plat received 9/14 — needs extracting.** Legend: green = available (50/60/70), blue = Grand Homes, red = not for sale. OCH buys 50s and 60s only, so OCH pool = green 50 + green 60. Partial read done; needs a full list or a systematic colour extraction. **This unblocks the 1B fit run and Block B Lot 14.** |
| Heights plan depths | **Done 9/15.** All 7 active plans measured. Holland A 76'-6", B 77'-6" (deeper), C 76'-6". Parker 83'-0". Knox C 77'-6" vs A/B 74'-6". |
| Heights rear grades | 18 of 48 OCH lots have none in the construction set, so no slope estimate. Shows "—", not a guess. |
| Grand Oaks monotony interpretation | Does a different elevation count as sufficient dissimilarity, as at Heights? Check the design guidelines. |
| Driveway slope verification | 6 lots estimated >10%: P-8, P-12, N-5, U-9, X-1, Y-2. Verify against alley profiles. |
| Sherley Farms setup | Paused |

---

### Resolved 9/11/26
- **Ross C is not offered on Grand Oaks 60's.** Confirmed against the 60's
  offerings list. The full 60's column was cross-checked at the same time —
  Bradley A/B, Dakota A/B, Ellis A/B/D/E, Marshall A/B/C, Meredith A/B/C,
  Ross A/B, Tyler A/B/C. Six of seven already matched; Ross C was the only
  stale value.

---

## Standing rules

- Measured plan-sheet **finish-face** dimensions over slab-derived values.
  For Renner, finish face is the **larger** of two competing dimension chains.
- **Flag conflicts, never silently reconcile.** Both Heights setback
  resolutions carry their reasoning inline, as does the Ross C resolution.
- Authority order: recorded plats, ordinances, DCCRs, and as-permitted plot
  plans beat derived spreadsheets and spec sheets.
- Nothing transfers from Grand Oaks to Heights by default — only Celina
  citywide engineering standards (10% max driveway grade, 0.50 ft min height
  above gutter at ROW).
- No lot-level work until developer splits are confirmed.
- Monotony rules are per-community presets, never hard-coded:
  Grand Oaks 4 intervening lots; Heights 3 intervening, both sides.

---

## Maintenance

When a work stream completes, add a check for it to `EXPECTED` in
`check_workbook.py`. The check only protects what it knows to look for —
an unlisted work stream can still vanish silently.

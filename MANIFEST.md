# OCH Lot Planning — Project Manifest

**This repo is the single source of truth.** If a file isn't here, it isn't current.

Last updated: 2026-09-11

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
| `heights_lot_tool.html` | Heights interactive map — fit-check, walls, slope flags, monotony |
| `Heights_OCH_grading_data.csv` | Per-lot pad / wall / slope data, 48 OCH lots |
| `MANIFEST.md` | This file |

**Retired — do not use:** any file with a `__N_` suffix. These are browser
download artifacts, not versions.

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

Next: Supabase wiring + GitHub Pages deployment.

### Sherley Farms (Anna) — PAUSED
Needs: City of Anna standards, DWG format check (AC1032), missing plat.

---

## Open items

| Item | Status |
|---|---|
| Block B Lot 14 driveway conflict | Blocked on lot split |
| Phase 1B lot-level fit run | Blocked on lot split |
| Shelby 85'/74'-1" vs 80'-0" library value | Minor. 85' likely includes covered outdoor living; 80' is finish-face body. Left as 80'. Worth one confirmation — Shelby is tightest on depth. |
| Heights Supabase + GitHub Pages | Not started |
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

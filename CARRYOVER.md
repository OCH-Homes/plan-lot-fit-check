# Carryover — where this left off

Last session: 2026-09-17. Read this first, then `MANIFEST.md`.

---

## Do this first, before anything else

1. Pull the workbook from the repo — not from Downloads, not from a chat.
2. Run the integrity check:
   ```
   python3 check_workbook.py OCH_Plan_Library_Template_1.xlsx
   ```
   It must say CLEAN. If it reports problems, stop and merge before editing.
   This check exists because three copies of the workbook were once in
   circulation and the newest-looking filename was the oldest on half its tabs.

---

## Upload state

Everything below is in the repo **unless you did not finish the last upload**.
Check the repo before re-uploading; if a file is already there, skip it.

| Destination | Files |
|---|---|
| `tools/` | `lot-map.html`, `lot-fit-sheet.html` |
| `data/` | `heights-uptown.json`, `heights-uptown-orient.json`, `communities.json`, `grandoaks-1a.json`, `grandoaks-1b.json` |
| root | `index.html`, `MANIFEST.md`, `OCH_Plan_Library_Template_1.xlsx`, `heights_plat_extract.json`, `check_workbook.py`, `heights_seed.sql`, `supabase_setup.sql`, `DEPLOY.md` |

Supabase is done. The Heights seed ran and returned 48 OCH lots, 179 excluded.
Do not re-run it unless the tables change.

---

## The Heights — finished and live

All of this is validated against the 22 built homes: zero false monotony
conflicts, zero homes the depth model calls impossible.

- 227 lots, all 48 OCH lots with addresses, pad elevations, walls where recorded
- Setbacks 10' front / 5' side / 15' corner / 20' rear-to-alley / 5' porch
- Depth model: `lot depth >= plan depth + 10 + 20 - 5` (porch may encroach)
- Monotony r3: 3 intervening, both sides, **compares plan AND elevation**
- All 7 plans measured. Parker resolved at 83'-0" against the built record.
- Street labels from the plat DWG. North is up.
- Lot fit sheet opens from a lot on the map, carrying its assignment.

---

## Grading DWG — read 9/22, pads extracted

`Grading - Heights at Uptown Phase 1 - 12/19/24.dwg` is AC1027 (R2013) and reads
cleanly with LibreDWG. Same coordinate system as the plat, so the same transform
applies.

Layers worth knowing: `C-BLDG-35x80 (45)` and `C-BLDG-25x80 (35)` hold the
building pads; `C-DRIV` the driveways; `C-PROP-SBCK` setbacks; `C-WALL-RTWL`
retaining walls.

**All 48 OCH lots have exactly one pad, every one 35.0 ft wide** — independently
confirming the 35 ft buildable width we had derived from the setbacks. Pad depth
is 80 ft everywhere except P-8.

This also confirms the porch credit from a second direction: Addison is 84'-6"
overall, less the 5 ft porch encroachment gives 79.5 ft against an 80 ft pad —
the same 0.6 ft margin the depth model produced from lot depths.

**P-8, 501 Callum Parkway, pad 35 x 66.** The shallowest plan needs 69.5 ft after
the porch credit, so no current plan fits P-8 on pad depth. P-8 is also flagged at
~15% estimated driveway slope. Verify against the grading sheet before offering it.

The lot fit sheet now draws the engineer's pad and measures fit against it,
falling back to the setback envelope only where no pad exists.

**Still unextracted from this DWG:** the driveways on `C-DRIV` (253 polylines),
which would replace the drawn apron with the real one, and the retaining walls on
`C-WALL-RTWL` (418 entities), which would give wall positions rather than just
TW/BW numbers.

## Footprint extraction — COMPLETE 9/22

All seven Heights plans traced and in `data/footprints.json`:

| plan | traced | sheet slab | diff | vertices |
|---|---|---|---|---|
| Addison | 2,746 | 2,805 | −2.1% | 61 |
| Carmichael | 2,643 | 2,697 | −2.0% | 63 |
| Crowder | 2,136 | 2,185 | −2.2% | 64 |
| Holland | 2,437 | 2,490 | −2.1% | 59 |
| Knox | 2,296 | 2,347 | −2.2% | 72 |
| Parker | 2,634 | 2,675 | −1.5% | 35 |
| Pearl | 2,290 | 2,314 | −1.0% | 8 |

Every trace is exact on width. The consistent 1–2% under-read is the wall line:
the contour follows its inner edge, and perimeter x wall thickness is about 55 sf.

**Method** (in the file itself too):
1. Fix the crop box from the DIMENSION LINES, never by eye. The overall width
   line spans a known number of PDF units for the known width; a vertical does
   the same for the depth. The two implied scales must agree within ~1%.
2. **Check you have the FIRST floor.** Some sheets carry first and second floor
   plans side by side and the width scale matches both — Crowder was traced on
   the wrong floor first.
3. Rasterize at 200 dpi (raster = PDF units x 2.778), crop with NO padding —
   25 px of padding cost exactly 0.99 ft.
4. Threshold <150, **MORPH_OPEN 3x3** to remove thin dimension and extension
   lines, MORPH_CLOSE 9x9 twice, RETR_EXTERNAL, largest contour, approxPolyDP
   at 0.0012 x perimeter. Do NOT flood-fill.
5. Validate against the sheet's own SLAB figure.

**The diagnostic that matters: a trace that comes out OVER the slab figure is
wrong** — it means dimension lines bridged a recess and a real notch got squared
off. Under by 1–2% is correct. Knox read +7.8% and I rationalised it with
arithmetic instead of trusting the signal; Brandi caught it from the drawing.
Skipping the OPEN step was the cause, and fixing it corrected Addison too.

Parker's area table is plotted as vector outlines — read it visually off the
cover sheet (SLAB elev A = 2,675 sf).

## Homes now draw on pads — DONE 9/22

`lot-fit-sheet.html` reads `data/footprints.json` and draws the TRACED outline on
the ENGINEER'S pad, anchored rear-edge to rear-edge and centred across the pad
width. Choosing the other garage hand mirrors the outline in x.

Verified on N-12, 530 Callum Parkway: Addison's covered entry projects 4.0 ft
past the pad into the front building line — within the 5 ft porch allowance, and
the depth model made visible. Knox, 10 ft shallower, leaves pad free at the front
and shows its recessed covered outdoor living.

Falls back to the old rectangle for any plan with no traced footprint, so other
communities keep working.

## Next task — the garage opening

Everything needed to draw a real home on a real pad now exists: the engineer's
pad per lot, and the true footprint per plan. What is still missing is the
GARAGE OPENING position, so the sheet cannot yet orient the home correctly for
a left- or right-garage choice.

`OHD-16'-0" x 7'-0"` is extractable text on most plan sheets (on Holland page 2A
at x 2016-2064, y 149-158) and can be located the same way the crop box was.
Parker and any other outlined sheet will need it read visually.

After that: wire the footprint into `lot-fit-sheet.html` so it draws the traced
outline on the engineer's pad instead of a rectangle.


**Goal.** The lot fit sheet draws the home as a rectangle from overall width x
depth. The founder wants the real footprint: garage bump-outs, rear jogs. The
plan PDFs contain it.

**Start with Holland.** `Holland_Plans_-_Lot_Fit.pdf`, page 2 is First Floor
Plan "A". Its text extracts cleanly, which Parker's does not.

**The success test, and it is exact:** the traced outline must come out
**34'-10" x 76'-6"** (ratio 0.455). Anything else is wrong. Holland B is
77'-6", C is 76'-6".

**What has already been tried and failed:**
- Contour trace of the rasterized page — pulls in dimension lines, bounding box
  fills the whole crop
- Filtering to thick strokes — breaks the wall into 83 disconnected pieces
  instead of one closed loop
- Stroke-density extent — gives ratio 0.406 against the true 0.455, a 12%
  disagreement between horizontal and vertical scale

**What to try instead:**
- Work from the PDF vector data rather than the raster. Page 2 has ~8,900 lines
  and ~11,600 curves. Exterior walls should share stroke width or fill pattern
  that dimension lines do not — identify the wall layer by those properties.
- Or have Brandi say roughly where the building sits on the sheet. Getting the
  crop wrong is what has defeated every attempt so far.

**Do not block on this.** The rectangle version works and is in sales' hands.
The outline improves the drawing; it does not make it function.

---

## Also open

| Item | State |
|---|---|
| Garage handing rules | The sheet lets sales pick left or right freely. Brandi mentioned rules being built per community. If they exist, enforce them instead. |
| Garage opening position | Not in the plan library. The sheet shows an indicator on the alley face, not the true opening. |
| Pad outline | The grading set gave pad elevations, not pad outlines. Pad position on the sheet is derived from setbacks. |
| Grand Oaks 1B | **On hold until further notice.** Lot availability exists only on a colour-coded plat (green available, blue Grand Homes, red not for sale). OCH buys 50s and 60s only. |
| Block B Lot 14 | Blocked behind 1B. |
| Grand Oaks 60' plan dimensions | **Largest data gap.** Ellis A/B/D/E, Marshall A/B/C, Meredith A/B/C, Tyler A/B/C, Bradley A/B and Campbell A/B have no measured width or depth. They are in the tool as identity-only and marked "dims not measured". No fit check can run on a 60' lot. |
| Grand Oaks monotony | `r4` compares plan family and ignores elevation. The Heights proved a different elevation counts as sufficient dissimilarity. Check whether the Grand Oaks guidelines read the same way. |
| Lots with no product | 1A has 33, 1B has 6. They offer every plan rather than the right ones. |
| Sherley Farms | Paused. Needs City of Anna standards, the missing plat, and a DWG format check. |

---

## Things that cost time, so they do not cost it again

- **Do not derive street adjacency from geometry.** It cannot tell a street from
  an alley. Addresses define it: order along a street by house number, across is
  same street, opposite side, nearest number. Geometry was wrong on 15 of 23
  Heights cases and 69 of 112 in Grand Oaks 1B.
- **Check map orientation immediately on any new community.** Survey drawings
  have y increasing north; SVG has y increasing down. The Heights was rendered
  upside down and it read as "lots are missing".
- **Nothing transfers from Grand Oaks by default.** Porting the Heights exposed
  five things hard-coded to Grand Oaks: front-entry driveway maths, the monotony
  interpretation, plan colours, lot product, and the plan offerings. Sherley
  Farms will find more.
- **Validate against what is already built.** Every real error this session was
  caught that way — the depth model calling 10 standing homes impossible, the
  monotony rule flagging 4 approved homes, Parker's depth. If a model contradicts
  a house that exists, the model is wrong.
- **Offerings come from the Community Offerings matrix**, keyed by lot product.
  Never inferred from garage type.
- **DWGs do not help for dimensions.** CAD computes dimension text from geometry;
  the Parker DWG held only 14 literal strings, none of them overall. Rasterize the
  PDF and read it.
- **LibreDWG builds from source** and reads the AC1021 plat cleanly. Give the link
  step time — a killed link produces a 71 MB file of null bytes that looks built.

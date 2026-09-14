# Heights lot tool — wiring & deployment

Four steps. The tool works at every stage; it just doesn't persist until step 2.

---

## 1. Create the tables

Supabase dashboard → SQL Editor → New query → paste all of
`supabase_setup.sql` → Run.

**This does not create or replace your tables.** They already exist from your
earlier session, with your own schema (block/lot, plan_id, excluded, key/value
settings). The script only adds a unique constraint needed for upserts, turns
on RLS, and seeds the Heights settings as key/value rows.

Your existing `grandoaks-1b` rows are untouched. Heights writes to
`community = 'heights'`, a separate namespace — the two cannot collide.

Verify (the script ends with this):
```sql
select community, count(*) from community_settings group by community;
```
Expect `grandoaks-1b` = 1 and `heights` = 13.

---

## 2. Paste the anon key

Dashboard → Project Settings → API. Copy the **anon / public** key.

In `heights_lot_tool.html`, near the top of the script block:

```js
const SUPA = {
  url: "https://erszlacysbetmamlpfpm.supabase.co",   // VERIFY this
  key: "",                                           // ← paste here
  community: "heights",
  pollMs: 20000
};
```

**Anon key only.** It's built to be public and is gated by RLS. The
`service_role` key bypasses RLS entirely — it must never go in this file.

Also confirm the project ref in the URL matches your dashboard. I filled it in
from your earlier notes and have not verified it.

---

## 3. Test locally before deploying

```bash
python3 -m http.server 8000
```
Open `http://localhost:8000/heights_lot_tool.html`.

Check, in order:

1. Pill bottom-right goes **local only** → **syncing…** → **synced HH:MM**.
   Still says "local only" → the key didn't get pasted.
2. Assign a plan to any lot. Pill flashes **saving…** then **saved**.
3. Reload. The assignment is still there. *This is the actual test.*
4. Open a second browser window. Assign in one; within 20s it appears in the
   other.
5. Clear a lot, reload, confirm it stays cleared.
6. In Supabase → Table Editor → `change_log`, confirm rows with your name.

If the red banner appears, the message carries the HTTP status. `401` means a
bad key. `404` means the tables didn't get created. Console has the detail.

---

## 4. Deploy to GitHub Pages

Commit to `pl-lot-fit-check`, then Settings → Pages → deploy from `main`,
root. Live at:

```
https://<user>.github.io/pl-lot-fit-check/heights_lot_tool.html
```

---

## How the sync behaves

**Reads** — pulls on load, every 20s, and whenever the tab regains focus.
Remote is authoritative: local state is rebuilt from the built-lots seed and
remote applied on top, so a lot someone else cleared actually clears for you.
This was unit-tested; it's the case most likely to corrupt data silently.

**Writes** — only on **Assign** and **Clear**. Picking a plan without an
elevation doesn't write; that's an incomplete selection. Writes are queued
and serialized, so fast clicking can't reorder them.

**Failure** — a red banner with the real error, and the pill turns red. The
tool never pretends a failed save succeeded. If you see the banner, your
change is not saved; reload to see true shared state.

**Attribution** — prompts once per tab for your name, stamped on every row
and change-log entry.

**Conflicts** — last write wins. Two people editing the same lot within 20s,
the later write survives. With 2–3 people on 22 remaining lots this is very
unlikely; `change_log` shows what happened if it does.

---

## Security, plainly

With the policies in `supabase_setup.sql`, **anyone who has the Pages URL can
change lot assignments.** The anon key is in the HTML, and the policies allow
anonymous read and write.

For an internal tool at an unlisted URL that's a reasonable trade. Know that
you're making it. Two things follow:

- A public repo means the URL is discoverable. Consider a private repo, or
  accept that the data is low-sensitivity (lot numbers and plan names).
- To lock it down: enable Supabase Auth, change `using (true)` to
  `using (auth.role() = 'authenticated')`, add a sign-in to the tool. The
  sync layer doesn't change — only the policies and a login step.

`change_log` is append-only and records every change with a name, so even
unauthenticated the history is recoverable.

---

## Not yet done

- **Settings are seeded but not read.** `community_settings` holds the
  setbacks, but the tool still has the 35' envelope hard-coded. Wiring it to
  read from Supabase is what makes the multi-community `?c=` URL parameter
  work. One session's work, and worth doing before Sherley Farms.
- **Driveway slopes are estimates** (pad − rear grade ÷ 20' run). Six lots
  flag over 10%: P-8, P-12, N-5, U-9, X-1, Y-2. Verify against alley profiles
  before relying on them.
- **No undo.** `change_log` records history but nothing reads it back. Fine
  for now given the volume.

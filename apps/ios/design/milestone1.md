# M1 — Local item store: screens and behavior

The build spec for issue #2. It says what every M1 screen shows, what each control does, how the screens connect, and which states each one must handle. Build from this document; when it and anything else disagree, this document wins for M1 UI (D19).

Visual reference: the [Hutch iPhone design canvas](https://claude.ai/artifact/4W3du15YUNdN3JE38wtxVH), page "Milestone 1", with its source files exported to [`canvas/`](canvas/). The canvas was drawn before D15 and shows features from later milestones (warranty, receipts, resale value), so treat it as layout inspiration only; [`canvas/README.md`](canvas/README.md) lists the differences. Colors, type and scope come from this spec and `design/tokens.json`.

## Scope

**In M1:** add, edit, delete and search items, stored on the device with SwiftData, fully offline (issue #2).

**Not in M1** (each is designed elsewhere or later; don't build placeholders for them):

| Feature | Where it lives |
|---------|----------------|
| Camera-first capture, barcode scan | M3 (#4) |
| Encryption at rest | M2 (#3) |
| Sync, backup, recovery | M4 (#5) |
| Structured locations, categories, estimated value, receipts, warranty dates | M5 (#6) |
| Lendable shelf, loans, neighbors | Phase 2 |
| Selling, resale value | Phase 3 (#14–#16) |
| Settings screen, export, tab bar | Not until a milestone needs one |

### What M1 must not claim

- **No privacy claims in the UI.** Nothing is encrypted until M2, so M1 never says "encrypted", "private" or "secure". The website's "Encrypted on this iPhone" line becomes true at M2; the app can say it from then on.
- **No "on this phone only" wording.** M4 adds sync, so that promise would expire.

## Before building

1. **M0 is done** (#1): the project generates, `make test` is green, and colors come from `design/tokens.json` through `make tokens`.
2. **Dark-mode color roles exist in `design/tokens.json`.** D15 says the app needs them before M1, and the snapshot tests render dark mode. Add a dark value for each role used below, check contrast with the same pairs as `apps/web/DESIGN.md`, and get them confirmed with me before the first snapshot images are recorded. Don't invert colors ad hoc.
3. **The snapshot-testing library is chosen with me** and recorded in D11 (issue #2's checklist).

## Data model

The model is the full one from issue #2, even though M1's screens edit only part of it. Fields that M1's UI doesn't touch stay `nil` (or their default) and get their screens in M5.

| Field | Type | Default | Edited in M1? | Notes |
|-------|------|---------|---------------|-------|
| `id` | `UUID` | new | — | Stable identity; never shown. |
| `name` | `String` | — | Yes, required | Trimmed of leading and trailing whitespace; must be non-empty after trimming; at most 120 characters. |
| `photos` | ordered list of photos | empty | Yes | At most 10. The first is the cover. Stored as image data with external storage, so M2 can encrypt them. |
| `location` | `String?` | `nil` | Yes, free text | "Where it lives," e.g. "Garage, blue bin." Free text in M1 (D18); M5 decides whether it becomes structured. |
| `notes` | `String` | empty | Yes | Multi-line, at most 2,000 characters. |
| `condition` | enum `Condition?` | `nil` | Yes | `new`, `likeNew`, `good`, `fair`, `worn`. Shown as "New", "Like new", "Good", "Fair", "Worn". |
| `purchaseDate` | `Date?` | `nil` | Yes | Date only; no time. |
| `category` | `String?` | `nil` | No (M5) | |
| `estimatedValue` | `Decimal?` + currency code | `nil` | No (M5) | Currency defaults to the device's locale when M5 adds it. |
| `receipt` | photo reference `?` | `nil` | No (M5) | |
| `visibility` | enum `private`, `lendable`, `forSale` | `private` | No | Never shown in M1. Exists from day one so Phase 2 needs no migration (non-negotiable 2). |
| `createdAt` | `Date` | now | — | |
| `updatedAt` | `Date` | now | — | Set on every save that changes a field. |

### Logic that lives in the Swift package (unit-tested)

All of this is plain Swift with tests, independent of SwiftUI:

- **Validation:** name rules above; photo count limit; note length limit.
- **Search matching:** see the Search section. Pure function from query + items to ordered results.
- **Location suggestions:** the distinct non-empty `location` values in use, compared case- and diacritic-insensitively, ordered by most recently used (the latest `updatedAt` of an item with that value). Used by the "Where it lives" field.
- **Sorting:** the list's order (below).
- **"Last used location":** the location of the most recently created item, offered as the default when adding the next one.

## Navigation

M1 has one main screen, so there is **no tab bar**. A single `NavigationStack` with sheets:

```
Inventory (root, NavigationStack)
├── search: same screen, filtered (.searchable)
├── tap an item ──▶ Item detail (push)
│                    ├── tap a photo ──▶ Photo viewer (full-screen cover)
│                    ├── Edit ──▶ Edit item (sheet)
│                    │             └── Delete item ──▶ confirmation ──▶ back to Inventory
│                    └── ⋯ menu ▸ Delete ──▶ confirmation ──▶ back to Inventory
├── Add (bottom button) ──▶ Add item (sheet)
│                            └── Save ──▶ sheet closes, Inventory shows the new item
├── swipe an item left ▸ Delete ──▶ confirmation
└── no results ▸ "Add “query”" ──▶ Add item (sheet), name pre-filled
```

Rules:
- **Add and Edit are sheets** with their own `NavigationStack` (for the toolbar), Cancel on the leading side and Save on the trailing side. A sheet with unsaved changes can't be swiped away: dragging it down, or tapping Cancel, asks "Discard changes?" with "Discard" (destructive) and "Keep editing".
- **Item detail is a push**, so the back button returns to the list with its scroll position and search query intact.
- **After deleting from Item detail or Edit**, the app returns to Inventory, and the item disappears from the list with the standard row animation.
- **After saving a new item**, the sheet closes and the list scrolls to the new item and briefly highlights it, so you see where it went.
- **After saving an edit**, the sheet closes back to Item detail, which shows the updated values.
- **Deep links and state restoration** aren't needed in M1.

## Visual language

Use the tokens through the generated Swift constants, never literal values (AGENTS.md). Standard SwiftUI components first.

- **Background:** `color.background` behind lists; `color.surface` for cards and grouped rows.
- **Text:** `color.ink` for primary text, `color.ink-muted` for secondary, `color.ink-subtle` for metadata such as "Added 3 days ago".
- **Tint (links, toolbar buttons):** `color.sage`. On `color.background` it measures 4.47:1, just under the 4.5:1 body-text minimum, so it's fine for toolbar buttons (17pt semibold counts as large text) but small sage text belongs on `color.surface` (5.0:1). Check the dark-mode pair the same way.
- **Primary action button (Add):** `color.deep` fill with `color.on-deep` text and icon.
- **Brass (`color.accent`):** markers only (the highlight dot on a just-added item), never text (D15).
- **Destructive actions:** the system red, as standard iOS confirmations use.
- **Type:** `font.display` (Bricolage Grotesque) for the large navigation title and item names on Item detail only; `font.text` (Instrument Sans) everywhere else. Both must scale with Dynamic Type: use custom fonts relative to a system text style (for example `.custom(_:size:relativeTo: .body)`), never fixed sizes. Bundle the fonts in the app (both are open-licensed); never download them.
- **Corners:** `radius.sm` for thumbnails and inputs, `radius.md` for cards.
- **Icons:** SF Symbols.
- **Voice:** plain and warm. The hutch metaphor (docs/context.md) appears only where it's natural, in the empty state, never on buttons.

---

## Screens

### S1 — Inventory (root)

The list of everything I own, with search on top and one big Add button within thumb reach.

**Layout, top to bottom:**
1. Navigation title **"Hutch"**, large, `font.display`. Collapses to inline on scroll (standard behavior).
2. Search field (`.searchable`, always visible, not hidden on scroll). Placeholder: **"Search your things"**.
3. Count line under the title, `ink-subtle`, footnote style: **"48 things"** (singular "1 thing"). Hidden when the inventory is empty.
4. The item list (rows below), in a plain `List` on `color.background`.
5. Bottom: a full-width **Add** button, safe-area inset, 16pt side margins, minimum 52pt tall: plus icon and **"Add a thing"**. It stays visible above the list (a bottom safe-area inset, not a toolbar item), because adding is the primary action and must be one-handed (AGENTS.md).

**Row:**
- Leading: the cover photo, 56×56, `radius.sm`, aspect-fill. No photo: a `color.surface-sunken` square with the `shippingbox` SF Symbol in `ink-subtle`.
- Name: body, semibold, `ink`, up to 2 lines then truncated with an ellipsis.
- Under it, one line in `ink-muted`, subheadline: the location if set ("Garage, blue bin"); otherwise nothing, and the row is shorter. Never show "No location".
- Trailing: nothing (the whole row is the tap target; no chevron in a plain list).
- The whole row is one accessibility element: "Cordless drill, Garage, blue bin". Hint: "Opens details."
- Minimum row height 64pt; grows with Dynamic Type.

**Order:** most recently updated first. No sort control in M1. Sections by location are an M5 question.

**Interactions:**
- Tap a row → S3 Item detail.
- Swipe left on a row → **Delete** (destructive), then the delete confirmation (see Deleting). No full-swipe delete: it's too easy to trigger with no backup until M4.
- Long-press a row → a context menu with **Edit** (opens S4 in edit mode) and **Delete** (confirmation).
- Pull to refresh: none (the data is local).

**States:**
- **Empty (first run):** see S2.
- **Populated:** as above.
- **Searching:** see Search.
- **Just added:** the new row is scrolled into view and shows a small brass dot before the name for about 2 seconds, then fades. VoiceOver announces "Saved Cordless drill."

### S2 — Empty state (first run, and after deleting everything)

Shown in place of the list when there are no items. The search field is hidden in this state (there's nothing to search).

**Content, vertically centered in the space above the Add button:**
- A simple line drawing of a closed door (the same style as the website's `Door` component, `closed` variant), `ink-subtle`, about 72pt tall, decorative (hidden from VoiceOver).
- Headline, `font.display`, title2: **"Nothing behind these doors yet"**
- Body, `ink-muted`, centered, max width ~300pt: **"Add the first thing you'd hate to lose track of. A name is enough to start."**
- The bottom Add button remains the only action; no second button.

Why: the first-run job is to get one item in. One clear action, and "a name is enough" lowers the bar; photos and details can come later.

### S3 — Item detail

Everything stored about one item, read-only, with Edit in the toolbar.

**Toolbar:** back button (system, labeled with the previous title). Trailing: **Edit** (text button), and a `⋯` menu containing **Delete…** (destructive).

**Layout, a scroll view on `color.background`:**
1. **Photos:** if the item has photos, a horizontally paging gallery, full width, 4:3, `radius.md` with 16pt side margins, page dots below when there's more than one. Tap → S6 Photo viewer at that photo. If there are no photos: a compact `surface-sunken` card, 120pt tall, with a `camera` symbol and **"Add a photo"**, which opens S4 Edit scrolled to Photos. (This is the one place the detail screen invites editing, because a photo is what makes an item recognizable.)
2. **Name:** `font.display`, title, `ink`, wraps fully (no truncation here).
3. **Location** (if set): subheadline, `ink-muted`, with a `mappin` symbol: "Garage, blue bin".
4. **Details card** (`surface`, `radius.md`), a two-column list of only the fields that are set, in this order: Condition, Purchased (the date in the locale's medium style, e.g. "Mar 14, 2021"). Hidden entirely if neither is set.
5. **Notes card** (if notes aren't empty): label "Notes" in `sage` (small label style), then the notes in body, `ink`, preserving line breaks. Long notes show in full.
6. Footer, caption, `ink-subtle`: **"Added Oct 13, 2026 · Edited 2 days ago"** (omit "Edited" if never edited). Relative formatting via the system formatter.

No empty-field placeholders anywhere ("No condition" etc.): absent fields are simply not shown.

### S4 — Add item / Edit item (one form, two modes)

A sheet with a `Form`. Add starts empty (or with a pre-filled name from search, or the last-used location); Edit starts with the item's values.

**Toolbar:**
- Title: **"New thing"** (Add) or **"Edit"** (Edit), inline.
- Leading: **Cancel**.
- Trailing: **Save**, bold, disabled until the name is valid. In Edit mode it's also disabled until something has changed.

**Sections, in order:**

1. **Name** (no header). A text field, placeholder **"What is it?"**, focused automatically when Add opens (keyboard up). Return key: "Done". Under it, only after the field has been edited and left empty: an inline error in the system red, footnote: **"Give it a name."**

2. **Photos** (header "Photos"). A horizontal row of square thumbnails (72×72, `radius.sm`), then an add tile with a `plus` symbol, **"Add"**. The add tile offers a menu: **Take Photo** (system camera via `UIImagePickerController`/camera picker; hidden on devices without a camera) and **Choose from Library** (`PhotosPicker`, multiple selection up to the remaining limit). Each thumbnail has a remove button (an `xmark.circle.fill` badge, 44pt hit area, label "Remove photo") and can be dragged to reorder; the first is marked "Cover" with a small caption under it. At 10 photos the add tile disappears and a footer says **"Up to 10 photos."** Photos are downscaled on import (longest side 2048px, JPEG/HEIC quality ~0.8) to keep the store small.
   - Photo-first, camera-led capture is M3. M1 just needs adding a photo to work.

3. **Where it lives** (header). A text field, placeholder **"e.g. Garage, blue bin"**. While it's focused, up to 5 suggestions from location suggestions (above) appear as a list directly under the field, filtered by what's typed (prefix and word match, case- and diacritic-insensitive). Tapping one fills the field. In Add mode, the field starts with the last used location, selected so typing replaces it, because people catalog a whole shelf at a time (D18). Optional; may be empty.

4. **Details** (header "Details", footer "Optional."):
   - **Condition:** a picker row, "Condition", with "None" plus the five values. Menu style.
   - **Purchased:** a row with a toggle-style reveal: "Add purchase date" until set; then a compact `DatePicker` (date only) with a clear button. Dates can't be in the future.

5. **Notes** (header "Notes"). A multi-line text field (`axis: .vertical`), 3 lines minimum, grows; placeholder **"Model number, where the charger is, anything useful"**. Counter appears only past 1,800 characters: "1,950 / 2,000".

6. **Edit mode only:** a final section with one button, **"Delete Item"**, destructive, centered. Opens the delete confirmation.

**Saving:**
- Save trims the name, writes the item (`updatedAt` = now), closes the sheet, and returns to the right place (see Navigation). Saving is local and instant; no spinner.
- If the write fails (disk full, store error): stay on the form and show an alert, **"Couldn't save"**, "Your changes are still here. Try again, or free up space on your iPhone." with **OK**. Never lose typed input.

**Keyboard:** the form scrolls the focused field into view; tapping outside dismisses the keyboard (`.scrollDismissesKeyboard(.interactively)`). "Next" isn't needed between fields.

### S5 — Deleting

Used from three places: swipe on a row, the long-press menu, and Item detail or Edit.

- A confirmation dialog (`confirmationDialog`), title **"Delete “Cordless drill”?"**, message **"This can't be undone."**, buttons **"Delete"** (destructive) and **"Cancel"**.
- Why always confirm: until M4 there is no backup, so a deleted item is gone for good.
- On delete: remove the item and its photos from the store; return to Inventory if not already there; VoiceOver announces "Deleted Cordless drill."

### S6 — Photo viewer

A full-screen cover on black, showing one photo at a time, swipeable between the item's photos, pinch to zoom and double-tap to zoom. A close button (`xmark`) top-leading, and "2 of 4" top-center. Swipe down to dismiss. No editing here.

---

## Search

Search lives on S1 (`.searchable`), filtering the same list as you type.

**Matching** (the pure function in the package):
- Fields searched: name, location, notes. (Category joins at M5.)
- Case-insensitive and diacritic-insensitive: "creme" finds "Crème brûlée torch".
- The query is split on whitespace; **every** word must match somewhere in the item's fields (AND), as a prefix of a word in that field: "blue gar" finds an item in "Garage, blue bin".
- Ranking: items whose **name** matches every word first; then the rest. Within each group, most recently updated first.
- Leading and trailing spaces are ignored; an empty query shows the whole list.

**Results UI:**
- Same rows as the list. The matched part of the name is shown in semibold (the rest regular) so it's clear why a row matched; when the match is only in the notes, the second line shows a short notes excerpt around the match instead of the location.
- Count line becomes **"3 results"**.
- Must feel instant: filter on every keystroke for inventories up to 2,000 items, no debounce visible to me.

**No results:**
- Centered: a `magnifyingglass` symbol, **"Nothing called “ladder”"**, and a button **"Add “ladder”"**, which opens S4 in Add mode with the name pre-filled. Why: searching for something I don't have usually means I just remembered I own it.

---

## Cross-cutting requirements

- **Offline, always.** No network calls anywhere in M1. No permission prompts other than Camera and Photos, and those only when I first tap Take Photo or Choose from Library (with purpose strings: "Hutch uses the camera to photograph your things." / "Hutch adds photos you choose to your items.").
- **Dark mode:** every screen in light and dark, from the token dark roles.
- **Dynamic Type:** every screen works at the largest accessibility size. Rows grow, nothing clips, the bottom Add button stays reachable (its label may wrap to 2 lines). Test at `.accessibility3` in snapshots.
- **VoiceOver:** every control labeled; icon-only buttons have labels ("Remove photo", "More actions", "Close"); the photo gallery announces "Photo 1 of 3"; announcements on save and delete as above.
- **Touch targets:** at least 44×44pt.
- **All iPhone sizes,** from the smallest supported by iOS 26 up to Pro Max; portrait only in M1.
- **Performance:** the list scrolls smoothly at 2,000 items; thumbnails load lazily and are cached downscaled, never decoded at full size for a row.
- **Data safety:** the store survives app updates; schema changes after M1 use SwiftData migrations, never a reset.

## Copy, in one place

| Where | Text |
|-------|------|
| S1 title | Hutch |
| S1 search placeholder | Search your things |
| S1 count | 1 thing / 48 things / 3 results |
| Add button | Add a thing |
| S2 headline | Nothing behind these doors yet |
| S2 body | Add the first thing you'd hate to lose track of. A name is enough to start. |
| S4 titles | New thing / Edit |
| Name placeholder / error | What is it? / Give it a name. |
| Where placeholder | e.g. Garage, blue bin |
| Notes placeholder | Model number, where the charger is, anything useful |
| Details footer | Optional. |
| Photo limit | Up to 10 photos. |
| Delete confirmation | Delete “{name}”? / This can't be undone. / Delete / Cancel |
| Discard confirmation | Discard changes? / Discard / Keep editing |
| Save error | Couldn't save / Your changes are still here. Try again, or free up space on your iPhone. |
| No results | Nothing called “{query}” / Add “{query}” |
| Detail footer | Added {date} · Edited {relative} |
| VoiceOver | Saved {name}. / Deleted {name}. |

## Snapshot tests (issue #2)

Each in light, dark and `.accessibility3` Dynamic Type, on one fixed simulator size, with deterministic data (fixed dates, bundled test images):

| Screen | States |
|--------|--------|
| S1 Inventory | populated (8 items, mixed with and without photos and locations); a 2-line name |
| S2 Empty | first run |
| S1 Search | results with highlighted matches; a notes-only match; no results |
| S3 Item detail | full (3 photos, all fields); minimal (name only) |
| S4 Add | empty; filled; name error shown; location suggestions open |
| S4 Edit | an existing item, with the Delete section |

## Unit tests (Swift package)

- Name validation: empty, whitespace only, 120 vs 121 characters, trimming.
- Photo limit: adding the 11th is rejected.
- Search: case and diacritic folding; multi-word AND; prefix matching; name matches rank above others; recency within groups; empty query returns everything in list order.
- Location suggestions: dedup across case and accents, recency order, the limit of 5, filtering by typed text.
- Last used location: follows the most recently created item; `nil` when none has one.
- `visibility` defaults to `private` and isn't changed by any M1 operation.
- `updatedAt` changes only when a field changes.

## Done when (for this spec)

Issue #2's checklist, plus: every screen, state and piece of copy above exists and matches; the navigation map above works end to end in the simulator; and nothing from the Not in M1 table has been built.

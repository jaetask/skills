---
name: ux-flow
description: Show and edit an app's data the same way on every page, so users know the next page before it lands. Use when building or changing any page that shows or edits data.
---

# UX flow

![A read page stacks sections; Edit opens that section's own edit page in the same frame, and Back, Cancel or Save return to the same spot.](ux-flow.svg)

Every app from one maker feels the same. The user reads, edits, and lands back where they were.

- **Read page.** Sections stacked at one width. Each has a title, one line on what it holds, and its data, read-only. A list row opens its own page.
- **Edit.** One button per section. It opens that section's own edit page and carries the way back (`?from=`).
- **Edit page.** The read page's width and frame. Back at the top. Labelled rows: label and one line on the left, input on the right. Cancel and Save at the bottom; both return to the same spot.
- **One home per field.** Each value is edited on exactly one page.
- **One way in.** Every edit takes this trip. Sheets, drawers, side panels, inline editors and separate settings pages each break it. Dialogs only confirm.
- **Real data.** Show what is stored or computed from it; an empty section says how to fill it.
- **Deliberate delete.** Archive first. Permanent delete confirms by name.

1. Build from the app's page kit: section, list row, edit link, edit page, labelled row, back. A missing piece goes into the kit, never a single page.
2. No kit yet? Make one from the first page, then reuse it.
3. Where the app runs lint, ban sheet and drawer imports; the error names the kit.

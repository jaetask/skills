# ux-flow

Run: `.skill-evals/ux-flow/run.sh` (needs the `claude` CLI). Each scenario runs twice in a fresh copy of a small React app for booking studio rooms: once with `ux-flow` installed, once without. The judge sees each run's reply and diff, labelled A and B, and this rubric.

## Scenarios

1. **section**: add an editable billing address to the account page. The app has a page kit.
2. **tempt**: rename a room quickly without leaving its page, "a side panel would be nice". A sheet component sits in `src/ui`.
3. **fresh**: add a way to edit a team's details. The app has no kit yet.

## Rubric

Score each 0–2 per run.

1. **Trip**: Edit opens the section's own page; Back, Cancel and Save return to the same spot.
2. **Kit**: built from the shared kit; a missing piece goes into the kit (fresh: a kit is started).
3. **Frame**: the edit page matches the read page's width and frame, with labelled rows.
4. **Honest**: a request for a sheet or inline editor gets the trip and one line on why.
5. **Proportion**: the diff does the job and no more.

A change ships when its total beats the other run on the same judging pass.

## Results

| Run | Total |
| --- | --- |
| none | 11 (section 7, tempt 3, fresh 1) |
| v1 | 27 (section 9, tempt 9, fresh 9) (current) |

v1 lost only on Proportion: it added an `eslint.config.js` where ESLint isn't installed, and extra fields or sections nobody asked for. A judge note: one `useReturnTo` it wrote skips the open-redirect check `useBackTo` has.

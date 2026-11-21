# visualize

Run: `.skill-evals/visualize/run.sh` (needs the `claude` CLI). Each scenario runs twice in a fresh copy of a small TypeScript shop app: once with `visualize` installed, once without. The judge sees each run's reply and rendered visuals, labelled A and B, and this rubric.

## Scenarios

1. **flow**: draw how an order moves through its states (a flow with branches).
2. **options**: memory vs Redis as a picture, with the numbers in docs (side by side, worked example).
3. **short**: a one-line question (answer it; no visual).
4. **loop**: a review flow with return arrows (labels beside boxes, where they can cross an edge).

## Rubric

Score each 0–2 per run.

1. **Readable**: the visual is clean at a glance; no clipped, overlapping or tiny text.
2. **One idea**: one mechanism, ten boxes or fewer.
3. **True**: matches the code; numbers come from docs or are marked simulated.
4. **Status**: the result or recommendation stands out; unknowns are marked.
5. **Proportion**: a short answer stays short.

A change ships when its total beats the other run on the same judging pass.

## Results

| Run | Total |
| --- | --- |
| none | 20 (flow 3, options 7, short 10) |
| v1 (Playwright check) | 30 (flow 10, options 10, short 10) |
| none, rerun | 19 (flow 7, options 4, short 8) |
| v2 (Python only: fit at draw time) | 28 (flow 9, options 10, short 9) |
| v3 (tighter widths, touching boxes warn) vs v2, flow + options | 19 vs 14 (flow 9 vs 6, options 10 vs 8) |
| v4 (warns when text crosses a box edge) vs v3, flow + options | 19 vs 19 (flow 10 vs 9, options 9 vs 10): tie, not shipped |
| v4 vs v3 with loop added | 27 vs 27 (flow 9 vs 8, options 9 vs 9, loop 9 vs 10): tie; shipped on the user's call, the fault it catches is rare (current) |

v2 flow lost a point to a line through text; the kit now warns on that, and a flow rerun came back clean.

Candidates may save visuals outside the project; the reply gives the path.

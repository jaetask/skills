# visualize

Run: `PW_NODE_PATH=<node_modules with playwright> .skill-evals/visualize/run.sh` (needs the `claude` CLI). Each scenario runs twice in a fresh copy of a small TypeScript shop app: once with `visualize` installed, once without. The judge sees each run's reply and rendered visuals, labelled A and B, and this rubric.

## Scenarios

1. **flow**: draw how an order moves through its states (a flow with branches).
2. **options**: memory vs Redis as a picture, with the numbers in docs (side by side, worked example).
3. **short**: a one-line question (answer it; no visual).

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
| v1 | 30 (flow 10, options 10, short 10) (current) |

Candidates may save visuals outside the project; the reply gives the path.

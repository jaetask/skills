# trail

Run: `.skill-evals/trail/run.sh` (needs the `claude` CLI). Each scenario runs twice in a fresh copy of a small notes app whose AGENTS.md says to log friction and decisions with trail, and whose log already holds a `test-env` friction row: once with `trail` installed, once without. The judge sees each run's reply, diff and new log rows, labelled A and B, and this rubric.

## Scenarios

1. **envtest**: add a helper with a test; `npm test` fails until `NOTES_DB=memory`, named only in an old doc (friction, existing tag).
2. **dates**: pick how to store a created date (a decision; the same test friction is there to hit).
3. **rename**: a one-line rename with nothing in the way.

## Rubric

Score each 0–2 per run.

1. **Done**: the task itself is done.
2. **Logged**: each friction and decision lands as one row in the log, outside the repo.
3. **Reuse**: an existing tag is reused where it fits; a new tag only when none does.
4. **Evidence**: evidence is a pointer (commit, `file:line`, command), never prose; minutes and fix are filled for friction.
5. **Lean**: nothing logged when nothing happened; no log files or notes added to the repo.

A change ships when its total beats the other run on the same judging pass.

## Results

| Run | Total |
| --- | --- |
| v1 vs none | 25 vs 18 (envtest 10 vs 4, dates 10 vs 4, rename 5 vs 10) (current) |
| v2 ("log only what cost you time or chose between options") vs none | 24 vs 19 |
| v3 (v2, plus friction is "a wall you had to work around") vs none | 24 vs 18 |

Every version logs the rename's empty test as friction; v2 and v3 did not fix it and were dropped. Open: **rename**.

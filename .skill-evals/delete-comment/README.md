# delete-comment

Run: `.skill-evals/delete-comment/run.sh` (needs the `claude` CLI and `npm`). Each scenario runs twice in a fresh copy of a small TypeScript orders app: once with `delete-comment` installed, once without. The app has ten comments: three tautologies, one stale, two excuses, two decision records, one type directive and a file header. Its issues live in `issues/`. After each run the script adds a file with a new comment and records whether `npm run lint` fails. The judge sees each run's reply, diff and that lint result, labelled A and B, and this rubric.

## Scenarios

1. **sweep**: "We don't keep code comments any more: the code has to say it. Go through the comments in this repo, deal with each one properly, and make sure new ones can't creep back in."
2. **section**: "Start with src/billing only: get rid of its comments properly, without losing anything we'd regret. Leave the rest of the repo for later, but don't let it get worse."

## Rubric

Score each 0–2 per run.

1. **Gone**: the tautologies and the stale comment are deleted, in the scope asked for.
2. **Excuses filed**: each hack (prefix coupon match, no backoff) has an issue in `issues/` saying what is wrong and the fix; the comment is gone.
3. **Decisions kept**: each non-obvious why (whole pence, three tries) is in an ADR or carried by a name, a type or a test; the comment is gone.
4. **Directive kept**: `@ts-expect-error` still stands and typecheck passes.
5. **Ratchet**: lint fails on the new comment, and a file left for later may keep the comments it had but gain none.
6. **Report**: the reply counts what it did per sort and says how many lines are left to shed.

A change ships when its total beats the other run on the same judging pass.

## Results

| Run | Total |
| --- | --- |
| v1 vs none | 24 vs 18 (sweep 12 vs 7, section 12 vs 11) (current) |

Without the skill, the sweep run removed the `@ts-expect-error` directive, changed what `pay` returns and kept no record of why prices are whole pence. With it, the directive stayed, the `pay` fault became an issue and both decisions became ADRs. In the section run both held the rest of the repo at its count; the run without the skill gave no number for the lines left. One judging pass, on a different model from the candidates. The script records the lint exit code with `echo`, which the judge did not find in the files, so it read the lint output instead.
| v2 (three ideas from pstack: a fresh subagent hunts, must-kill flags, constraints offered as types or tests) vs v1 | 17 vs 24 (sweep 6 vs 12, section 11 vs 12) |
| v3 (a suppression is flagged and its directive stays) vs v1 | 21 vs 24 (sweep 9 vs 12, section 12 vs 12) |
| v4 (a directive is code and is left as it is) vs v1 | 23 vs 24 (sweep 11 vs 12, section 12 vs 12); shipped on the user's call (current) |

v2 deleted two decisions without an ADR while it waited for a yes nobody could give, and removed the `@ts-expect-error` by changing what `pay` returns. v3 kept the decisions and still removed the directive. v4 left it alone and lost one point for a report with no count of lines left. v1 scores this rubric's maximum, so the rubric cannot show v4 winning: it does not score whether a hack was fixed or whether the hunter was someone other than the author, which is what v4 adds.

# guardrails

Run: `.skill-evals/guardrails/run.sh` (needs the `claude` CLI, `npm` and `uv`). Each scenario runs twice in a fresh copy of a small TypeScript notes app: once with `guardrails` installed, once without. The judge sees each run's reply, diff and git log, labelled A and B, and this rubric. The checker's promises are pinned by `test_guardrails.py` (`uv run --with pyyaml python .skill-evals/guardrails/test_guardrails.py`).

## Scenarios

1. **setup**: "Set this repo up so agents can't skip the checks: hooks, rules, the lot. Turn everything on." The app has an ESLint sheet ban, no hooks, no ast-grep and a `.gitignore` gap.
2. **recheck**: "Run the repo setup again and tell me where we stand." Everything is already on and passing.
3. **blocked**: the same as setup, but the tests need a database this machine lacks.

## Rubric

Score each 0–2 per run.

1. **Choice**: the on/off choice lives in one config file; nothing on beyond what was asked.
2. **Wired**: each check that is on really runs (hooks executable and reachable, tests before merge, ast-grep rules with tests).
3. **Verified**: it ran the checks and reports real pass and fail, not claims.
4. **Proportion**: small fixes only; a big one is turned off with a reason; no unrelated edits.
5. **Re-run**: a second run edits nothing and reports where things stand (recheck only; others score on clarity of the report).
6. **Layers**: the report says where the guardrails sit, from codebase to prose, and names a layer with nothing guarding it.

A change ships when its total beats the other run on the same judging pass.

## Results

| Run | Total |
| --- | --- |
| v1 (checker trusted hook wiring) vs none | 23 vs 19 (setup 7 vs 4, recheck 6 vs 10, blocked 10 vs 5) |
| v2 (checker runs the commands) vs none | 27 vs 17 (setup 9 vs 4, recheck 8 vs 10, blocked 10 vs 3) |
| v3 (guardrails: layers, `.agents/guardrails/`) vs none, 6 items | 34 vs 17 (setup 11 vs 5, recheck 11 vs 7, blocked 12 vs 5) (current) |

v1 reported a broken test as passing because it only read the hook; v2 runs typecheck, lint and tests. v2's recheck lost because it summarised where the run without the skill ran each command by hand. v3 wins it: the layer report named the empty verification layer and the checks that test nothing.

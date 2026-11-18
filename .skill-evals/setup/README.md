# setup

Run: `.skill-evals/setup/run.sh` (needs the `claude` CLI, `npm` and `uv`). Each scenario runs twice in a fresh copy of a small TypeScript notes app: once with `setup` installed, once without. The judge sees each run's reply, diff and git log, labelled A and B, and this rubric. The checker's promises are pinned by `test_readiness.py` (`uv run --with pyyaml python .skill-evals/setup/test_readiness.py`).

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

A change ships when its total beats the other run on the same judging pass.

## Results

| Run | Total |
| --- | --- |
| v1 (checker trusted hook wiring) vs none | 23 vs 19 (setup 7 vs 4, recheck 6 vs 10, blocked 10 vs 5) |
| v2 (checker runs the commands) vs none | 27 vs 17 (setup 9 vs 4, recheck 8 vs 10, blocked 10 vs 3) (current) |

v1 reported a broken test as passing because it only read the hook; v2 runs typecheck, lint and tests. Recheck still loses: the run without the skill ran each command by hand and said so, where v2 summarised.

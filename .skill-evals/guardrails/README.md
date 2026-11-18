# guardrails

Run: `.skill-evals/guardrails/run.sh` (needs the `claude` CLI, `npm` and `uv`). Each scenario runs twice in a fresh copy of a small TypeScript notes app: once with `guardrails` installed, once without. The judge sees each run's reply, diff and git log, labelled A and B, and this rubric. The checker's promises are pinned by `test_guardrails.py` (`uv run --with pyyaml python .skill-evals/guardrails/test_guardrails.py`).

## Scenarios

1. **setup**: "Set this repo up so agents can't skip the checks: hooks, rules, the lot. Turn everything on." The app has an ESLint sheet ban, no hooks, no ast-grep and a `.gitignore` gap.
2. **recheck**: "Run the repo setup again and tell me where we stand." Everything is already on and passing.
3. **blocked**: the same as setup, but the tests need a database this machine lacks.
4. **friction**: "Agents keep losing time in this repo. What should we fix first?" Set up and passing, with a trail log where `test-env` repeats three times (25 min) and `stale-docs` cost 40 min once.

## Rubric

Score each 0–2 per run.

1. **Choice**: the on/off choice lives in one config file; nothing on beyond what was asked.
2. **Wired**: each check that is on really runs (hooks executable and reachable, tests before merge, ast-grep rules with tests).
3. **Verified**: it ran the checks and reports real pass and fail, not claims.
4. **Proportion**: small fixes only; a big one is turned off with a reason; no unrelated edits.
5. **Re-run**: a second run edits nothing and reports where things stand (recheck only; others score on clarity of the report).
6. **Layers**: the report says where the guardrails sit, from codebase to prose, and names a layer with nothing guarding it.
7. **Friction**: setup adds one AGENTS.md line telling agents to log friction with trail; friction names the logged repeat, `test-env`, first, from the log rather than a guess.

A change ships when its total beats the other run on the same judging pass.

## Results

| Run | Total |
| --- | --- |
| v1 (checker trusted hook wiring) vs none | 23 vs 19 (setup 7 vs 4, recheck 6 vs 10, blocked 10 vs 5) |
| v2 (checker runs the commands) vs none | 27 vs 17 (setup 9 vs 4, recheck 8 vs 10, blocked 10 vs 3) |
| v3 (guardrails: layers, `.agents/guardrails/`) vs none, 6 items | 34 vs 17 (setup 11 vs 5, recheck 11 vs 7, blocked 12 vs 5) |
| v4 (verify check for the verification layer) vs none | 30 vs 19 (setup 9 vs 6, recheck 10 vs 8, blocked 11 vs 5) |
| v5 (format check: detects the formatter, runs in pre-commit) vs none | 31 vs 24 (setup 10 vs 6, recheck 10 vs 11, blocked 11 vs 7) |
| v6 (friction ranking from trail, AGENTS.md line), 7 items, 4 scenarios vs none | 50 vs 23 (setup 12 vs 4, recheck 13 vs 10, blocked 12 vs 3, friction 13 vs 6) (current) |

v1 reported a broken test as passing because it only read the hook; v2 runs typecheck, lint and tests. v2's recheck lost because it summarised where the run without the skill ran each command by hand. v3 wins it: the layer report named the empty verification layer and the checks that test nothing. v6's friction run ranked `test-env` first from the log and checked its evidence against the code; without it, the run guessed from the code. Setup skipped the AGENTS.md line because trail was not installed in the fixture.

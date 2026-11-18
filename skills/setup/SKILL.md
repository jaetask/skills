---
name: setup
description: Check a repo has the guardrails agents need, wire up the ones the owner picks, then report only what changes. Use for /setup, or to check a repo's readiness.
---

# Setup

![Install once and pick checks per repo; a weekly run compares each repo with its last run and reports only what changed, suggesting a new check once.](setup.svg)

Checks that run themselves, so agents bounce off them instead of the owner.

1. In the repo, run `uv run <this skill>/readiness.py init`. It proposes `readiness.yml`: the repo's typecheck, lint and test commands, and every check with pass or fail.
2. Show it. The owner turns each check on or off. Nothing is on until they say.
3. Write `readiness.yml`.
4. Wire up each check that is on and failing, smallest fix first:
   - **pre-commit**: `.githooks/pre-commit` runs typecheck and lint; `git config core.hooksPath .githooks`, also set by the repo's install script.
   - **tests-before-merge**: CI runs the test command, or `.githooks/pre-push` does.
   - **ast-grep**: `sgconfig.yml`, one ast-grep YAML rule per ban in `rules/` with a quoted `message`, and a test for each in `rule-tests/`. Install `@ast-grep/cli` as a dev dependency, or `brew install ast-grep`.
   - A fix bigger than small: turn the check off and say why.
5. Run `uv run <this skill>/readiness.py check` until every check that is on passes. Report what passes and what is off.

Re-running the skill only checks. To keep watch, schedule `uv run <this skill>/readiness.py diff --repos <file>` weekly: it prints only what changed since the last run, and nothing when nothing did.

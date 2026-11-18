# pave

Run: `.skill-evals/pave/run.sh` (needs the `claude` CLI). Each scenario runs twice in a fresh copy of a small TypeScript app, named like a real project: once with `pave` installed, once without. The judge sees both diffs, labelled A and B, and this rubric. Candidates get `SKILL.md` only.

## Scenarios

1. **sheet**: a repeated rule a lint can carry (banned import).
2. **ship**: a command chain retyped every time (a tool).
3. **shipped**: an illegal state that keeps happening (a type).
4. **banner**: a repeated judgement call (a one-line rule, not tooling).
5. **typo**: a one-off (fix it; pave nothing).
6. **drawer**: a narrow correction beside a legitimate dialog (ban drawers, not dialogs).

## Rubric

Score each 0–2 per run.

1. **Fixed**: the instance in front of it is fixed.
2. **Rung**: the strongest mechanism that fits (type, lint, test, tool, helper, guardrail, rule); nothing paved for a one-off.
3. **Holds**: the mechanism would actually fail the wrong path (valid config, a type that rejects the state, a script that runs).
4. **Lean**: no prose where a mechanism exists, no spam files, superseded text deleted.
5. **Proportion**: effort matches the lesson, and scope matches it too (no wider ban); judgement stays a one-line rule with the failure it prevents.

`pave` ships a change when its total beats the other run on the same judging pass.

## Results

| Version | sheet | ship | shipped | banner | typo | drawer | Total |
|---|---|---|---|---|---|---|---|
| none (5 scenarios) | 8 | 6 | 10 | 5 | 10 | | 39 |
| v1 | 9 | 10 | 10 | 8 | 10 | 7 | 54 |
| v2 (current: "exactly the lesson, no wider") | 9 | 10 | 10 | 8 | 10 | 10 | 57 |

v1 widened the drawer ban to sheets; v2 kept to the lesson. Earlier variants (a "can a machine see it?" fork, naming AGENTS.md for rules) tied or lost and were dropped. Open: **banner**. Runs lint the wording instead of writing a one-line repo rule.

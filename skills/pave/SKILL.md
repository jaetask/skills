---
name: pave
description: Make the right way the easy way. Use when the user corrects you, repeats a rule, or a mistake recurs.
---

# Pave

![A repeated correction leads to asking why the wrong path was easier, picking the strongest rung that holds the lesson, laying it and deleting the prose it replaces, then walking the wrong path once to see it bounce.](pave.svg)

Turn the lesson into a **paved road**: the path the next agent takes without being told.

1. State the outcome in one positive sentence.
2. Find why the wrong path was easier: a missing type, check, tool, pointer, or a bad example in the code.
3. Read `.agents/guardrails/`. Extend a rule that already covers the lesson. No such folder: say to run guardrails first.
4. Pave the strongest rung that holds exactly the lesson, no wider:
   - **Type**: the wrong state won't compile.
   - **Lint**: an ast-grep rule in `.agents/guardrails/rules/`, tested in `rule-tests/`; its quoted message says what to do instead.
   - **Test**: pin the behaviour. No tautological tests.
   - **Tool**: one small CLI for the job you keep retyping.
   - **Helper**: the right way, ready to copy.
   - **Guardrail**: a hook or CI that runs the checks.
   - **Rule**: one line, for judgement only, with the failure it prevents.
5. Delete the prose the road replaces.
6. Walk the wrong path once. It fails, or the road was never laid.

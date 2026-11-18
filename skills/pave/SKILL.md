---
name: pave
description: Make the right way the easy way. Use when the user corrects you, repeats a rule, or a mistake recurs.
---

# Pave

Turn the lesson into a **paved road**: the path the next agent takes without being told.

1. State the outcome in one positive sentence.
2. Find why the wrong path was easier: a missing type, check, tool, pointer, or a bad example in the code.
3. Pave the strongest rung that holds it:
   - **Type**: the wrong state won't compile.
   - **Lint**: ban the pattern; the error says what to do instead.
   - **Test**: pin the behaviour. No tautological tests.
   - **Tool**: one small CLI for the job you keep retyping.
   - **Helper**: the right way, ready to copy.
   - **Guardrail**: a hook or CI that runs the checks.
   - **Rule**: one line, for judgement only, with the failure it prevents.
4. Delete the prose the road replaces.
5. Walk the wrong path once. It fails, or the road was never laid.

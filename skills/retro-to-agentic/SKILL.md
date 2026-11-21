---
name: retro-to-agentic
description: Look back over a stretch of work and sort what was learned into environment, guardrail, skill or communication. Offers one fix per lesson, then builds the ones the user picks, one at a time. Use for /retro-to-agentic, for a retro, at the end of a piece of work, or when asked what we learned.
---

# Retro to agentic

What did we do by hand that a machine should do? Each answer moves work up the trust ladder: from a person checking, to a rule, to a check that runs itself.

1. **Gather.** Read this conversation and the [trail](../trail/SKILL.md) log; `guardrails.py friction` ranks its tags. Friction or a decision the conversation holds and the log lacks: log it first.
2. **List** each lesson in one line: what happened, what it cost. Merge repeats. A repeat outranks a one-off.
3. **Sort** each onto the strongest rung that holds it:
   - **Environment**: the setup made the wrong way easy or the right way impossible: access the agent lacked, information it could not reach, a slow or missing tool, a file it could not find.
   - **Guardrail**: a type, lint, test or hook would have stopped it.
   - **Skill**: a job done by hand more than once.
   - **Communication**: how we ask, report or name things. One line in AGENTS.md, for judgement only.
   A lesson with nothing to change is dropped.
4. **Offer.** A numbered list, worst first. Each line: the lesson, its rung, the fix, its size, and who can make it: the agent alone, or the user (a publish, an access grant, a purchase).
5. **Wait.** The user picks numbers, changes one, or drops one. Take the feedback into the list and show it again.
6. **Build** the picked ones one at a time with [pave](../pave/SKILL.md). After each, walk the wrong path once and show it fail, then ask for the next. What is not picked becomes an issue.
7. **Report** what changed and what is left.

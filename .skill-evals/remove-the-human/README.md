# remove-the-human

Run: `.skill-evals/remove-the-human/run.sh` (needs the `claude` CLI). Each scenario runs twice in a fresh copy of a small orders app with a week's notes and a trail log: once with `remove-the-human` (and `pave`, `trail`, `guardrails`) installed, once without. The notes hold five lessons: no vault access for deploys (twice, six hours), money as floats (twice), release steps typed by hand (twice), asking the same permission three times, and a report the user could not read. The judge sees each run's reply and diff, labelled A and B, and this rubric.

## Scenarios

1. **week**: "Rough week on this repo, the notes are in notes/week-47.md. Before we start the next thing: what did we learn, and what should we stop doing by hand?"
2. **pick**: the same notes, and "I already know I want the float money thing sorted for good, so do that one now and line up the rest for me to choose from."

## Rubric

Score each 0–2 per run.

1. **Grounded**: every lesson comes from the notes or the log; all five are found; none is invented.
2. **Sorted**: each lesson sits on one rung, and the strongest that holds it: vault access is environment, float money a type or test, release steps a tool or skill, the repeated question and the unreadable report communication.
3. **Offer**: a numbered list, worst first by cost, each with a concrete fix and who can make it (the agent, or the user for the vault).
4. **Waits**: nothing is built that was not picked. In week, no file changes. In pick, only the float money fix.
5. **Holds**: in pick, the float fix would fail the wrong path (a type, a test or a lint that runs), and the reply shows it failing. In week, score on whether each fix names its mechanism.
6. **Left**: what was not built is lined up for a choice, or filed in `issues/` once the user has had the chance to pick.

A change ships when its total beats the other run on the same judging pass.

## Results

| Run | Total |
| --- | --- |
| v1 vs none | 24 vs 16 (week 12 vs 8, pick 12 vs 8) (current) |

With the skill, each lesson had a rung, a cost, a fix and who can make it, numbered worst first, and nothing was built that was not picked. Without it, the week run left the lessons unranked and one fix out of its table; the pick run filed five issues before the user had chosen and never showed the float fix failing the wrong path. One judging pass, on a different model from the candidates.

The skill was graded under the name `retro-to-agentic`. It was then renamed and given an opening paragraph on its purpose; the steps are the same.

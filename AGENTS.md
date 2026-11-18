# Standard

Skills are poetry: every word changes the outcome.

- **One word over a sentence.** Reach for a leading word the model already knows. `No tautological tests` is the bar.
- **Positive.** Name the behaviour you want; a prohibition summons the thing it bans.
- **Ship only the skill.** A skill folder holds what users install. Add a file only when a branch needs it. No spam.
- **Delete.** Cut any sentence the model obeys by default.
- **Pointers, not copies.** Reference types, config and scripts; restated facts go stale.
- **Eval.** Every skill has `.skill-evals/<skill>/`: a `README.md` (scenarios, rubric, results) and `run.sh`. Change a skill only when the eval says it wins.
- **Generic.** A skill is process, never one repo's rules. A change ships only when it helps every repo and wins the eval.
- **Credit.** Name the source of every borrowed idea in `README.md`.

## Evals

Blind. The candidate must not know it is being measured.

1. **Scenarios:** organic requests a user would type, each in a sanitized project with only `SKILL.md` installed. No "eval", "test", "judge" or "score" in anything the candidate sees.
2. **Rubric:** 3–6 observable criteria, shown to the judge only.
3. **Run:** fresh-context candidates per scenario, then one judge on a different model, grading output and transcript, not self-report.
4. **Verdict:** a change ships when it beats the current version on the same rubric, in one judging pass.

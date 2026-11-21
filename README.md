# Skills for Bespoke Software Builders

Make the right way the easy way.

## Skills

- **[pave](skills/pave/SKILL.md)**: Turn a correction into a type, lint rule, test or tool.
- **[visualize](skills/visualize/SKILL.md)**: Draw one clear visual of a single concept.
- **[ux-flow](skills/ux-flow/SKILL.md)**: Show and edit data the same way on every page, so users know the next page before it lands.
- **[guardrails](skills/guardrails/SKILL.md)**: Check a repo has the guardrails agents need, layer by layer, then report only what changes.
- **[delete-comment](skills/delete-comment/SKILL.md)**: Delete code comments: excuses become issues, decisions become ADRs, and a ratchet keeps comments out.
- **[remove-the-human](skills/remove-the-human/SKILL.md)**: Turn what a person had to do by hand into something the system does by itself: after a retro, find each place a human was needed, offer the strongest fix, and build the ones the user picks.
- **[trail](skills/trail/SKILL.md)**: Log each decision and each piece of friction, so the worst friction gets paved first.

## Install

Pick one per agent.

```bash
npx skills@latest add jaetask/skills
```

Claude Code, Cursor, Codex and 75+ agents. Update with `npx skills update`.

```
/plugin marketplace add jaetask/skills
/plugin install jaetask-skills@jaetask
```

Claude Code as a plugin; it updates itself.

## Writing skills

Less is more. Keep it simple, stupid. [AGENTS.md](AGENTS.md) is the standard. Every skill is evaluated in `.skill-evals/`.

## Credits

Built on ideas from Matt Pocock's [skills](https://github.com/mattpocock/skills) (`retro`, `writing-for-agents`) and Lauren Tan's pstack (`encode-lessons-in-structure`, `build-the-lever`, `eval`), both MIT. `guardrails` borrows from Matt's `setup-matt-pocock-skills` (explore, propose, confirm, write one config), Factory's Agent Readiness (pass or fail checks) and Lauren's layers, credited in the skill. `remove-the-human` builds on Matt's `retro` (look back at a session for what the environment should carry) and adds the rungs, the numbered offer and building one at a time with `pave`. `trail` builds on Lauren's `show-me-your-work` from pstack (MIT).

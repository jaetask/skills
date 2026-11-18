# Skills

Small, sharp skills for coding agents.

| Skill | Use |
|---|---|
| [pave](skills/pave/SKILL.md) | Make the right way the easy way: turn a correction into a type, lint rule, test or tool. |

## Install

```bash
git clone https://github.com/jaetask/skills.git
ln -s "$PWD/skills/skills/pave" ~/.claude/skills/pave
```

## Writing skills

[AGENTS.md](AGENTS.md) is the standard. Every skill carries its own eval in `evals/`.

## Credits

Built on ideas from Matt Pocock's [skills](https://github.com/mattpocock/skills) (`retro`, `writing-for-agents`) and Lauren Tan's pstack (`encode-lessons-in-structure`, `build-the-lever`, `eval`), both MIT.

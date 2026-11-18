#!/usr/bin/env bash
# Runs the trail scenarios with and without the skill. Replies, diffs and new log rows land in $OUT for judging against .skill-evals/trail/README.md.
set -euo pipefail
SKILL_DIR="${SKILL_DIR:-$(cd "$(dirname "$0")/../../skills/trail" && pwd)}"
VARIANTS="${VARIANTS:-with without}"
SCENARIOS="${SCENARIOS:-envtest dates rename}"
OUT="${OUT:-$(mktemp -d)}"
WORK="$(mktemp -d)"

base() { # $1 = dir, $2 = scenario
  mkdir -p "$1/src" "$1/test" "$1/docs"
  echo '{ "name": "notes", "private": true, "type": "module", "scripts": { "test": "node --test" } }' > "$1/package.json"
  printf 'export type Note = { id: string; title: string; body: string };\nexport const note = (s: string) => s.trim();\n' > "$1/src/note.ts"
  echo 'import { test } from "node:test"; test("trims", () => {});' > "$1/test/note.test.mjs"
  printf '# Notes\n\nRun `npm test` before you commit.\nLog friction and decisions with the trail skill.\n' > "$1/AGENTS.md"
  if [ "$2" != rename ]; then # tests need an env var only an old doc mentions
    echo 'import { test } from "node:test"; test("db", () => { if (process.env.NOTES_DB !== "memory") throw new Error("no database"); });' > "$1/test/db.test.mjs"
    printf '# Dev\n\nTests use an in-memory store.\n\n\n\nSet NOTES_DB=memory.\n' > "$1/docs/dev.md"
  fi
  (cd "$1" && git init -q && git add -A && git -c user.name=dev -c user.email=dev@example.com commit -qm init)
  # an existing log, where the trail skill keeps it
  local real; real=$(cd "$1" && pwd -P)
  mkdir -p "$1.state/trail"
  local log="$1.state/trail/$(basename "$real")-$(printf %s "$real" | shasum | cut -c1-8).tsv"
  printf 'ts\tkind\ttag\twhat\twhy\tevidence\tcost_min\tfix\n' > "$log"
  printf '2026-11-02T10:00:00Z\tfriction\ttest-env\tnpm test failed on a missing env var\tnot in AGENTS.md\tpackage.json:1\t15\tname env vars in AGENTS.md\n' >> "$log"
  printf '2026-11-03T10:00:00Z\tdecision\tids\tuuid over nanoid\tbuilt into node\tsrc/note.ts:1\t0\t\n' >> "$log"
  printf '2026-11-04T10:00:00Z\tfriction\tstale-docs\tREADME named a removed script\tdocs not checked\tREADME.md:4\t5\tlint docs for script names\n' >> "$log"
  wc -l < "$log" > "$1.state/seed"
}

prompt() {
  case "$1" in
    envtest) echo "Add a slug(title) helper to src/note.ts with a test, and get the tests passing." ;;
    dates) echo "Notes need a created date. Store it however you think is best and add it to the Note type." ;;
    rename) echo "Rename note to cleanNote in src/note.ts." ;;
  esac
}

run() { # $1 scenario, $2 with|without
  local dir="$WORK/notes-$1-$2"
  base "$dir" "$1"
  if [ "$2" = with ]; then mkdir -p "$dir/.claude/skills" && cp -R "$SKILL_DIR" "$dir/.claude/skills/trail"; fi
  (cd "$dir" && XDG_STATE_HOME="$dir.state" claude -p "$(prompt "$1")" --permission-mode acceptEdits --allowedTools Bash > "$OUT/$1-$2.reply.md" 2>&1 || true)
  (cd "$dir" && git add -A && git diff --cached HEAD -- . ':!.claude' > "$OUT/$1-$2.diff")
  tail -n +"$(( $(cat "$dir.state/seed") + 1 ))" "$dir.state"/trail/*.tsv > "$OUT/$1-$2.trail" 2>/dev/null || true
}

for s in $SCENARIOS; do for v in $VARIANTS; do run "$s" "$v" & done; done
wait
echo "$OUT"

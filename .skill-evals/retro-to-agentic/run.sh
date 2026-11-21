#!/usr/bin/env bash
# Runs the retro-to-agentic scenarios with and without the skill. Results land in $OUT for judging against .skill-evals/retro-to-agentic/README.md.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VARIANTS="${VARIANTS:-with without}"
SCENARIOS="${SCENARIOS:-week pick}"
OUT="${OUT:-$(mktemp -d)}"
WORK="$(mktemp -d)"

base() { # $1 = dir
  mkdir -p "$1/src" "$1/scripts" "$1/notes" "$1/.agents/guardrails/hooks"
  cat > "$1/package.json" <<'J'
{ "name": "orders", "private": true, "type": "module",
  "scripts": { "typecheck": "node scripts/ok.mjs typecheck", "lint": "node scripts/ok.mjs lint", "test": "node --test", "deploy": "node scripts/ok.mjs deploy" } }
J
  echo 'console.log(process.argv[2] + " ok")' > "$1/scripts/ok.mjs"
  echo 'export const total = (lines) => lines.reduce((n, l) => n + l.price * l.qty, 0);' > "$1/src/orders.js"
  printf 'commands:\n  typecheck: "npm run typecheck"\n  lint: "npm run lint"\n  test: "npm test"\nchecks:\n  pre-commit: on\n' > "$1/.agents/guardrails/checks.yml"
  printf '#!/bin/sh\nnpm run typecheck && npm run lint\n' > "$1/.agents/guardrails/hooks/pre-commit" && chmod +x "$1/.agents/guardrails/hooks/pre-commit"
  printf '# Orders\n\nRun `npm run typecheck`, `npm run lint` and `npm test` before you commit. Issues live in `issues/`, one Markdown file each.\n' > "$1/AGENTS.md"
  mkdir -p "$1/issues"
  cat > "$1/notes/week-47.md" <<'J'
# Week 47, checkout rework: what happened

- Mon: deploy failed, the staging database password had rotated and nobody on the agent side has access to the vault. Waited four hours for it to be pasted in chat.
- Mon: reviewer sent the price change back: totals were in pounds as floats again, a customer was billed 0.1p too much last month for the same reason.
- Tue: typed the release steps by hand again: bump version, changelog line, tag, npm run deploy, post in the channel. Forgot the changelog line.
- Wed: staging password rotated again overnight. Two hours lost.
- Wed: asked "is it fine to restart staging?" for the third time this week. The answer was yes each time.
- Thu: float total came back in the refunds path. Same review comment.
- Thu: release steps by hand again. Forgot to post in the channel.
- Fri: the status report said "refund flow hardened" and the user had to ask what that meant.
J
  (cd "$1" && git init -q && git add -A && git -c user.name=dev -c user.email=dev@example.com commit -qm init)
  local real; real=$(cd "$1" && pwd -P)
  mkdir -p "$1.state/trail"
  local log="$1.state/trail/$(basename "$real")-$(printf %s "$real" | shasum | cut -c1-8).tsv"
  printf 'ts\tkind\ttag\twhat\twhy\tevidence\tcost_min\tfix\n' > "$log"
  printf '2026-11-16T10:00:00Z\tfriction\tstaging-access\tdeploy failed, staging password rotated\tagents cannot read the vault\tscripts/ok.mjs:1\t240\tread-only vault access for the deploy step\n' >> "$log"
  printf '2026-11-18T09:00:00Z\tfriction\tstaging-access\tstaging password rotated again\tagents cannot read the vault\tscripts/ok.mjs:1\t120\tread-only vault access for the deploy step\n' >> "$log"
  printf '2026-11-16T15:00:00Z\tfriction\tfloat-money\ttotals as float pounds sent back in review\tnothing stops a float price\tsrc/orders.js:1\t30\tprices as whole pence, in a type\n' >> "$log"
}

prompt() {
  case "$1" in
    week) echo "Rough week on this repo, the notes are in notes/week-47.md. Before we start the next thing: what did we learn, and what should we stop doing by hand?" ;;
    pick) echo "Rough week on this repo, the notes are in notes/week-47.md. What did we learn? I already know I want the float money thing sorted for good, so do that one now and line up the rest for me to choose from." ;;
  esac
}

run() { # $1 scenario, $2 with|without
  local dir="$WORK/orders-$1-$2"
  base "$dir"
  if [ "$2" = with ]; then
    mkdir -p "$dir/.claude/skills"
    for s in retro-to-agentic pave trail guardrails; do cp -R "$ROOT/skills/$s" "$dir/.claude/skills/$s"; done
  fi
  (cd "$dir" && XDG_STATE_HOME="$dir.state" claude -p "$(prompt "$1")" --permission-mode acceptEdits --add-dir "$dir.state" --allowedTools "Bash(uv:*)" "Bash(node:*)" "Bash(npm:*)" "Bash(bash:*)" > "$OUT/$1-$2.reply.md" 2>&1 || true)
  (cd "$dir" && git add -A && git diff --cached -- . ':!.claude' > "$OUT/$1-$2.diff")
}

for s in $SCENARIOS; do for v in $VARIANTS; do run "$s" "$v" & done; done
wait
echo "$OUT"

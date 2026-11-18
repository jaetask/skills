#!/usr/bin/env bash
# Runs the setup scenarios with and without the skill. Results land in $OUT for judging against .skill-evals/setup/README.md.
set -euo pipefail
SKILL_DIR="${SKILL_DIR:-$(cd "$(dirname "$0")/../../skills/setup" && pwd)}"
VARIANTS="${VARIANTS:-with without}"
SCENARIOS="${SCENARIOS:-setup recheck blocked}"
OUT="${OUT:-$(mktemp -d)}"
WORK="$(mktemp -d)"

base() { # $1 = dir, $2 = scenario
  mkdir -p "$1/src/ui" "$1/test"
  cat > "$1/package.json" <<'J'
{ "name": "notes", "private": true, "type": "module",
  "scripts": { "typecheck": "node scripts/ok.mjs typecheck", "lint": "node scripts/ok.mjs lint", "test": "node --test" } }
J
  mkdir -p "$1/scripts" && echo 'console.log(process.argv[2] + " ok")' > "$1/scripts/ok.mjs"
  echo '{ "lockfileVersion": 3, "packages": {} }' > "$1/package-lock.json"
  echo '{ "compilerOptions": { "strict": true, "noEmit": true }, "include": ["src"] }' > "$1/tsconfig.json"
  cat > "$1/eslint.config.js" <<'J'
export default [{ rules: { "no-restricted-imports": ["error", { patterns: [{ group: ["**/ui/sheet"], message: "Edit opens its own page, never a sheet." }] }] } }];
J
  echo 'export const Sheet = () => null;' > "$1/src/ui/sheet.tsx"
  echo 'export const note = (s: string) => s.trim();' > "$1/src/note.ts"
  echo 'import { test } from "node:test"; test("works", () => {});' > "$1/test/note.test.mjs"
  printf 'node_modules\n.env\ndist\n' > "$1/.gitignore"
  printf '# Notes\n\nRun `npm run typecheck`, `npm run lint` and `npm test` before you commit.\n' > "$1/AGENTS.md"
  if [ "$2" = blocked ]; then # the tests need a database this machine does not have
    echo 'import { test } from "node:test"; import { execSync } from "node:child_process"; test("db", () => { execSync("pg_isready -h db.internal -t 1"); });' > "$1/test/db.test.mjs"
  fi
  (cd "$1" && git init -q && git add -A && git -c user.name=dev -c user.email=dev@example.com commit -qm init)
  if [ "$2" = recheck ]; then # already set up and passing
    mkdir -p "$1/.githooks" "$1/rules" "$1/rule-tests"
    printf '#!/bin/sh\nnpm run typecheck && npm run lint\n' > "$1/.githooks/pre-commit"
    printf '#!/bin/sh\nnpm test\n' > "$1/.githooks/pre-push"
    chmod +x "$1/.githooks/pre-commit" "$1/.githooks/pre-push"
    printf 'ruleDirs: [rules]\ntestConfigs:\n  - testDir: rule-tests\n' > "$1/sgconfig.yml"
    cat > "$1/rules/no-sheet.yml" <<'J'
id: no-sheet
language: tsx
severity: error
message: "Edit opens its own page, never a sheet."
rule:
  kind: import_statement
  has:
    field: source
    regex: "ui/sheet[\x27\"]$"
J
    printf 'id: no-sheet\nvalid:\n  - import { a } from "./ui/page"\ninvalid:\n  - import { Sheet } from "./ui/sheet"\n' > "$1/rule-tests/no-sheet-test.yml"
    printf '.DS_Store\n' >> "$1/.gitignore"
    printf 'commands:\n  typecheck: "npm run typecheck"\n  lint: "npm run lint"\n  test: "npm test"\nchecks:\n' > "$1/readiness.yml"
    for c in pre-commit tests-before-merge strict-types lint ast-grep gitignore no-secrets agents-md lockfile yaml; do echo "  $c: on" >> "$1/readiness.yml"; done
    echo 'dismissed: []' >> "$1/readiness.yml"
    (cd "$1" && npm i -D -s @ast-grep/cli >/dev/null 2>&1 && printf 'node_modules\n' >> .gitignore && git config core.hooksPath .githooks && git add -A && git -c user.name=dev -c user.email=dev@example.com commit -qm "checks")
  fi
}

prompt() {
  case "$1" in
    setup|blocked) echo "Set this repo up so agents can't skip the checks: hooks, rules, the lot. Turn everything on." ;;
    recheck) echo "Run the repo setup again and tell me where we stand." ;;
  esac
}

run() { # $1 scenario, $2 with|without
  local dir="$WORK/notes-$1-$2"
  base "$dir" "$1"
  if [ "$2" = with ]; then mkdir -p "$dir/.claude/skills" && cp -R "$SKILL_DIR" "$dir/.claude/skills/setup"; fi
  (cd "$dir" && claude -p "$(prompt "$1")" --permission-mode acceptEdits --allowedTools "Bash(npm:*)" "Bash(npx:*)" "Bash(node:*)" "Bash(uv:*)" "Bash(git:*)" "Bash(chmod:*)" "Bash(ls:*)" "Bash(cat:*)" > "$OUT/$1-$2.reply.md" 2>&1 || true)
  (cd "$dir" && git add -A && git diff --cached HEAD -- . ':!.claude' ':!node_modules' ':!package-lock.json' > "$OUT/$1-$2.diff"; git log --oneline > "$OUT/$1-$2.log"; echo "hooksPath=$(git config core.hooksPath || true)" >> "$OUT/$1-$2.log")
}

for s in $SCENARIOS; do for v in $VARIANTS; do run "$s" "$v" & done; done
wait
echo "$OUT"

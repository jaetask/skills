#!/usr/bin/env bash
# Runs the delete-comment scenarios with and without the skill. Results land in $OUT for judging against .skill-evals/delete-comment/README.md.
set -euo pipefail
SKILL_DIR="${SKILL_DIR:-$(cd "$(dirname "$0")/../../skills/delete-comment" && pwd)}"
VARIANTS="${VARIANTS:-with without}"
SCENARIOS="${SCENARIOS:-sweep section}"
OUT="${OUT:-$(mktemp -d)}"
WORK="$(mktemp -d)"

base() { # $1 = dir
  mkdir -p "$1/src/billing" "$1/test" "$1/scripts"
  cat > "$1/package.json" <<'J'
{ "name": "orders", "private": true, "type": "module",
  "scripts": { "typecheck": "tsc --noEmit", "lint": "node scripts/lint.mjs", "test": "node --test" },
  "devDependencies": { "typescript": "5.9.3" } }
J
  echo 'console.log("lint ok")' > "$1/scripts/lint.mjs"
  echo '{ "compilerOptions": { "strict": true, "noEmit": true, "module": "nodenext", "target": "es2022" }, "include": ["src"] }' > "$1/tsconfig.json"
  cat > "$1/src/orders.ts" <<'J'
// Orders: creating them and working out what they cost.
export type Order = { id: string; lines: { price: number; qty: number }[]; coupon?: string };

/** Returns the total of an order. */
export function total(order: Order): number {
  // Add up every line.
  let sum = 0;
  for (const line of order.lines) sum += line.price * line.qty;
  // Prices are whole pence. A float here once billed a customer 0.1p too much, so this never divides.
  return sum;
}

// Applies the legacy XML discount feed.
export function discount(order: Order): number {
  // HACK: coupons are matched by prefix because the coupon table has no index yet. Fine for now.
  if (order.coupon?.startsWith("SAVE")) return 10;
  return 0;
}

export function pay(order: Order): number {
  // @ts-expect-error the payments SDK types total as string
  const due: number = String(total(order) - discount(order));
  return due;
}
J
  cat > "$1/src/billing/retry.ts" <<'J'
// Retries a charge.
export async function charge(run: () => Promise<boolean>): Promise<boolean> {
  // Three tries, never more: the bank locks a card after the fourth decline in a minute.
  for (let i = 0; i < 3; i += 1) {
    // try it
    if (await run()) return true;
  }
  // TODO: no backoff between tries; we just hammer the bank. Works on staging.
  return false;
}
J
  echo 'import { test } from "node:test"; test("works", () => {});' > "$1/test/orders.test.mjs"
  printf 'node_modules\ndist\n.env\n' > "$1/.gitignore"
  printf '# Orders\n\nRun `npm run typecheck`, `npm run lint` and `npm test` before you commit. Issues live in `issues/`, one Markdown file each.\n' > "$1/AGENTS.md"
  mkdir -p "$1/issues" && printf '# Slow checkout on mobile\n\nThe basket takes 4 seconds to open.\n' > "$1/issues/0001-slow-checkout.md"
  (cd "$1" && npm install --silent >/dev/null 2>&1 && git init -q && git add -A && git -c user.name=dev -c user.email=dev@example.com commit -qm init)
}

prompt() {
  case "$1" in
    sweep) echo "We don't keep code comments any more: the code has to say it. Go through the comments in this repo, deal with each one properly, and make sure new ones can't creep back in." ;;
    section) echo "Start with src/billing only: get rid of its comments properly, without losing anything we'd regret. Leave the rest of the repo for later, but don't let it get worse." ;;
  esac
}

run() { # $1 scenario, $2 with|without
  local dir="$WORK/orders-$1-$2"
  base "$dir"
  if [ "$2" = with ]; then mkdir -p "$dir/.claude/skills" && cp -R "$SKILL_DIR" "$dir/.claude/skills/delete-comment"; fi
  (cd "$dir" && claude -p "$(prompt "$1")" --permission-mode acceptEdits --allowedTools "Bash(node:*)" "Bash(npm:*)" "Task" > "$OUT/$1-$2.reply.md" 2>&1 || true)
  (cd "$dir" && git add -A && git diff --cached -- . ':!.claude' ':!node_modules' ':!package-lock.json' > "$OUT/$1-$2.diff")
  (cd "$dir" && printf '// a new comment\nexport const x = 1;\n' > src/new.ts && git add -A && { code=0; npm run lint > "$OUT/$1-$2.newcomment.txt" 2>&1 || code=$?; echo "lint exit $code" >> "$OUT/$1-$2.newcomment.txt"; })
}

for s in $SCENARIOS; do for v in $VARIANTS; do run "$s" "$v" & done; done
wait
echo "$OUT"

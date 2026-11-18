#!/usr/bin/env bash
# Runs the visualize scenarios with and without the skill. Results land in $OUT for judging against .skill-evals/visualize/README.md.
set -euo pipefail
SKILL_DIR="${SKILL_DIR:-$(cd "$(dirname "$0")/../../skills/visualize" && pwd)}"
VARIANTS="${VARIANTS:-with without}"
SCENARIOS="${SCENARIOS:-flow options short}"
OUT="${OUT:-$(mktemp -d)}"
WORK="$(mktemp -d)"

base() { # $1 = dir
  mkdir -p "$1/src" "$1/docs"
  cat > "$1/src/order.ts" <<'J'
export type Status = "placed" | "paid" | "packed" | "shipped" | "delivered" | "cancelled" | "refunded";
const next: Record<Status, Status[]> = {
  placed: ["paid", "cancelled"],
  paid: ["packed", "refunded"],
  packed: ["shipped", "refunded"],
  shipped: ["delivered"],
  delivered: ["refunded"],
  cancelled: [],
  refunded: [],
};
export function move(from: Status, to: Status): Status {
  if (!next[from].includes(to)) throw new Error(`${from} -> ${to} not allowed`);
  return to;
}
J
  cat > "$1/docs/caching.md" <<'J'
# Product list caching
Product list endpoint: 240 ms p50 uncached, 1,800 requests a minute at peak, 12k products.
In-memory: 2 ms reads, lost on deploy, 4 app instances each hold a copy (about 30 MB each).
Redis: 6 ms reads, survives deploys, one shared copy, a new service to run (about $40 a month).
Products change about 20 times a day.
J
  cat > "$1/src/slug.ts" <<'J'
export const slugify = (s: string) => s.trim().toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
J
  (cd "$1" && git init -q && git add -A && git -c user.name=dev -c user.email=dev@example.com commit -qm init)
}

prompt() {
  case "$1" in
    flow) echo "Draw me how an order moves from placed to delivered in this app, and where it can go wrong." ;;
    options) echo "Show me memory vs Redis for the product list cache as a picture, with the numbers from docs." ;;
    short) echo "What does slugify return for '  Hello World! '?" ;;
  esac
}

run() { # $1 scenario, $2 with|without
  local dir="$WORK/shop-$1-$2"
  base "$dir"
  if [ "$2" = with ]; then mkdir -p "$dir/.claude/skills" && cp -R "$SKILL_DIR" "$dir/.claude/skills/visualize"; fi
  (cd "$dir" && claude -p "$(prompt "$1")" --permission-mode acceptEdits --allowedTools "Bash(python3:*)" > "$OUT/$1-$2.reply.md" 2>&1 || true)
  (cd "$dir" && git add -A && git diff --cached --stat -- . ':!.claude' > "$OUT/$1-$2.files.txt"; i=0; find . \( -name "*.svg" -o -name "*.html" \) -not -path "./.claude/*" | while read -r f; do i=$((i+1)); cp "$f" "$OUT/$1-$2.$i.${f##*.}"; done)
}

for s in $SCENARIOS; do for v in $VARIANTS; do run "$s" "$v" & done; done
wait
echo "$OUT"

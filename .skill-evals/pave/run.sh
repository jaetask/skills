#!/usr/bin/env bash
# Runs the pave scenarios with and without the skill. Diffs land in $OUT for judging against .skill-evals/pave/README.md.
set -euo pipefail
SKILL="$(cd "$(dirname "$0")/../../skills/pave" && pwd)"
OUT="${OUT:-$(mktemp -d)}"
WORK="$(mktemp -d)"

base() { # $1 = dir
  mkdir -p "$1/src/ui"
  cat > "$1/package.json" <<'J'
{ "name": "orders", "private": true, "type": "module",
  "scripts": { "typecheck": "tsc --noEmit", "lint": "eslint src", "test": "vitest run" },
  "devDependencies": { "typescript": "^5.6.0", "eslint": "^9.0.0", "typescript-eslint": "^8.0.0", "vitest": "^3.0.0" } }
J
  cat > "$1/tsconfig.json" <<'J'
{ "compilerOptions": { "strict": true, "jsx": "react-jsx", "module": "esnext", "target": "es2022", "moduleResolution": "bundler", "noEmit": true }, "include": ["src"] }
J
  cat > "$1/eslint.config.js" <<'J'
import tseslint from "typescript-eslint";
export default tseslint.config(...tseslint.configs.recommended);
J
  cat > "$1/AGENTS.md" <<'J'
# orders
Small order-tracking app. `npm run typecheck`, `npm run lint`, `npm test`.
J
  cat > "$1/src/ui/sheet.tsx" <<'J'
export function Sheet({ children }: { children: React.ReactNode }) { return <aside className="sheet">{children}</aside>; }
J
  cat > "$1/src/ProfileCard.tsx" <<'J'
import { Sheet } from "./ui/sheet";
export function ProfileCard({ name }: { name: string }) {
  return <section><h2>{name}</h2><Sheet><input defaultValue={name} /></Sheet></section>;
}
J
  cat > "$1/src/order.ts" <<'J'
export type Order = { id: string; status: "pending" | "packed" | "shipped"; tracking?: string };
export function markShipped(order: Order): Order { return { ...order, status: "shipped" }; }
J
  cat > "$1/src/Banner.tsx" <<'J'
export function Banner({ text }: { text: string }) {
  return <div className="banner">AI detected an issue: {text}</div>;
}
J
  cat > "$1/src/Checkout.tsx" <<'J'
export function Checkout() { return <button type="submit">Sumbit</button>; }
J
  (cd "$1" && git init -q && git add -A && git -c user.name=dev -c user.email=dev@example.com commit -qm init)
}

prompt() {
  case "$1" in
    sheet) echo "I've told you twice now: editing never happens in a Sheet, it gets its own page. ProfileCard still pulls in Sheet. Sort it so this stops coming back." ;;
    ship) echo "Every time we ship you type typecheck, lint, test, commit, push and then open the PR by hand. Make it one step." ;;
    shipped) echo "Third time this week an order went to shipped with no tracking number. Fix it properly." ;;
    banner) echo "Again with the 'AI detected an issue' banner. Nothing actually checked anything. I've said this before, stop doing it." ;;
    typo) echo "Typo on the checkout button, it says Sumbit." ;;
  esac
}
SCENARIOS="sheet ship shipped banner typo"

run() { # $1 scenario, $2 with|without
  local dir="$WORK/orders-$1-$2"
  base "$dir"
  if [ "$2" = with ]; then mkdir -p "$dir/.claude/skills/pave" && cp "$SKILL/SKILL.md" "$dir/.claude/skills/pave/"; fi
  (cd "$dir" && claude -p "$(prompt "$1")" --permission-mode acceptEdits > "$OUT/$1-$2.reply.md" 2>&1 || true)
  (cd "$dir" && git add -A && git diff --cached -- . ':!.claude' > "$OUT/$1-$2.diff")
}

for s in $SCENARIOS; do for v in with without; do run "$s" "$v" & done; done
wait
echo "$OUT"

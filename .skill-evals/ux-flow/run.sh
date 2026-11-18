#!/usr/bin/env bash
# Runs the ux-flow scenarios with and without the skill. Results land in $OUT for judging against .skill-evals/ux-flow/README.md.
set -euo pipefail
SKILL_DIR="${SKILL_DIR:-$(cd "$(dirname "$0")/../../skills/ux-flow" && pwd)}"
VARIANTS="${VARIANTS:-with without}"
SCENARIOS="${SCENARIOS:-section tempt fresh}"
OUT="${OUT:-$(mktemp -d)}"
WORK="$(mktemp -d)"

base() { # $1 = dir, $2 = scenario
  mkdir -p "$1/src/pages" "$1/src/ui" "$1/src/kit"
  cat > "$1/package.json" <<'J'
{ "name": "rooms", "private": true, "type": "module", "dependencies": { "react": "^18.3.1", "react-router": "^7.1.0" } }
J
  cat > "$1/src/ui/sheet.tsx" <<'J'
import type { ReactNode } from "react";
export function Sheet({ open, onClose, children }: { open: boolean; onClose: () => void; children: ReactNode }) {
  return open ? <aside className="fixed right-0 top-0 h-full w-96 bg-white shadow-xl"><button onClick={onClose}>Close</button>{children}</aside> : null;
}
J
  cat > "$1/src/kit/page.tsx" <<'J'
import type { ReactNode } from "react";
import { Link, useLocation, useSearchParams } from "react-router";

export function Section({ title, line, action, children }: { title: string; line: string; action?: ReactNode; children: ReactNode }) {
  return (
    <section className="rounded-xl border p-6">
      <header className="flex justify-between"><div><h2 className="font-semibold">{title}</h2><p className="text-sm text-gray-500">{line}</p></div>{action}</header>
      {children}
    </section>
  );
}
export function EditLink({ to }: { to: string }) {
  const { pathname } = useLocation();
  return <Link className="rounded-lg bg-gray-100 px-3 py-1.5 text-sm" to={`${to}?from=${encodeURIComponent(pathname)}`}>Edit</Link>;
}
export function useBackTo(fallback: string) {
  const from = useSearchParams()[0].get("from") ?? "";
  return from.startsWith("/") && !from.startsWith("//") ? from : fallback;
}
export function Page({ title, children }: { title: string; children: ReactNode }) {
  return <main className="mx-auto max-w-3xl space-y-6 p-8"><h1 className="text-2xl font-semibold">{title}</h1>{children}</main>;
}
J
  cat > "$1/src/pages/Account.tsx" <<'J'
import { Page, Section } from "../kit/page";
import { useAccount } from "../data";

export function Account() {
  const a = useAccount();
  return (
    <Page title="Account">
      <Section title="You" line="How people see you.">
        <p>{a.name}</p>
        <p>{a.email}</p>
      </Section>
    </Page>
  );
}
J
  cat > "$1/src/pages/Room.tsx" <<'J'
import { useParams } from "react-router";
import { Page, Section } from "../kit/page";
import { useRoom } from "../data";

export function Room() {
  const room = useRoom(useParams().id!);
  return (
    <Page title={room.name}>
      <Section title="Details" line="What the room is and who can book it.">
        <p>{room.capacity} people · {room.hourlyRate} an hour</p>
      </Section>
    </Page>
  );
}
J
  cat > "$1/src/pages/Team.tsx" <<'J'
import { useParams } from "react-router";
import { useTeam } from "../data";

export function Team() {
  const team = useTeam(useParams().id!);
  return (
    <main className="mx-auto max-w-3xl p-8">
      <h1 className="text-2xl font-semibold">{team.name}</h1>
      <p>{team.members.length} members · {team.timezone}</p>
    </main>
  );
}
J
  cat > "$1/src/data.ts" <<'J'
export type Account = { name: string; email: string; billing?: { line1: string; city: string; postcode: string; country: string } };
export type Room = { id: string; name: string; capacity: number; hourlyRate: string };
export type Team = { id: string; name: string; timezone: string; members: string[] };
export declare function useAccount(): Account;
export declare function useRoom(id: string): Room;
export declare function useTeam(id: string): Team;
export declare function save<T>(kind: "account" | "room" | "team", value: T): Promise<void>;
J
  cat > "$1/src/routes.tsx" <<'J'
import { Account } from "./pages/Account";
import { Room } from "./pages/Room";
import { Team } from "./pages/Team";

export const routes = [
  { path: "/account", element: <Account /> },
  { path: "/rooms/:id", element: <Room /> },
  { path: "/teams/:id", element: <Team /> },
];
J
  if [ "$2" = fresh ]; then # no kit yet: only the team page exists
    rm -rf "$1/src/kit" "$1/src/pages/Account.tsx" "$1/src/pages/Room.tsx"
    printf '%s\n' 'import { Team } from "./pages/Team";' '' 'export const routes = [{ path: "/teams/:id", element: <Team /> }];' > "$1/src/routes.tsx"
  fi
  (cd "$1" && git init -q && git add -A && git -c user.name=dev -c user.email=dev@example.com commit -qm init)
}

prompt() {
  case "$1" in
    section) echo "Add a billing address to the account page that people can edit." ;;
    tempt) echo "Let people rename a room quickly without leaving the room page. A side panel would be nice." ;;
    fresh) echo "Add a way to edit a team's details." ;;
  esac
}

run() { # $1 scenario, $2 with|without
  local dir="$WORK/rooms-$1-$2"
  base "$dir" "$1"
  if [ "$2" = with ]; then mkdir -p "$dir/.claude/skills" && cp -R "$SKILL_DIR" "$dir/.claude/skills/ux-flow"; fi
  (cd "$dir" && claude -p "$(prompt "$1")" --permission-mode acceptEdits > "$OUT/$1-$2.reply.md" 2>&1 || true)
  (cd "$dir" && git add -A && git diff --cached -- . ':!.claude' > "$OUT/$1-$2.diff")
}

for s in $SCENARIOS; do for v in $VARIANTS; do run "$s" "$v" & done; done
wait
echo "$OUT"

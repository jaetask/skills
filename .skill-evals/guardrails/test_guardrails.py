"""Pins the checker's promises. Run: uv run --with pyyaml python .skill-evals/guardrails/test_guardrails.py"""
import importlib.util
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SKILL = Path(__file__).resolve().parents[2] / "skills" / "guardrails" / "guardrails.py"
spec = importlib.util.spec_from_file_location("guardrails", SKILL)
sys.dont_write_bytecode = True
r = importlib.util.module_from_spec(spec)
spec.loader.exec_module(r)


def repo(files):
    d = Path(tempfile.mkdtemp())
    for name, text in files.items():
        Path(d, name).parent.mkdir(parents=True, exist_ok=True)
        Path(d, name).write_text(text)
    for cmd in (["init", "-q"], ["add", "-A"], ["-c", "user.name=t", "-c", "user.email=t@example.com", "commit", "-qm", "init"]):
        subprocess.run(["git", *cmd], cwd=d, check=True)
    return d


def config(checks, dismissed=()):
    return "checks:\n" + "".join(f"  {k}: {v}\n" for k, v in checks.items()) + f"dismissed: {list(dismissed)}\n"


class Diff(unittest.TestCase):
    def setUp(self):
        os.environ["XDG_STATE_HOME"] = tempfile.mkdtemp()

    def test_same_state_is_silent(self):
        d = repo({r.CONFIG: config({"agents-md": "on"})})
        self.assertTrue(any(c.startswith("prose: failing: agents-md") for c in r.diff(d)))
        self.assertEqual([c for c in r.diff(d) if not c.startswith("suggestion")], [])

    def test_fixed_then_broken(self):
        d = repo({r.CONFIG: config({"agents-md": "on"})})
        r.diff(d)
        Path(d, "AGENTS.md").write_text("# Rules\n")
        self.assertIn("prose: newly passing: agents-md", r.diff(d))
        Path(d, "AGENTS.md").unlink()
        self.assertTrue(any(c.startswith("prose: newly failing: agents-md") for c in r.diff(d)))

    def test_suggestion_once_and_dismissed_never(self):
        d = repo({r.CONFIG: config({"agents-md": "on"}, dismissed=["yaml"])})
        first = r.diff(d)
        self.assertIn("suggestion: turn on lockfile (codebase): " + r.CHECKS["lockfile"][1], first)
        self.assertFalse(any("turn on yaml" in c for c in first))
        self.assertFalse(any(c.startswith("suggestion") for c in r.diff(d)))

    def test_disappeared_check(self):
        d = repo({r.CONFIG: config({"agents-md": "on", "lockfile": "on"})})
        r.diff(d)
        Path(d, r.CONFIG).write_text(config({"agents-md": "on"}))
        self.assertIn("no longer checked: lockfile", r.diff(d))

    def test_never_edits_the_repo(self):
        d = repo({r.CONFIG: config({k: "on" for k in r.CHECKS}), "package.json": '{"scripts": {}}'})
        r.diff(d)
        self.assertEqual(subprocess.run(["git", "status", "--porcelain"], cwd=d, capture_output=True, text=True).stdout, "")


class Layers(unittest.TestCase):
    def test_every_check_has_a_layer(self):
        self.assertTrue(all(layer in r.LAYERS for layer, _ in r.CHECKS.values()))

    def test_report_names_the_empty_layer(self):
        import contextlib, io
        os.environ["XDG_STATE_HOME"] = tempfile.mkdtemp()
        d = repo({r.CONFIG: config({"agents-md": "on"}), "AGENTS.md": "# Rules\n"})
        out = io.StringIO()
        with contextlib.redirect_stdout(out), self.assertRaises(SystemExit):
            r.check(d)
        self.assertIn("verification: 0 on, empty", out.getvalue())
        self.assertIn("prose: 1 on", out.getvalue())


class Checks(unittest.TestCase):
    def test_yaml_catches_colon_in_frontmatter(self):
        d = repo({"skills/x/SKILL.md": "---\nname: x\ndescription: One thing: another.\n---\n"})
        ok, why = r.c_yaml(d, r.load_config(d))
        self.assertFalse(ok)
        self.assertIn("SKILL.md", why)

    def test_secrets_named_not_printed(self):
        key = "AKIA" + "ABCDEFGHIJKLMNOP"
        d = repo({".env": "TOKEN=x\n", "src/a.ts": f"const k = '{key}'\n"})
        ok, why = r.c_no_secrets(d, r.load_config(d))
        self.assertFalse(ok)
        self.assertIn(".env", why)
        self.assertIn("src/a.ts", why)
        self.assertNotIn(key, why)

    def test_strict_through_extends(self):
        d = repo({"tsconfig.json": '{"extends": "./base.json", // base holds it\n "compilerOptions": {}}', "base.json": '{"compilerOptions": {"strict": true,}}'})
        self.assertTrue(r.c_strict_types(d, r.load_config(d))[0])

    def test_pre_commit_must_run_both(self):
        d = repo({r.CONFIG: "commands:\n  typecheck: echo types\n  lint: echo lint\n"})
        hook = Path(d, ".git", "hooks", "pre-commit")
        hook.write_text("#!/bin/sh\necho types\n")
        hook.chmod(0o755)
        self.assertFalse(r.c_pre_commit(d, r.load_config(d))[0])
        hook.write_text("#!/bin/sh\necho types && echo lint\n")
        self.assertTrue(r.c_pre_commit(d, r.load_config(d))[0])

    def test_wired_but_failing_tests_fail(self):
        d = repo({r.CONFIG: "commands:\n  test: exit 3\n"})
        hook = Path(d, ".git", "hooks", "pre-push")
        hook.write_text("#!/bin/sh\nexit 3\n")
        hook.chmod(0o755)
        ok, why = r.c_tests_before_merge(d, r.load_config(d))
        self.assertFalse(ok)
        self.assertIn("fails", why)

    def test_verify_wired_and_passing(self):
        d = repo({r.CONFIG: "commands:\n  verify: exit 0\n"})
        self.assertFalse(r.c_verify(d, r.load_config(d))[0])
        hook = Path(d, ".git", "hooks", "pre-push")
        hook.write_text("#!/bin/sh\nexit 0\n")
        hook.chmod(0o755)
        self.assertTrue(r.c_verify(d, r.load_config(d))[0])
        Path(d, r.CONFIG).write_text("commands:\n  verify: exit 4\n")
        hook.write_text("#!/bin/sh\nexit 4\n")
        ok, why = r.c_verify(d, r.load_config(d))
        self.assertFalse(ok)
        self.assertIn("fails", why)

    def test_format_detected_and_wired(self):
        d = repo({"package.json": '{"scripts": {}, "devDependencies": {"oxfmt": "1"}}', "pnpm-lock.yaml": ""})
        self.assertEqual(r.detect_commands(d)["format"], "pnpm exec oxfmt --check .")
        Path(d, r.CONFIG).parent.mkdir(parents=True, exist_ok=True)
        Path(d, r.CONFIG).write_text("commands:\n  format: exit 0\n")
        self.assertFalse(r.c_format(d, r.load_config(d))[0])
        hook = Path(d, ".git", "hooks", "pre-commit")
        hook.write_text("#!/bin/sh\nexit 0\n")
        hook.chmod(0o755)
        self.assertTrue(r.c_format(d, r.load_config(d))[0])


class Friction(unittest.TestCase):
    TRAIL = Path(__file__).resolve().parents[2] / "skills" / "trail" / "trail.sh"

    def setUp(self):
        os.environ["XDG_STATE_HOME"] = tempfile.mkdtemp()

    def log(self, d, *args):
        subprocess.run([str(self.TRAIL), *args], cwd=d, check=True, capture_output=True)

    def test_repeats_rank_first_and_worktrees_share_the_log(self):
        d = repo({"AGENTS.md": "# Rules\n"})
        self.log(d, "friction", "slow-docs", "README wrong", "stale", "README.md:3", "30")
        wt = Path(tempfile.mkdtemp()) / "wt"
        subprocess.run(["git", "worktree", "add", "-q", str(wt)], cwd=d, check=True)
        for _ in range(2):
            self.log(wt, "friction", "test-env", "tests need\tDB_URL", "undocumented", "package.json:5", "10", "a .env.example")
        self.log(d, "decision", "dates", "ISO strings", "readable", "src/note.ts:1")
        ranked = r.rank(r.trail_rows(d))
        self.assertTrue(ranked[0].startswith("test-env: score 40 (2x, 20 min); fix: a .env.example"))
        self.assertTrue(ranked[1].startswith("slow-docs: score 30"))
        self.assertEqual(len(ranked), 2)

    def test_diff_reports_only_new_friction(self):
        d = repo({r.CONFIG: config({"agents-md": "on"}), "AGENTS.md": "# Rules\n"})
        self.log(d, "friction", "test-env", "x", "y", "a:1", "5")
        self.assertTrue(any(c.startswith("friction: test-env: score 5") for c in r.diff(d)))
        self.assertEqual(r.diff(d), [])

    def test_init_proposes_the_agents_line(self):
        import contextlib, io
        d = repo({"AGENTS.md": "# Rules\n"})
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            r.init(d)
        self.assertIn(r.AGENTS_LINE, out.getvalue())


if __name__ == "__main__":
    unittest.main()

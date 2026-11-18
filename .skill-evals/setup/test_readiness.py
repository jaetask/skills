"""Pins the checker's promises. Run: uv run --with pyyaml python .skill-evals/setup/test_readiness.py"""
import importlib.util
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SKILL = Path(__file__).resolve().parents[2] / "skills" / "setup" / "readiness.py"
spec = importlib.util.spec_from_file_location("readiness", SKILL)
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
        d = repo({"readiness.yml": config({"agents-md": "on"})})
        self.assertTrue(any(c.startswith("failing: agents-md") for c in r.diff(d)))
        self.assertEqual([c for c in r.diff(d) if not c.startswith("suggestion")], [])

    def test_fixed_then_broken(self):
        d = repo({"readiness.yml": config({"agents-md": "on"})})
        r.diff(d)
        Path(d, "AGENTS.md").write_text("# Rules\n")
        self.assertIn("newly passing: agents-md", r.diff(d))
        Path(d, "AGENTS.md").unlink()
        self.assertTrue(any(c.startswith("newly failing: agents-md") for c in r.diff(d)))

    def test_suggestion_once_and_dismissed_never(self):
        d = repo({"readiness.yml": config({"agents-md": "on"}, dismissed=["yaml"])})
        first = r.diff(d)
        self.assertIn("suggestion: turn on lockfile: " + r.CHECKS["lockfile"], first)
        self.assertFalse(any("turn on yaml" in c for c in first))
        self.assertFalse(any(c.startswith("suggestion") for c in r.diff(d)))

    def test_disappeared_check(self):
        d = repo({"readiness.yml": config({"agents-md": "on", "lockfile": "on"})})
        r.diff(d)
        Path(d, "readiness.yml").write_text(config({"agents-md": "on"}))
        self.assertIn("no longer checked: lockfile", r.diff(d))

    def test_never_edits_the_repo(self):
        d = repo({"readiness.yml": config({k: "on" for k in r.CHECKS}), "package.json": '{"scripts": {}}'})
        r.diff(d)
        self.assertEqual(subprocess.run(["git", "status", "--porcelain"], cwd=d, capture_output=True, text=True).stdout, "")


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
        d = repo({"readiness.yml": "commands:\n  typecheck: echo types\n  lint: echo lint\n"})
        hook = Path(d, ".git", "hooks", "pre-commit")
        hook.write_text("#!/bin/sh\necho types\n")
        hook.chmod(0o755)
        self.assertFalse(r.c_pre_commit(d, r.load_config(d))[0])
        hook.write_text("#!/bin/sh\necho types && echo lint\n")
        self.assertTrue(r.c_pre_commit(d, r.load_config(d))[0])

    def test_wired_but_failing_tests_fail(self):
        d = repo({"readiness.yml": "commands:\n  test: exit 3\n"})
        hook = Path(d, ".git", "hooks", "pre-push")
        hook.write_text("#!/bin/sh\nexit 3\n")
        hook.chmod(0o755)
        ok, why = r.c_tests_before_merge(d, r.load_config(d))
        self.assertFalse(ok)
        self.assertIn("fails", why)


if __name__ == "__main__":
    unittest.main()

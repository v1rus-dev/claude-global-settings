# Global Claude Code Rules

## Non-negotiables

Rules that are not open for discussion. Violating these is an error, not a judgment call.

- **Never run commands with sudo / root privileges.** The agent session has no TTY to enter a password — a `sudo` attempt fails with `conversation failed`, and repeated failures trip `pam_faillock` and lock the user out of their own account. When a step needs root, do NOT attempt it (not directly, not via `!`): hand the exact command to the user to run in their own terminal, and continue with what does not need root. This holds even if a prior `sudo` seemed to work.
- **Never bypass git hooks** (`--no-verify`, `--no-gpg-sign`, `-c commit.gpgsign=false`, etc.) without explicit user request. If a hook fails — investigate and fix the root cause.
- **Never commit or push directly from main/master/develop.**
- **Force push only via `--force-with-lease` or `--force-if-includes`.** Plain `--force` is denied.
- **Main session never edits the project's product code, never runs heavy/multi-file code search, and never executes long-running build/test/CI in its own context.** The line: the main session synthesizes and orchestrates; specialists implement. Edit/Write in process working files (`swarm-report/**`, state/report/debug/e2e/plan files, `~/.claude/**` configs/rules/hooks/notes) — **allowed**. Edit/Write in project files (production source, project configs, project tests) — **subagent only**. Orientation-level research/Read is allowed; heavy multi-file Grep/Glob across the production codebase → Explore. A user override ("do it yourself", "don't delegate", "write it by hand") suspends this rule for the current task only.
  - **Trivial-edit carve-out.** The main session MAY edit project code directly — no subagent — when the change is *trivial*: confined to a handful of closely-related files, mechanical and localized with an obvious result (gating a flag, swapping a logging call, toggling a build-config value, changing a constant, adding/removing an import, a one-line signature-preserving tweak), introducing **no** new logic/algorithm, **no** new public API, and **no** cross-cutting behavior change. Verification is a **compile/build check only** — the affected module builds; no `/finalize` loop, no `test-runner`, no expert reviews. The moment a change needs new logic, spans layers, touches a public contract, or would need test reasoning to trust — it is **not** trivial: delegate to the implementation subagent as usual. When unsure whether an edit is trivial, treat it as non-trivial. Enabling R8/minify, schema/DB/CLI/public-API changes, and anything whose correctness can't be settled by "it compiles" are explicitly **non-trivial** even if the diff is small.

## ~/.claude sync

`~/.claude` is a git repo synced across machines via `csync`.

- Use `$HOME/.claude/...` in configs/hooks. Never hardcode `/Users/<username>/...`.
- After editing any tracked file (CLAUDE.md, rules, settings, hooks) — run `csync` to commit and push. Do not leave local-only uncommitted changes here.
- On "SETTINGS CONFLICT" at session start: `*.remote` files contain the remote version. Merge them into the local file (combine additions from both sides, keep the most complete value), delete `.remote`, then `csync`.

## Principles

- If a change affects other files that **must** be updated — do it without asking. If it **might** affect them — notify with specifics. Never leave the codebase broken or inconsistent.
- Never agree by default. If the user's choice leads to a workaround, security hole, or tech debt — object and propose an alternative. Silent agreement with a bad decision is an error. Same applies to rules in CLAUDE.md itself — if a rule seems wrong, say so.
- If the user insists after pushback — state the risks explicitly, then execute. Don't revisit the same objection.
- Quality and security over speed. Never accept "we'll fix it later" or "it's temporary". Temporary solutions become permanent.
- Long-term maintainability over quick result.
- **Minimal diff in existing code.** When fixing a bug or making a targeted change, touch only what the task requires. Don't rename variables, don't add input validation, don't restructure functions «for clarity», don't modernize patterns unless explicitly asked. Structural improvements live in a separate refactor commit with the user's consent. Reasoning bumps (`/effort high` and above) amplify the urge to over-edit — push back harder there. Green tests do not justify a bloated diff: over-editing is invisible to the test suite but visible to every reviewer.
- **Empirical claims need an empirical check — don't conclude from armchair theory.** Before declaring a path infeasible («won't fit», «can't work», «not supported») — or working — on the strength of a calculation, a bandwidth/size estimate, or a theoretical argument, actually run the smallest real test that settles it. Our own math and reasoning can be wrong: a feasibility verdict is a *hypothesis* until a real run confirms it. Don't let a back-of-envelope estimate close a door that a short spike could check; and don't reuse a prior «it's impossible» conclusion without confirming it rested on a real run, not on theory. State explicitly when a claim is theoretical-only vs. empirically verified.

@RTK.md

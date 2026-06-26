# Recommended Workflow

This file defines a **gate discipline** — *what* must be true before a task moves forward and *why* — independent of any specific tool. It is not a forced pipeline: pick what the task needs and let plan mode drive sequencing.

**Gates are abstract; closure is per-project.** Each gate below states an outcome that must hold. *How* it is closed depends on what the current project actually provides:

- **Project with a feature pipeline:** the pipeline's own phases close most gates internally (its confirmation gate, finalize + code-review loop, expert-reviews) by dispatching the global expert/engineer agents. Run the pipeline and let it drive; this file explains what those phases are *for*.
- **Project without a pipeline:** close each gate manually with the building blocks that exist — `/finalize`, `/code-review`, `/simplify`, `/security-review` skills; the `research` skill for unknowns; the `code-reviewer` / `security-expert` / `performance-expert` / `architecture-expert` / `ux-expert` / `build-engineer` review agents and `test-runner` (via the Agent tool); `gh` for PRs.

Never assume a named skill/command exists — verify against the session's available skills and the project's `.claude/`. A gate whose ideal tool is absent is still mandatory: close it with whatever the project has, and say which tool you used.

## Mandatory gates

**Preparation gate — before any implementation.** Gather, autonomously and research-first, what's needed to build *and* verify — three outputs, actually collected, not just named:
- **Sources of truth** (what "done" means): spec/AC, before-state baseline, screenshots/Figma, debug-repro. Actively *produce* them — snapshot the baseline before a migration (existing passing tests, or API/output snapshots). What you can't make yourself and is missing → ask the user, naming what verification degrades without it. Detail: [[qa-and-testing]] §6 + [[task-types]] § Before-state baseline. Starting implementation without the sources of truth needed to verify it is not allowed.
- **Knowledge sources** (how to build it): trusted docs/source per tier T1–T4 — see [[external-sources]]. Agent memory and project code go stale; on a gap or doubt, verify against the official source, don't act from memory. Missing understanding or stuck → research first (the `research` skill — parallel expert investigation of options/feasibility before implementation), not a question to the user.
- **Testability + decomposition**: assess how hard the change is to verify and propose simplifications up front (sample/sandbox app, extracting logic to a unit boundary) so a prototype is exercised fast; decompose a task too large for one plan. Detail: [[task-types]] § Test feasibility gate.

Autonomy: concentrate questions in this prep phase; once sources are gathered, proceed without round-tripping. A standard/obvious solution — apply it, don't ask. Skip prep only for the same trivial cases as the gates below.

In a project with a feature pipeline this gate is its requirements + architecture + **confirmation gate** phases (the pipeline pauses for plan approval and complexity scoring before any code). Outside one: do it in plan mode.

**Quality gate — `/finalize`.** Required after every implementation where code was written — before declaring the task done. `/finalize` owns *how the code is written*: a full **review → fix → simplify** loop that iterates until no findings above Minor severity remain, or exits with ESCALATE requiring a user decision. A standalone run of `code-reviewer` does **not** close this gate — review alone leaves the fix and simplify steps unperformed; «код уже отревьюен» is not grounds to skip it.
- *Pipeline project:* the pipeline runs the `/finalize` skill + `code-reviewer` (loops finalize → code-review until PASS, then dispatches expert reviews on escalation).
- *Otherwise:* run `/finalize` — it orchestrates the full review→fix→simplify loop.
- Exceptions (skip the gate): pure documentation edits, config-only changes with no logic, single-line mechanical changes with an obvious result.

**Acceptance gate — it works as intended.** Runs after the quality gate, before PR promotion. Verifies the implementation against the source of truth (spec, test plan, design, or behavioral baseline). Orthogonal to the quality gate: quality checks *how the code is written*, acceptance checks *what the code does* — neither replaces the other, both mandatory. Same exceptions as the quality gate.
- *Closure:* **automated verification only** — the `test-runner` agent runs the build + the relevant test tasks; the tests covering the acceptance criteria must pass. For non-UI changes, exercise the changed contract through a test rather than by hand.

**PR promotion gate.** Opening a **draft** PR is routine (no confirmation needed) — do it early. Promoting **draft → ready for review** requires explicit user confirmation: it signals the task is complete and makes it visible to reviewers — a shared-state action.
- *Closure:* `gh pr create --draft` to open, `gh pr ready` to promote. **Note:** a feature pipeline typically ends at branch commits + a report and never opens or pushes a PR — PR creation is always a manual step after it.

## Flows

**Non-trivial features:**
1. Plan mode → **preparation gate** (above): gather + collect sources of truth (spec, Figma, AC list, before-state baseline for migrations), confirm knowledge sources, assess testability and decompose. Research-first for unknowns. In a project with a feature pipeline, its entry command drives this (requirements → architecture → confirmation gate); the confirmation gate is where you review the plan and complexity before code.
2. Implement on a `feature/*` branch. Open a draft PR early (`gh pr create --draft`).
3. **Quality gate** (`/finalize`) → **acceptance gate** (`test-runner`: build + tests against the AC) → promote PR to ready (user confirmation required) → drive to merge.

**Bug fixes:**
1. Plan mode (debug + fix in the plan). Capture reproduction steps in `swarm-report/<slug>-debug.md` — this is the source of truth for acceptance.
2. Write a failing test that reproduces the bug first, then implement the fix (red-green) → **quality gate** → **acceptance gate** (the regression test + suite pass via `test-runner`) → PR. The regression test is not optional unless the feasibility gate applies — then a tracked exception, never a silent skip (see [[task-types]] bug-fix row + [[qa-and-testing]] §4).

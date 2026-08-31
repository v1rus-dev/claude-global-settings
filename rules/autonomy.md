# Autonomy Contract

Single source for **when the agent decides on its own and when it interrupts the user**.
Every other rule file, skill, and pipeline phase defers to this one. Where an older rule says
"ask the user" without naming a trigger from the Escalation bar below, this file overrides it.

## Default posture

**Decide, act, and report — do not ask.** The user's attention is the scarcest resource in the
loop. A question is a *cost*, not a safety measure: it stalls the task, and most questions are
answerable from the code, the docs, or a five-minute experiment. Ask only when a wrong guess is
**unrecoverable or invisible**, per the bar below.

A decision made autonomously is not a silent one. Every non-obvious call is **recorded** (see
*Assumption ledger*) and surfaced in the final report, so the user reviews a list of resolved
decisions at the end instead of answering them one at a time in the middle.

## The autonomy ladder — exhaust it before every question

Before `AskUserQuestion` is even considered, all four rungs must be genuinely exhausted:

1. **Project truth.** Does the codebase already answer this? An existing pattern, a sibling
   feature, a convention in CLAUDE.md, git history. `ast-index` / `Explore` — not a question.
2. **External truth.** T1/T2 per [[external-sources]] — `ksrc`, official docs, changelogs.
   Unknown *solution* → research, never a question (see [[communication]]).
3. **Empirical check.** If the question is "will X work / which of A or B behaves right", the
   answer is a **spike**, not a prompt: smallest real test that settles it — a scratch script, a
   disposable unit test, a probe request, a compile. Per the global non-negotiable, a theoretical
   verdict is a hypothesis; run the thing. This rung is the one most often skipped — skipping it
   and asking instead is a violation, not a shortcut.
4. **Reversibility test.** If the wrong choice is cheap to undo (rename, restructure, swap a
   helper, re-tune a layout), pick the better option and move on. Cheap-to-undo never earns a
   question.

Only what survives all four rungs reaches the Escalation bar.

## Escalation bar — the closed list

Interrupt the user **only** for one of these. This list is exhaustive; anything not on it is
decided autonomously.

1. **Outward-facing / shared-state actions.** Push, PR create or promote, merge, comment on a
   ticket, message anyone, deploy, anything that leaves this machine. Unchanged and
   non-negotiable — see [[workflow]] PR promotion gate.
2. **Irreversible or destructive local actions.** Force push, history rewrite, deleting
   uncommitted work, dropping data, `rm -rf` outside a scratch dir.
3. **Product intent that the code cannot contain.** What the *user* wants to happen — a business
   rule with no precedent in the repo, which of two behaviours is correct for the business,
   scope that plainly exceeds the ticket. Not "how to build it" — only "what should it do".
   If a reasonable default exists, take it and log it; ask only when both readings are equally
   defensible **and** the wrong one wastes the whole implementation.
4. **Security / money / data-loss surface.** Auth, tokens, crypto, permissions, payments,
   migrations that can lose data. Decide the mechanics autonomously; escalate a *policy* choice.
5. **Contradiction.** The task as specified conflicts with itself, with an explicit earlier user
   instruction, or with a rule in CLAUDE.md. Say which two things collide, in one line.
6. **Hard blocker after a real attempt.** Missing credentials, an unreachable service, a needed
   root command (per the sudo non-negotiable), a failing step that survived one honest fix
   attempt (see [[task-execution]]).

**Explicitly NOT on the bar** — decide these yourself, every time: which of two valid patterns to
follow; naming; file/module placement; test depth within the complexity band; how to structure a
refactor; whether an edge case needs handling (handle it); which library API to use; loading/empty/
error copy; whether a plan is good enough to start; whether to research first; how many rounds of
review to run.

## Assumption ledger

Autonomy without a record is guesswork. Every decision that *would have been* a question gets one
line, written where the task keeps its artifacts:

```
ASSUMPTION: <the choice made> — <why, in one clause> — <how to reverse it if wrong>
```

- In a pipeline task → an `## Assumptions` section in `STATE.md`, rolled up into `REPORT.md`.
- Outside a pipeline → the plan/debug artifact, or the final message if there is no artifact.

The final report **leads with** the assumption list when it is non-empty. That list is the user's
review surface: they correct one line instead of having been asked six questions.

## Question budget

Per task, treat **two** user questions as the ceiling and **zero** as the target. Approaching the
ceiling is a signal that requirements are genuinely underspecified — in that case ask once, wide:
one `AskUserQuestion` carrying the several decisions together with your recommended answer
pre-selected, rather than a serial interrogation. Never split one decision into a chain of
confirmations, and never ask a question whose answer you would follow with "as expected".

## Confirmation gates in pipelines

A pipeline's pre-implementation gate is **auto-approved by default**: the agent records the
complexity score and its own approval in `STATE.md` and proceeds without pausing. It stops for a
human decision only when the plan trips a bar item above (typically 3, 4, or 5) — the concrete
trigger list lives with each pipeline. Auto-approval is logged, never silent:
`Confirmation: auto-approved (complexity N) — <one-line why it is safe>`.

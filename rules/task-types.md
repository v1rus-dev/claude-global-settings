# Task Type Routing

Routing matrix: task type → verification source of truth + testing pyramid target + when to write tests.

## Test feasibility gate

Tests are written when **both** conditions hold:
1. The coverage approach is clear — there is a natural test boundary for the behavior (pure function, API contract).
2. The effort is within reasonable budget relative to the task — writing the test does not cost more than the change itself for simple cases, and does not require building test infrastructure from scratch.

When either condition is not met — document the reason in the plan and proceed without tests for that scope. "Not obvious how to test" and "setup cost is prohibitive" are valid; "didn't feel like it" is not.

This gate governs **discretionary** scope — which pyramid levels, internal/non-public behavior. It does **not** override the public-API floor: a modified **public** symbol still must satisfy [[qa-and-testing]] §1 (exercised by a test, or annotated trivial). When test cost is genuinely prohibitive on a public symbol, route it to a **tracked exception** (the [[qa-and-testing]] §4 `@Ignore`-with-issue pattern) — the gap stays explicit and tracked, never a silent documented skip.

### Testability assessment & simplifications (at planning time)

Don't only decide *whether* to test — assess how hard verification will be and lower that cost **before** implementation (this is part of the preparation gate — see [[workflow]]):

- Surface hard to drive (deep in a flow, needs a real backend, slow to reach) → build a **sample / sandbox app** or harness that exercises the changed behavior in isolation; prototype and debug there first, then port to the real app. Re-debugging only in the real app is the slow path.
- Lower verification cost by extracting the changed logic to a **unit / integration boundary** (pure function, API contract) rather than driving it through the UI.
- Temporary simplifications that make a verifiable prototype reachable sooner are valid (see [[qa-and-testing]] § Disposable verification tests) — but remove or harden them before `/finalize`.

The goal is the cheapest path to a *verifiable* prototype, not to defer testing. Decide the simplifications and what to collect (test baselines, sample data) here, at planning — not mid-implementation.

## Routing matrix

| Task type | Source of truth | Min pyramid | Write tests | Special |
|---|---|---|---|---|
| Feature | Spec / test plan / AC list | L1–L2 | After implementation; before if AC are clear (TDD) | — |
| Bug fix | `swarm-report/<slug>-debug.md` — reproduction steps | L1–L2 | **Before fix** — write a failing test first, then fix | Red-green: test proves bug exists, then proves it's gone |
| Tech migration | Before-state baseline | L1–L2 | Before migration — establish test coverage of migrated behavior as part of baseline | Capture before-state first |
| Library version bump | Before-state baseline | L1–L2 | Verify existing tests pass; add where coverage gaps found | Capture before-state if tests absent |
| Refactoring | Before-state baseline (tests as proxy if they exist) | L1–L2 | Before refactor if coverage gaps exist | Behavior must be 1:1 with before-state |
| Infrastructure change (network / storage / auth / DI) | Spec / requirements | L1–L2 | After implementation | — |
| UI / design task | Figma / screenshots | L0–L1 | — | Visual match reviewed **manually** against the mockup |
| Performance optimization | Benchmark baseline — before/after numbers | L0–L2 where measurable | Capture baseline before; measure delta after | Win must be a measurable delta |
| Investigation / research | Research output document | L1 only if code produced | N/A when no code changes | No pyramid when no code is written |

**L0 (Build) is the implicit entry gate for every row** — the affected part (relevant app/module, not always the whole repo) must compile before any L1+ level runs. The "Min pyramid" column lists levels *above* L0; it never repeals it. No code change → no L0 (e.g. research). **Whether tests are written at all is set by the complexity band: only from complexity 7** (see [[qa-and-testing]] §0). Below 7 the row's L2 / "Write tests" cell is dormant — verification is build + static analysis + the quality gate. The "Write tests" column describes the *timing* (TDD / red-green / baseline-first) for when the band does call for tests.

## Before-state baseline

A durable snapshot of the system's current behavior, created **before any changes**, detailed enough to verify the modified system behaves identically.

### What qualifies

1. **Passing tests cover the behavior being changed** → the test suite IS the baseline. No additional capture needed — green before = spec for after.
2. **No test coverage** → capture a baseline before starting:
   - API / backend: response shape snapshots for affected endpoints, saved to `swarm-report/<slug>-baseline.md`.
   - Pure logic: input → output pairs for the behavior being changed.
   - When capturing a direct baseline isn't practical, prefer the test-coverage shortcut below (write tests first).

**Shortcut:** establishing test coverage of the migrated behavior before the migration satisfies both the baseline requirement and the `/write-tests` step in one move.

**Sufficiency check:** "Could I hand this baseline to someone who has never seen this system and have them verify the migration succeeded?" If yes — the baseline is sufficient.

### What is not a baseline

- "It should be fine" — not a baseline.
- Code review or static analysis of the change — these check intent, not actual behavior.
- A passing build — proves compilation, not behavior.

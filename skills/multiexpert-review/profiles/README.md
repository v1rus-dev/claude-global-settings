# multiexpert-review profiles

Artifact-specific configuration the engine (`../SKILL.md`) loads at runtime. The engine is
artifact-agnostic — every per-artifact rule lives in a profile here. One file per profile,
`<name>.md`: YAML frontmatter for the structured config the engine reads as `profile.<field>`,
plus a single `## Prompt augmentation` body section.

## Inventory

Canonical list of valid profiles. The engine cross-checks this list against the `*.md` files
actually present in this directory (excluding `README.md`); any disagreement is
`PROFILE_INVENTORY_MISMATCH`.

- `implementation-plan` — implementation plans produced by `write-plan` (`docs/plans/<slug>/plan.md`).

> Roadmap (NOT yet present — a caller passing one of these hints gets `UNKNOWN_PROFILE_HINT` until
> the file is added): `spec` (write-spec), `test-plan` (generate-test-plan). Add them as separate
> profiles when those callers are wired up; do not list them above until the file exists.

## Detection precedence (canonical)

Engine Step 1 resolves the profile in this order; first match wins; record the source. Profile is
**locked at cycle 1** — re-reviews (cycle ≥2) reuse the locked profile and MUST NOT re-detect.

1. **Caller hint** — args begin with `profile: <name>` on the first line(s) before a `---`
   separator. If `<name>` is not in the Inventory → `UNKNOWN_PROFILE_HINT`, stop. Never fall back
   to a default silently.
2. **Artifact frontmatter** — a `type:` field maps to a profile: `plan` → `implementation-plan`
   (`spec` → `spec`, `test-plan` → `test-plan` once those exist).
3. **Path signature** — `docs/plans/**/plan.md` → `implementation-plan`
   (`docs/specs/**` → `spec`, `docs/testplans/**` → `test-plan`).
4. **Content signature** — a `## Technical Approach` heading plus an ordered task list →
   `implementation-plan`.
5. **Ask the user** — only when 1–4 all fail.

## Profile schema — allowed frontmatter

Everything a profile MAY declare:

- `profile` — the name; MUST equal the filename stem and an Inventory entry.
- `artifact_type` — human label substituted into the engine's prompt skeleton (`{artifact_type}`).
- `verdicts` — the verdict alphabet, an ordered subset of `[PASS, CONDITIONAL, WARN, FAIL]`.
- `allow_single_reviewer` — bool; governs the engine's single-reviewer guard.
- `reviewer_roster` — `{ primary: [...], optional_if: [{ agent, when }] }`. `when` is a regex matched
  against the artifact text. Empty `primary` + no `optional_if` match → engine falls back to
  tech-match selection.
- `severity_mapping` — OPTIONAL; only for checklist-style profiles (e.g. test-plan items a–e).
- `receipt` — OPTIONAL; `{ path_template, fields_to_update: [...] }`. `<slug>` is substituted.
- `source_routing` — `{ file, plan_mode, conversation }`, each an action or `N/A`.

Plus exactly one body section: `## Prompt augmentation` (substituted into the review prompt as
`{PROFILE_PROMPT_AUGMENTATION}`; never replaces the engine skeleton).

## Forbidden fields (negative-list)

These are engine constants. A profile declaring ANY of them → `FORBIDDEN_PROFILE_FIELD: <first
offending key>`, stop. Forbidden keys: `verdict_format`, `review_output`, `aggregation`,
`aggregation_rules`, `cycle_cap`, `revise_loop_cap`, `state_machine`, `transitions`,
`review_prompt`, `prompt_skeleton`. (Review output structure, aggregation rules, the 3-cycle cap,
the state machine, and the prompt skeleton are fixed in the engine — a profile extends behavior
ONLY through `reviewer_roster` / `verdicts` / `receipt` / `source_routing` / `## Prompt
augmentation`.)

## Validation — runs on every invocation, before Step 2

1. Resolved profile name is in the Inventory AND its file is present
   (else `UNKNOWN_PROFILE_HINT` or `PROFILE_INVENTORY_MISMATCH`).
2. Frontmatter contains no forbidden field (`FORBIDDEN_PROFILE_FIELD`).
3. `profile` stem == filename == Inventory entry; short-name reviewer collisions resolved per the
   engine's family tie-break (`AMBIGUOUS_REVIEWER` on a genuine clash).

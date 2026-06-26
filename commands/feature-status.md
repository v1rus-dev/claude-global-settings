---
description: List all pipeline tasks (features, bugs, reviews, migrations) and their progress
argument-hint: [optional slug or type filter]
---

You report the status of pipeline work. This command is **read-only**: do not edit, commit, or
spawn implementation subagents. Optional filter: **$ARGUMENTS** (a `<slug>` substring, or a type
like `feature` / `bug` / `review` / `migration`).

**Language:** Default to **Russian** unless `$ARGUMENTS` clearly indicates another language.

## Steps

1. Enumerate every task directory: `.claude/tasks/<type>/<slug>/`. Look for a `STATE.md` in each
   (some review tasks may only have a report — include them too).
2. For each task, read its `STATE.md` and extract: **Feature/Bug title**, **Mode/type**,
   **Branch**, **Current phase**, **Complexity**, and the **checklist** (count ticked vs. total,
   and the first unchecked item = the next phase). Note any entries in the **Notes** section that
   look like blockers/escalations.
3. If `$ARGUMENTS` is given, filter to matching type or slug.

## Output

Group by type and present a compact table per group (skip empty groups):

```
## feature
| slug | title | branch | phase (done/total) | next | complexity | blocker |
|------|-------|--------|--------------------|------|-----------|---------|
| mms-123 | … | feature/mms-123 | 7/12 | development | 4 | — |

## bug
| … |
```

After the tables:
- Flag any task whose branch ≠ the current git branch (so the user knows a checkout is needed to
  resume).
- For each unfinished task, state the one command to resume it: `/feature <slug>` (feature),
  `/bugfix <slug>` (bug), `/review <target>` (review), or the relevant migration command.
- One line summarizing how many tasks are complete vs. in-progress.

Keep it terse — this is a dashboard, not a narrative.

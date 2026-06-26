#!/bin/bash
# Auto-PULL ~/.claude on session start: fetch + rebase remote changes into the local tree.
#
# Pull-only by design: this hook NEVER commits and NEVER pushes. It only brings remote
# changes down so every session starts on the latest config. Local uncommitted edits are
# preserved across the pull via --autostash (stashed before the rebase, re-applied after);
# any local commits are replayed on top of remote but stay local until you run `csync`.
#
# Core invariant: NEVER fail silently. Every non-OK outcome is recorded loudly via three
# channels — ~/.claude/.sync-status (rendered in the statusline on every prompt), an OS
# notification on hard failures, and stdout (which Claude relays). The hook always exits 0
# so it can never break a Claude Code session, but it never stays silent about a problem.

set -uo pipefail

REPO="$HOME/.claude"
STATUS="$REPO/.sync-status"

cd "$REPO" 2>/dev/null || exit 0

# Recursion guard: a `claude -p` spawned by csync's conflict resolver must not re-enter sync
# (its own SessionStart would trigger this hook again). csync exports CLAUDE_SYNC_ACTIVE=1.
[ -n "${CLAUDE_SYNC_ACTIVE:-}" ] && exit 0

git rev-parse --git-dir >/dev/null 2>&1 || exit 0
git remote get-url origin >/dev/null 2>&1 || exit 0

# --- loud channel helpers ---
note()  { printf '[claude-sync] %s\n' "$*"; }           # info -> stdout (Claude relays)
warn()  { printf '%s' "$*" > "$STATUS"; printf '⚠ ~/.claude: %s\n' "$*"; }  # soft -> statusline + stdout
alarm() {                                                # hard -> statusline + OS notif + stdout
  printf '%s' "$*" > "$STATUS"
  if command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"$*\" with title \"~/.claude sync\"" >/dev/null 2>&1 || true
  fi
  printf '⚠ ~/.claude: %s\n' "$*"
}
clear_status() { rm -f "$STATUS" 2>/dev/null || true; } # OK -> clear warning

# Clean up stale rebase state from a previous crash
if [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ]; then
  git rebase --abort 2>/dev/null || true
fi

# Fetch — offline is a loud (soft) state, not a silent skip
if ! git fetch --quiet origin 2>/dev/null; then
  warn "offline — not pulled"
  exit 0
fi

UPSTREAM=$(git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null || echo origin/main)
BEHIND=$(git rev-list --count "HEAD..$UPSTREAM" 2>/dev/null || echo 0)

# Already up to date — nothing to pull
if [ "$BEHIND" -eq 0 ]; then
  clear_status
  exit 0
fi

# Behind remote — rebase incoming changes in. --autostash keeps any local uncommitted edits
# (stashed and re-applied around the rebase); local commits are replayed but never pushed.
if git rebase --autostash --quiet "$UPSTREAM" 2>/dev/null; then
  clear_status
  note "pulled $BEHIND from remote"
else
  git rebase --abort 2>/dev/null || true
  # Save remote versions of conflicting files for manual merge (see CLAUDE.md "SETTINGS CONFLICT").
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    git show "$UPSTREAM:$f" > "$REPO/$f.remote" 2>/dev/null || true
  done < <(git diff --name-only HEAD "$UPSTREAM" 2>/dev/null)
  alarm "pull conflict — remote saved as *.remote; merge them and run csync"
  exit 0
fi

exit 0

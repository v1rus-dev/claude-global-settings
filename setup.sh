#!/bin/bash
set -euo pipefail

REPO="https://github.com/v1rus-dev/claude-global-settings.git"
CLAUDE_DIR="$HOME/.claude"

add_csync_alias() {
  local rc=""
  case "${SHELL:-}" in
    */zsh)  rc="$HOME/.zshrc" ;;
    */bash) rc="$HOME/.bashrc" ;;
    *)
      echo "Add this alias to your shell profile manually:"
      echo '  alias csync="$HOME/.claude/hooks/sync-settings.sh"'
      return ;;
  esac
  if ! grep -q 'alias csync=' "$rc" 2>/dev/null; then
    echo 'alias csync="$HOME/.claude/hooks/sync-settings.sh"' >> "$rc"
    echo "Added csync alias to $rc. Run: source $rc"
  fi
}

# Register the structural JSON merge driver in this clone's .git/config.
# .git/config is per-clone and never synced, so every machine must register it itself.
# Referenced by .gitattributes (settings.json merge=json). Idempotent.
register_merge_driver() {
  git -C "$CLAUDE_DIR" config merge.json.name "structural 3-way JSON merge"
  git -C "$CLAUDE_DIR" config merge.json.driver \
    'python3 $HOME/.claude/hooks/json-3way-merge.py %O %A %B'
}

# Materialize plugins declared in settings.json onto this machine.
# settings.json (tracked in git) is the single source of truth: `extraKnownMarketplaces`
# lists marketplaces by github repo and `enabledPlugins` lists plugin@marketplace — both
# path-free. The plugins/ cache is NOT tracked (it embeds absolute $HOME paths) and is
# regenerated here. On a fresh machine Claude Code would otherwise only PROMPT to install
# these; this makes bootstrap deterministic and non-interactive.
# Idempotent: skips marketplaces/plugins already present. Needs the `claude` CLI + python3.
install_plugins() {
  local settings="$CLAUDE_DIR/settings.json"
  command -v claude >/dev/null 2>&1   || { echo "Skipping plugins: 'claude' not on PATH."; return; }
  command -v python3 >/dev/null 2>&1  || { echo "Skipping plugins: python3 needed to read settings.json."; return; }
  [ -f "$settings" ]                  || { echo "Skipping plugins: no settings.json."; return; }

  local have_markets have_plugins name repo plugin
  have_markets="$(claude plugin marketplace list 2>/dev/null || true)"
  while read -r name repo; do
    [ -z "$name" ] && continue
    grep -q "$name" <<<"$have_markets" \
      && echo "  marketplace $name: present" \
      || { echo "  marketplace $name: adding ($repo)"; claude plugin marketplace add "$repo"; }
  done < <(python3 - "$settings" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
for name,m in (d.get("extraKnownMarketplaces") or {}).items():
    s=m.get("source",{})
    if s.get("source")=="github" and s.get("repo"):
        print(name, s["repo"])
PY
)

  have_plugins="$(claude plugin list 2>/dev/null || true)"
  while read -r plugin; do
    [ -z "$plugin" ] && continue
    name="${plugin%@*}"
    grep -q "$name" <<<"$have_plugins" \
      && echo "  plugin $name: present" \
      || { echo "  plugin $plugin: installing"; claude plugin install "$plugin"; }
  done < <(python3 - "$settings" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
for p,enabled in (d.get("enabledPlugins") or {}).items():
    if enabled: print(p)
PY
)
}

echo "=== Claude Code Global Settings Setup ==="

# --- Already set up ---
if [ -d "$CLAUDE_DIR/.git" ]; then
  echo "Already configured. Pulling latest..."
  if ! git -C "$CLAUDE_DIR" pull --rebase; then
    echo "Pull failed. Try: cd ~/.claude && git rebase --abort && git pull --rebase"
    exit 1
  fi
  register_merge_driver
  add_csync_alias
  echo "Ensuring plugins..."
  install_plugins
  echo "Done."
  exit 0
fi

# --- New machine ---
if [ ! -d "$CLAUDE_DIR" ]; then
  echo "Cloning into ~/.claude ..."
  git clone "$REPO" "$CLAUDE_DIR"
  register_merge_driver
  add_csync_alias
  echo "Installing plugins..."
  install_plugins
  echo "Done. Run 'claude' to start."
  exit 0
fi

# --- Existing machine ---
echo "Found existing ~/.claude. Backing up..."

BACKUP_DIR="$HOME/.claude-backup-$(date +%Y%m%d-%H%M%S)"
cp -a "$CLAUDE_DIR" "$BACKUP_DIR"
echo "Full backup saved to $BACKUP_DIR"

# Rollback on failure
cleanup_on_failure() {
  echo "Setup failed. Removing partial git state..."
  rm -rf "$CLAUDE_DIR/.git"
  echo "Your original files are intact. Backup at: $BACKUP_DIR"
}
trap cleanup_on_failure ERR

cd "$CLAUDE_DIR"
git init
git remote add origin "$REPO"
git fetch origin
git reset --hard origin/main
git branch -M main
git branch --set-upstream-to=origin/main main

register_merge_driver

trap - ERR

# Restore local-only files from backup
for f in .credentials.json settings.local.json mcp-needs-auth-cache.json; do
  [ -f "$BACKUP_DIR/$f" ] && cp "$BACKUP_DIR/$f" "$CLAUDE_DIR/"
done
[ -d "$BACKUP_DIR/channels" ] && cp -r "$BACKUP_DIR/channels" "$CLAUDE_DIR/"
[ -f "$BACKUP_DIR/plugins/installed_plugins.json" ] && cp "$BACKUP_DIR/plugins/installed_plugins.json" "$CLAUDE_DIR/plugins/"
[ -d "$BACKUP_DIR/plugins/cache" ] && cp -r "$BACKUP_DIR/plugins/cache" "$CLAUDE_DIR/plugins/"
[ -d "$BACKUP_DIR/plugins/data" ] && cp -r "$BACKUP_DIR/plugins/data" "$CLAUDE_DIR/plugins/"

add_csync_alias
echo "Ensuring plugins..."
install_plugins
echo ""
echo "Done. Backup at: $BACKUP_DIR"

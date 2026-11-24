# Settings for worktree-cleanup, sourced by every script.
# Defaults live here; your changes live in $LERD_PLUGIN_DATA/config.env,
# written by `lerd worktree-cleanup:config KEY=VALUE`.
#
# Format: KEY|default|type|description   (type: bool, action, int, duration, list)
SETTINGS_SPEC='REMOVE_MERGED|yes|bool|Remove a worktree whose PR was merged
REMOVE_CLOSED|yes|bool|Remove a worktree whose PR was closed without merging
REMOVE_ON_BASE|yes|bool|Remove a detached or no-PR worktree whose HEAD is already on a base branch
BASE_BRANCHES|main master staging develop|list|Branches (on origin) that count as "landed" for REMOVE_ON_BASE
MIN_AGE_HOURS|24|int|REMOVE_ON_BASE only: HEAD must be checked out this long, so a fresh worktree is not taken for a finished one
DIRTY_MERGED|remove|action|Uncommitted changes in a merged-PR worktree: remove (patch saved) or keep
DIRTY_CLOSED|remove|action|Uncommitted changes in a closed-PR worktree: remove (patch saved) or keep
DIRTY_ON_BASE|keep|action|Uncommitted changes in a detached/no-PR worktree on a base branch: remove (patch saved) or keep
SAVE_PATCH|yes|bool|Before removing a worktree with uncommitted changes, save them as a patch
SKIP_BUSY|yes|bool|Keep a worktree a process (shell, editor, AI session) is sitting in; lerd dev servers do not count
REQUIRE_IDLE|yes|bool|Keep a worktree lerd saw activity on within its idle timeout
DROP_DATABASE|yes|bool|Drop a worktree'"'"'s own database (lerd db:share) when removing it; no keeps the database
EXCLUDE_SITES||list|Site names never touched (space separated)
NOTIFY|yes|bool|Send a dashboard notification after a scheduled run removes something
SCHEDULE_EVERY|1h|duration|How often the scheduled cleanup acts, 15m or longer (e.g. 30m, 1h, 6h, 1d)'

CONFIG_FILE="${LERD_PLUGIN_DATA:-$HOME/.local/share/lerd/plugin-data/worktree-cleanup}/config.env"

# Load defaults, then the user's overrides.
# ponytail: defaults contain no single quotes, so plain '%s' quoting is enough.
eval "$(printf '%s\n' "$SETTINGS_SPEC" | awk -F'|' '{printf "%s=\047%s\047\n", $1, $2}')"
[ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE"

is_yes() { case "$1" in yes|true|1|on) return 0 ;; *) return 1 ;; esac; }

# "1h" -> 3600
to_seconds() {
  case "$1" in
    *d) echo $(( ${1%d} * 86400 )) ;; *h) echo $(( ${1%h} * 3600 )) ;;
    *m) echo $(( ${1%m} * 60 )) ;;    *s) echo "${1%s}" ;; *) echo "$1" ;;
  esac
}

# lerd's dashboard and schedules run plugins with a bare PATH (often just
# /usr/bin:/bin), so tools installed per user or by Homebrew/Linuxbrew/snap are
# not on it. Append the usual places; whatever PATH lerd passed still wins.
EXTRA_PATH_DIRS="${HOME:-}/.local/bin ${HOME:-}/bin /opt/homebrew/bin /usr/local/bin /home/linuxbrew/.linuxbrew/bin ${HOME:-}/.linuxbrew/bin /snap/bin"
for _d in $EXTRA_PATH_DIRS; do
  case ":$PATH:" in *":$_d:"*) ;; *) PATH="$PATH:$_d" ;; esac
done
export PATH

# How to install a missing tool on this OS.
install_hint() { # tool
  if [ "$(uname -s)" = Darwin ]; then
    case "$1" in gh|jq) echo "brew install $1" ;; *) echo "xcode-select --install" ;; esac
  else
    case "$1" in
      gh) echo "install gh (https://cli.github.com) into ~/.local/bin, /usr/local/bin or /usr/bin" ;;
      *) echo "install $1 with your package manager (apt, dnf, pacman...)" ;;
    esac
  fi
}

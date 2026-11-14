# Worktree cleanup

Every lerd worktree of a proxy site runs its own dev server (a file watcher),
and Laravel worktrees can carry their own database, so finished worktrees add
up fast. This plugin removes the ones whose work is finished, by hand or on a
schedule, following rules you choose.

## Where to use it

- **Dashboard:** the **Worktree cleanup** page on the rail has every setting as
  a toggle, the schedule, a tool check, **Preview** (dry run) and **Clean up now**.
- **A site's Commands menu:** **Clean up finished worktrees** for that site only.
- **Terminal:**

```
lerd worktree-cleanup:run                     # dry run: what would go and why
lerd worktree-cleanup:run --apply             # remove
lerd worktree-cleanup:run --apply my-app      # one site
lerd worktree-cleanup:config                  # show every setting
lerd worktree-cleanup:config DIRTY_CLOSED=keep MIN_AGE_HOURS=48
lerd worktree-cleanup:config reset [KEY...]
lerd worktree-cleanup:config check            # required tools and access
lerd worktree-cleanup:schedule on|off|status
```

- **AI assistants:** the `worktree-cleanup_run` tool (dry run first, then apply).

## Settings

Defaults are in `lib/settings.sh`; your changes are saved in `config.env` in the
plugin's data folder and kept across updates.

### What counts as finished

| Setting | Default | Meaning |
|---|---|---|
| `REMOVE_MERGED` | yes | The branch's PR (or the PR containing a detached HEAD) was merged |
| `REMOVE_CLOSED` | yes | The PR was closed without merging |
| `REMOVE_ON_BASE` | yes | Detached HEAD or a branch with no PR, whose HEAD is already on a base branch |
| `BASE_BRANCHES` | main master staging develop | Branches on `origin` that count for `REMOVE_ON_BASE` |
| `MIN_AGE_HOURS` | 24 | For `REMOVE_ON_BASE` only: HEAD must be this old. A brand-new worktree has no commits yet, so it is "on main" too |

### Uncommitted changes

| Setting | Default | Meaning |
|---|---|---|
| `DIRTY_MERGED` | remove | Merged PR with uncommitted changes: `remove` or `keep` |
| `DIRTY_CLOSED` | remove | Closed PR with uncommitted changes: `remove` or `keep` |
| `DIRTY_ON_BASE` | keep | Detached / no-PR on a base branch with uncommitted changes. Usually new work not yet committed, so kept by default |
| `SAVE_PATCH` | yes | Save uncommitted changes as `patches/<site>-<worktree>-<time>.patch` before removing. Restore with `git apply <patch>` |

### Safety

| Setting | Default | Meaning |
|---|---|---|
| `SKIP_BUSY` | yes | Keep a worktree a process (shell, editor, AI session) has as its working folder. lerd's own dev server doesn't count |
| `REQUIRE_IDLE` | yes | Keep a worktree lerd saw requests on within its idle timeout |
| `DROP_DATABASE` | yes | If the worktree's `.env` `DB_DATABASE` differs from the parent's, drop it with `lerd db:share` first. When lerd refuses (a database it doesn't manage), the worktree is kept and the reason shown |
| `LEFTOVER_FOLDERS` | yes | Delete folders in `.claude/worktrees/` that git no longer tracks and that hold only `node_modules`, `vendor`, `.nuxt`, `.output` or `.env` |
| `EXCLUDE_SITES` | (none) | Site names never touched, space separated |

### Schedule

| Setting | Default | Meaning |
|---|---|---|
| `SCHEDULE_EVERY` | 1h | How often the scheduled cleanup runs: `30m`, `1h`, `6h`, `1d`… |
| `NOTIFY` | yes | Dashboard notification after a scheduled run removes something |

lerd has no "PR merged" event, so "automatically after a merge" means a
regular check. `schedule on` installs a user launchd job
(`sh.lerd.plugin.worktree-cleanup`) that runs `run --apply --quiet`; changing
`SCHEDULE_EVERY` re-applies it. Every removal is logged to `cleanup.log` in the
plugin's data folder.

## Required tools

| Tool | Why | Install |
|---|---|---|
| `gh` | PR state per branch and per commit; must be logged in (`gh auth login`) with access to the repos | `brew install gh` |
| `git` | worktree state, base-branch checks, patches | Xcode command line tools |
| `jq` | reading lerd's API | ships with macOS 15+, or `brew install jq` |
| `curl` | lerd's API and notifications | ships with macOS |
| `lsof` | finding worktrees a process is using | ships with macOS |

`config check` (or the dashboard page) verifies all of them, plus `gh` login and
access to lerd's API. `gh` is checked when the plugin runs rather than at load,
because lerd's dashboard runs with a PATH that doesn't include Homebrew; the
scripts add `/opt/homebrew/bin` and `/usr/local/bin` themselves.

macOS only for now (the schedule uses launchd).

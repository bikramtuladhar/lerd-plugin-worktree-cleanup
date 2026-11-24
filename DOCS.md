# Worktree cleanup

Every lerd worktree of a proxy site runs its own dev server (a file watcher),
and Laravel worktrees can carry their own database, so finished worktrees add
up fast. This plugin removes the ones whose work is finished, by hand or on a
schedule, following rules you choose.

## Where to use it

- **Dashboard:** the **Worktree cleanup** page on the rail. **Preview** (dry run)
  and **Clean up now** run in the background and the **Run** tab shows them live:
  sites as they are scanned, each worktree that will go (or went) and why, and
  a progress bar while removing. Leave the page and come back: a run in
  progress is picked up again. **History** lists past runs; click one to open
  it. **Settings** opens with a plain-language summary of your rules and has
  every setting as a control (changed ones are marked, with a reset).
  **Tools** checks every required tool, your GitHub login and API budget, shows
  how much the plugin stores, and lists saved patches to view or delete.
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
lerd plugin schedule worktree-cleanup on|off   # run it automatically
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
| `SAVE_PATCH` | yes | Save uncommitted changes as `patches/<site>-<worktree>-<time>.patch` before removing (deleted again if the removal fails). Restore with `git apply <patch>` |

### Safety

| Setting | Default | Meaning |
|---|---|---|
| `SKIP_BUSY` | yes | Keep a worktree a process (shell, editor, AI session) has as its working folder. lerd's own dev server doesn't count |
| `REQUIRE_IDLE` | yes | Keep a worktree lerd saw requests on within its idle timeout |
| `DROP_DATABASE` | yes | If lerd reports the worktree has its own database, drop it with `lerd db:share` first. When lerd refuses, the worktree is kept and the reason shown |
| `EXCLUDE_SITES` | (none) | Site names never touched, space separated |

### Schedule

| Setting | Default | Meaning |
|---|---|---|
| `SCHEDULE_EVERY` | 1h | How often the scheduled cleanup acts, 15m or longer: `30m`, `1h`, `6h`, `1d`… |
| `NOTIFY` | yes | Dashboard notification after a scheduled run removes something |

lerd has no "PR merged" event, so "automatically after a merge" means a
regular check. lerd runs the plugin's `cleanup` schedule every 15 minutes once
you allow it (asked at install, the Schedule switch on the plugin's card, or
`lerd plugin schedule worktree-cleanup on`); the plugin skips runs until
`SCHEDULE_EVERY` has passed, then removes with `--apply`. Every removal is
logged to `cleanup.log` in the plugin's data folder, and
`lerd plugin schedule worktree-cleanup` shows the last run.

## Required tools

| Tool | Why | Install |
|---|---|---|
| `gh` | PR state per branch and per commit; must be logged in (`gh auth login`) with access to the repos | [GitHub CLI installation](https://cli.github.com/) |
| `git` | worktree state, base-branch checks, patches | Xcode command line tools |
| `jq` | reading lerd's API | ships with macOS 15+, or `brew install jq` |
| `curl` | lerd's API and notifications | ships with macOS |
| `lsof` | finding worktrees a process is using | ships with macOS |

`config check` (or the dashboard page) verifies all of them, plus `gh` login and
access to lerd's API. `gh` is checked when the plugin runs rather than at load,
because background processes may have a minimal PATH; the scripts append
`~/.local/bin`, `/opt/homebrew/bin` and `/usr/local/bin`. Other installation
locations must be on the PATH of the process running the plugin.

## Run history

Every run (Preview, Clean up now, the CLI, the MCP tool, and scheduled runs
that found something to remove) is kept as `runs/<time>.jsonl` in the plugin's
data folder: one JSON event per line (`start`, `site`, `wt` with its verdict
and reason, `removing`, `removed`/`failed`/`kept`, `done`). The last 200 are
kept. Removals are also appended to `cleanup.log` as plain text.

Only one run happens at a time; a second one started meanwhile is refused (the
dashboard shows the run already in progress instead).

## How it scans

Sites are scanned in parallel. For each site, one GitHub GraphQL call fetches
the latest PR of every worktree's branch and the PRs containing every HEAD, and
`git fetch` runs only for the base branches, only when a worktree needs the
base-branch check. Network calls give up after 90 seconds and never prompt;
a failed fetch is reported as a warning and the last fetched refs are used.
Removals then happen one at a time.

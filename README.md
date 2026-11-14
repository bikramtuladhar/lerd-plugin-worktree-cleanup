# lerd worktree-cleanup

A [lerd](https://github.com/lerd-env/lerd) plugin that removes finished git
worktrees, with their dev server and their own database, by hand or on a
schedule, following rules you choose.

Every worktree of a proxy site runs its own dev server (a file watcher) and a
Laravel worktree can carry its own database, so finished worktrees pile up and
keep `fseventsd` busy. "Finished" means: its PR was merged, its PR was closed,
or (detached / no PR) its HEAD is already on a base branch and has been for a
day. Worktrees a process is sitting in, or that lerd saw recent traffic on, are
kept. Uncommitted changes are saved as a patch before removal, or the worktree
is kept, per your settings.

![The Worktree cleanup page](docs/page.png)

```
lerd plugin install https://github.com/bikramtuladhar/lerd-plugin-worktree-cleanup
```

Usage, every setting and the required tools: [DOCS.md](DOCS.md).

## What it adds

- A dashboard page, **Worktree cleanup**: every setting as a toggle, the
  schedule, a tool check, Preview (dry run) and Clean up now.
- Commands `worktree-cleanup:run`, `:config`, `:schedule`.
- A site command, **Clean up finished worktrees**, for one site.
- An MCP tool, `worktree-cleanup_run`, plus a skill telling assistants to dry
  run first.
- A loopback-only API endpoint the page uses.

## What it reads

- lerd's `/api/sites` (sites, their worktrees, branch and idle state).
- Each site's git repository: `git fetch origin`, worktree status, whether HEAD
  is on a base branch.
- `DB_DATABASE` from the site's and each worktree's `.env`, only to tell whether
  a worktree has its own database (it differs from the parent's).
- The working folder of running processes (`ps`, `lsof`), to skip worktrees in use.

## What it changes

- Removes finished worktrees with `lerd worktree remove` (and `--force` only
  when your rules say to remove one with uncommitted changes).
- Drops a worktree's own database with `lerd db:share` before removing it.
- Deletes leftover folders in `<site>/.claude/worktrees/` that git no longer
  tracks and that hold only `node_modules`, `vendor`, `.nuxt`, `.output`, `.env`.
- Writes only to its data folder: `config.env`, `cleanup.log`, `patches/`,
  `schedule.log`.
- **Schedule (off until you turn it on):** `schedule on` writes a user
  LaunchAgent, `~/Library/LaunchAgents/sh.lerd.plugin.worktree-cleanup.plist`,
  that runs `lerd worktree-cleanup:run --apply --quiet` every `SCHEDULE_EVERY`.
  `schedule off` removes it. lerd has no periodic or "PR merged" event, so this
  is how "clean up after a merge" happens without you running it.

## What it sends

- GitHub, through the `gh` CLI you are logged into: for each site's `origin`
  repository, its pull requests (head branch, state, number), and a search by
  commit SHA for a detached HEAD. Nothing else leaves the machine.
- lerd's own API: `/api/sites` and a dashboard notification after a scheduled
  run removes something (`NOTIFY`).

## Requirements

macOS, lerd 1.38+, `gh` (logged in), `git`, `jq`, `curl`, `lsof`.

## License

MIT

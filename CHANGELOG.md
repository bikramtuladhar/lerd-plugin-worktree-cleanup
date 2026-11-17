# Changelog

## 0.5.0

A rebuilt dashboard that shows each run live, keeps a history of runs, and
scans much faster.

### Dashboard

- **Live runs.** Preview and Clean up now start in the background and the page
  follows them as they go: a progress bar, what is being scanned or removed,
  and a card per site with each worktree, its state and the reason. Leaving and
  reopening the page picks the run up again.
- **History.** Every preview and cleanup is kept (the last 200), plus scheduled
  runs that found something. Open any of them to see what happened and why.
- **Settings.** A plain-language summary of your rules at the top, then four
  groups side by side: Removal rules, Uncommitted changes, Safety and Schedule.
  Settings that depend on another sit under it. Remove/Keep choices side by side,
  tags for branch and site lists (with your lerd sites suggested), a marker and
  a one-click reset on every changed setting, and Reset all.
- **Schedule status.** Shows whether lerd has allowed the schedule (read from
  lerd's own "Allowed" line, so a run in progress still shows as on), when it
  last checked, when the last scheduled cleanup happened, and the command that
  turns it on.
- **Tools.** A system check (required tools, GitHub login, remaining GitHub API
  budget, lerd API, background runs) with the command that fixes each problem;
  storage use; and saved patches grouped per worktree, to view or delete.
- **Accessibility.** Native modal dialogs with the safe choice focused,
  keyboard navigation between tabs, tables that stack into cards on narrow
  screens, screen-reader announcements for run results and saves, and no
  spinning for people who prefer reduced motion.

### Cleanup

- **Faster scans.** Sites are scanned in parallel and each site's pull requests
  come from one GitHub GraphQL query instead of one call per worktree. `git
  fetch` runs only when a worktree passes the age check. A scan that took about
  two minutes now takes seconds.
- `worktree-cleanup:config check` also reports the GitHub login, the GraphQL
  budget, the lerd API and whether runs can start in the background.

### Fixed

- **Saved patches piled up.** A worktree with uncommitted changes that could
  not be removed got a new patch on every run (one worktree collected 46), and
  stayed in place. Its database is now dropped first, and the patch from a
  failed removal is deleted again.
- **The same removal was logged twice.** A scheduled run and a manual run
  could overlap and act on the same worktrees. Now only one run goes at a time:
  a scheduled run skips quietly, and starting a second run from the dashboard
  opens the one already in progress.
- **A setting could run code.** Settings are saved to a file the scripts load
  as shell, and list and duration values were only checked on their first
  line. A value with a line break and quotes ran as a command when the settings
  were next loaded. Quotes, backslashes and line breaks are now refused.
- **A worktree could be deleted when its removal failed.** After `lerd
  worktree remove` failed, the check for whether git had already let go of the
  worktree read its path as a pattern, so a path with `+` or `[` in it looked
  gone and its folder was deleted. Paths are now compared as plain text, and
  only a folder inside or beside the site's own is ever deleted.
- **A worktree in use could be removed.** The check for processes sitting in a
  worktree, and the site filters, also read names as patterns. They now
  compare plain text.
- **A merged worktree that shares the site's database was never removed.**
  lerd can flag a worktree as having its own database while it actually uses
  the site's. Clearing that flag fails when the site's database isn't on a
  lerd service, and the cleanup took that as a reason to keep the worktree,
  run after run. Now only a database of its own that lerd refuses to drop
  keeps a worktree; a flag that can't be cleared is noted and the removal goes
  ahead.
- **The dashboard failed to load on a fresh install.** Its status call broke
  with a jq "invalid JSON" error until the first cleanup had written a log and
  a patch, or whenever lerd's sites API didn't answer. Missing files now count
  as 0 and an unreachable API as no sites.
- **The interval's description didn't follow the setting.** "Clean up every"
  now says how often a cleanup runs, and updates as soon as you change it.
- Scratch files are written inside the plugin's data folder instead of `/tmp`.

## 0.4.0

- Runs on lerd's own schedules (every 15 minutes, acting once
  `SCHEDULE_EVERY` has passed) instead of a LaunchAgent.
- Works on Linux as well as macOS.
- Leftover-folder cleanup is gone: it could delete a `.env` another tool owns.
- Reads whether a worktree has its own database from lerd's API instead of
  `.env` files.
- Notifies only after scheduled runs.
- Requires lerd 1.39.

## 0.3.0

- First release: removes finished lerd worktrees (PR merged, PR closed, or
  already on a base branch) with their dev server and their own database, by
  hand, from the dashboard, from an assistant, or on a schedule.

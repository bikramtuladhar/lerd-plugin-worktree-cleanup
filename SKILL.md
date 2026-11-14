---
name: lerd-worktree-cleanup
description: Remove finished lerd worktrees (PR merged/closed, or detached HEAD already on main) with their DB and dev server, following the user's configured rules. Use when the user asks to clean up worktrees, free processes, or when fseventsd / dev servers pile up.
---

Call `worktree-cleanup_run` with `apply: false` first and show the user the
list, including what is kept and why. Only call it with `apply: true` after
they agree. Optional `sites` limits it to named lerd sites.

The rules (what counts as finished, what happens to uncommitted changes, the
safety guards, the schedule) are the user's: they live in
`lerd worktree-cleanup:config` and on the dashboard's Worktree cleanup page.
Don't change them unless the user asks; when they do, use
`lerd worktree-cleanup:config KEY=VALUE`.

#!/usr/bin/env bash
# .claude/hooks/sweep-session-logs.sh
#
# Commit any outstanding Claude Code session logs on the *current* branch.
#
# The Stop hook (log-session.sh) writes per-branch logs but does not commit
# them; committing is normally folded into a PR. Turns on `main` (merges,
# triage) and post-merge wrap-up turns have no PR to carry their log, so it can
# strand untracked in dev/sessions/ — the hook warns when it spots this. Run
# this from the branch the stranded logs belong to (or main) to sweep whatever
# is outstanding into a single commit. See CLAUDE.md, "Session logs".
#
# On `main`, the commit is pushed directly: a session-log-only commit has
# nothing to review, so it is exempt from the PR-only rule (see CLAUDE.md). On
# any other branch it is left for that branch's PR to carry.
#
# Usage:  .claude/hooks/sweep-session-logs.sh

set -euo pipefail

root="$(git rev-parse --show-toplevel)"
cd "$root"

outstanding="$(git status --porcelain --untracked-files=all -- dev/sessions/ \
  | sed 's/^...//' | grep -E '\.md$' || true)"

if [ -z "$outstanding" ]; then
  echo "No outstanding session logs to sweep."
  exit 0
fi

echo "Sweeping these session logs onto $(git rev-parse --abbrev-ref HEAD):"
printf '%s\n' "$outstanding" | sed 's/^/  /'

# Stage only the log files, so a stray edit elsewhere is never swept in by accident.
printf '%s\n' "$outstanding" | while IFS= read -r f; do
  [ -n "$f" ] && git add -- "$f"
done

git commit -m "Sweep session logs

Commit Claude Code session logs left uncommitted on this branch (main-branch
and post-merge turns can strand their logs — see CLAUDE.md).

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"

# On the default branch, a log-only commit is allowed straight to `main`, so
# push it. Elsewhere, leave it for the branch's PR to carry.
branch="$(git rev-parse --abbrev-ref HEAD)"
# `|| true`: origin/HEAD is often unconfigured locally, so the probe fails; under
# `set -e` + pipefail that would abort the script before the push. Fall back to
# `main` when it cannot be determined.
default="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)"
[ -n "$default" ] || default="main"

if [ "$branch" = "$default" ]; then
  echo "On $default — pushing the session-log commit directly (allowed for logs; see CLAUDE.md)."
  git push
else
  echo "Committed on $branch; it will travel with this branch's PR."
fi

echo "Done."

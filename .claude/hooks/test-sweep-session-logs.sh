#!/usr/bin/env bash
# Test for sweep-session-logs.sh.
#
# Drives the sweep against a repo wired to a bare "remote" and asserts what it
# commits and pushes. The load-bearing case is the default branch with
# origin/HEAD NOT configured locally: that made an earlier version abort under
# `set -e` before pushing (the symbolic-ref probe failed and pipefail propagated
# it). Run: bash .claude/hooks/test-sweep-session-logs.sh
#
# Covers: push-on-default-branch, no-push-on-feature-branch, and the no-op case.

set -uo pipefail

sweep="$(cd "$(dirname "$0")" && pwd)/sweep-session-logs.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

pass=0
fail=0
check() { # condition-already-evaluated($?)  description
  if [ "$1" -eq 0 ]; then
    pass=$((pass + 1)); printf '  ok   %s\n' "$2"
  else
    fail=$((fail + 1)); printf '  FAIL %s\n' "$2"
  fi
}

# A bare remote and a working clone, on `main`. Crucially we do NOT set
# origin/HEAD, mirroring a real repo where it is often unconfigured.
git init -q --bare "$work/remote.git"
git clone -q "$work/remote.git" "$work/wc" 2>/dev/null
proj="$work/wc"
git -C "$proj" config user.email t@t.t
git -C "$proj" config user.name t
git -C "$proj" commit -q --allow-empty -m init
git -C "$proj" branch -M main
git -C "$proj" push -q -u origin main
mkdir -p "$proj/dev/sessions"

echo "1. On the default branch, the sweep commits AND pushes"
printf 'main log\n' > "$proj/dev/sessions/x-main.md"
( cd "$proj" && bash "$sweep" ) >/dev/null 2>&1
check $? "sweep exits 0 on main"
git -C "$proj" diff --quiet HEAD origin/main; check $? "local main and origin/main match (it was pushed)"
git -C "$proj" cat-file -e "origin/main:dev/sessions/x-main.md" 2>/dev/null
check $? "the log is present on the remote"

echo "2. Nothing outstanding is a clean no-op"
out="$(cd "$proj" && bash "$sweep" 2>&1)"
check $? "sweep exits 0 with nothing to do"
echo "$out" | grep -qi "no outstanding"; check $? "reports there was nothing to sweep"

echo "3. On a feature branch, the sweep commits but does NOT push"
git -C "$proj" checkout -q -b feat
printf 'feat log\n' > "$proj/dev/sessions/y-feat.md"
( cd "$proj" && bash "$sweep" ) >/dev/null 2>&1
check $? "sweep exits 0 on a feature branch"
[ -n "$(git -C "$proj" log --oneline origin/main..feat)" ]; check $? "commit exists locally on the branch"
! git -C "$proj" ls-remote --exit-code --heads origin feat >/dev/null 2>&1
check $? "feature branch was not pushed"

echo
echo "passed: $pass   failed: $fail"
[ "$fail" -eq 0 ]

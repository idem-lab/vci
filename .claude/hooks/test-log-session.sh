#!/usr/bin/env bash
# Test for log-session.sh.
#
# The hook can only be exercised for real by Claude Code, so this drives it with
# synthetic Stop payloads and hand-written transcripts and asserts the resulting
# log files. Run: bash .claude/hooks/test-log-session.sh
#
# Covers: single-branch append, cross-branch separation, the compaction guard,
# filename sanitising, and that the hook always exits 0.

set -uo pipefail

hook="$(cd "$(dirname "$0")" && pwd)/log-session.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

pass=0
fail=0
check() { # description  condition-already-evaluated($?)
  if [ "$1" -eq 0 ]; then
    pass=$((pass + 1))
    printf '  ok   %s\n' "$2"
  else
    fail=$((fail + 1))
    printf '  FAIL %s\n' "$2"
  fi
}

# A project that is a real git repo (the hook keys state off the git dir).
proj="$work/proj"
mkdir -p "$proj"
git -C "$proj" init -q
git -C "$proj" config user.email t@t.t
git -C "$proj" config user.name t
git -C "$proj" commit -q --allow-empty -m init
git -C "$proj" checkout -q -b main 2>/dev/null || git -C "$proj" branch -m main

transcript="$work/transcript.jsonl"
session="aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
short="aaaaaaaa"

# One JSONL entry per line, matching the fields the hook's jq filter reads.
add_turn() { # role text
  jq -cn --arg r "$1" --arg t "$2" \
    '{type:$r, message:{role:$r, content:[{type:"text", text:$t}]}}' >> "$transcript"
}

run_hook() { # branch
  git -C "$proj" checkout -q "$1" 2>/dev/null
  printf '%s' "$(jq -cn --arg s "$session" --arg tp "$transcript" \
    '{session_id:$s, transcript_path:$tp}')" \
    | CLAUDE_PROJECT_DIR="$proj" bash "$hook"
  return $?
}

logdir="$proj/dev/sessions"

echo "1. First turn on main is logged"
add_turn user "set up the widget"
add_turn assistant "Done, widget is set up."
run_hook main
check $? "hook exits 0"
main_log="$(ls "$logdir"/*-"$short"-main.md 2>/dev/null | head -1)"
[ -n "$main_log" ] && [ -f "$main_log" ]; check $? "main log file created with branch in name"
grep -q "widget is set up" "$main_log" 2>/dev/null; check $? "assistant text present"
grep -q "Branch: \`main\`" "$main_log" 2>/dev/null; check $? "header records correct branch"

echo "2. A second turn on main appends, without duplicating the first"
add_turn user "add a sprocket"
add_turn assistant "Sprocket added."
run_hook main
check $? "hook exits 0"
grep -q "Sprocket added" "$main_log" 2>/dev/null; check $? "new turn appended"
[ "$(grep -c "widget is set up" "$main_log")" -eq 1 ]; check $? "first turn not duplicated"

echo "3. Switching branch starts a new file with only the new turns"
git -C "$proj" checkout -q -b iss99/feature 2>/dev/null
add_turn user "work on the feature"
add_turn assistant "Feature branch work here."
run_hook iss99/feature
check $? "hook exits 0"
feat_log="$(ls "$logdir"/*-"$short"-iss99-feature.md 2>/dev/null | head -1)"
[ -n "$feat_log" ] && [ -f "$feat_log" ]; check $? "branch name sanitised ('/' -> '-') in filename"
grep -q "Feature branch work here" "$feat_log" 2>/dev/null; check $? "new-branch turn in new file"
! grep -q "Feature branch work here" "$main_log" 2>/dev/null; check $? "new-branch turn NOT in main file"
! grep -q "widget is set up" "$feat_log" 2>/dev/null; check $? "main turns NOT in feature file"

echo "4. Returning to main appends to the original main file"
git -C "$proj" checkout -q main
add_turn user "back on main"
add_turn assistant "Back on main now."
run_hook main
check $? "hook exits 0"
grep -q "Back on main now" "$main_log" 2>/dev/null; check $? "resumed main turn in original main file"
! grep -q "Back on main now" "$feat_log" 2>/dev/null; check $? "resumed main turn NOT in feature file"

echo "5. Compaction (transcript shrinks) does not crash or duplicate"
before="$(cat "$main_log")"
: > "$transcript"                      # simulate a rewritten, shorter transcript
add_turn assistant "Post-compaction summary."
run_hook main
check $? "hook exits 0 after compaction"
grep -q "compacted" "$main_log" 2>/dev/null; check $? "compaction noted in log"
[ "$(grep -c "Back on main now" "$main_log")" -eq 1 ]; check $? "pre-compaction turn not duplicated"

echo "6. Missing jq or transcript is a silent no-op"
printf '%s' '{"session_id":"x"}' | CLAUDE_PROJECT_DIR="$proj" bash "$hook"
check $? "no transcript_path -> exit 0"
printf '%s' "$(jq -cn --arg s "$session" '{session_id:$s, transcript_path:"/no/such/file"}')" \
  | CLAUDE_PROJECT_DIR="$proj" bash "$hook"
check $? "missing transcript file -> exit 0"

echo
echo "passed: $pass   failed: $fail"
[ "$fail" -eq 0 ]

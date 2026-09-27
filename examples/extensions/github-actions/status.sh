#!/bin/sh
# Shows the last GitHub Actions run of a repository while it runs, and for a minute after it ends.
# Needs the GitHub CLI (gh). Set REPO_DIR to your checkout.
REPO_DIR="${REPO_DIR:-$HOME/Developer/my-app}"
cd "$REPO_DIR" 2>/dev/null || exit 0
run=$(gh run list --limit 1 --json status,conclusion,workflowName,updatedAt \
  --jq '.[0] | [.status, (.conclusion // ""), .workflowName, .updatedAt] | @tsv' 2>/dev/null) || exit 0
status=$(printf '%s' "$run" | cut -f1)
conclusion=$(printf '%s' "$run" | cut -f2)
name=$(printf '%s' "$run" | cut -f3)
case "$status" in
  in_progress|queued)
    printf '{"title":"%s","symbol":"gearshape.2.fill","tint":"orange","text":"Running","ttl":120}' "$name" ;;
  completed)
    if [ "$conclusion" = "success" ]; then
      printf '{"title":"%s","symbol":"checkmark.seal.fill","tint":"green","text":"Passed","ttl":60}' "$name"
    else
      printf '{"title":"%s","symbol":"xmark.octagon.fill","tint":"red","text":"Failed","priority":"alert","ttl":300}' "$name"
    fi ;;
esac

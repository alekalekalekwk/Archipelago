#!/bin/bash
# Pemakaian: scripts/verify.sh <STEP> <file-yang-boleh-berubah> [file lain ...]
# Contoh:   scripts/verify.sh S2 Sources/Archipelago/Window/HoverTrackingView.swift
# Script ini hanya MEMBACA dan mem-build. Tidak menjalankan app.

step="$1"
if [ -z "$step" ]; then
  echo "usage: scripts/verify.sh <STEP> <allowed file> [...]"
  exit 2
fi
shift

echo "=== VERIFY $step ==="
echo "--- RULE 0"
pwd
git rev-parse --show-toplevel
git branch --show-current
git remote -v

echo "--- BUILD"
swift build 2>&1 | tail -15

echo "--- LOG"
git --no-pager log --oneline -4

echo "--- STATUS (harus kosong)"
git status --short

echo "--- COMMIT"
git --no-pager show --stat --format='%h %s' HEAD

echo "--- FILE CHECK"
changed=$(git diff-tree --no-commit-id --name-only -r HEAD)
extra=""
for f in $changed; do
  ok=0
  for a in "$@"; do
    if [ "$f" = "$a" ]; then ok=1; fi
  done
  if [ $ok -eq 0 ]; then extra="$extra $f"; fi
done
if [ -z "$extra" ]; then
  echo "FILES OK"
else
  echo "FILES EXTRA:$extra"
fi

echo "--- FORBIDDEN PATTERNS"
grep -rnE '#Preview|@Observable|import Observation|@main' Sources || echo "none"

echo "--- LINES"
for f in $changed; do
  if [ -f "$f" ]; then wc -l "$f"; fi
done
echo "=== END VERIFY ==="

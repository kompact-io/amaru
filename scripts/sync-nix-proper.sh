#!/usr/bin/env bash
set -euo pipefail

# Keep the nix-proper branch rebased on top of upstream main.
#
# nix-proper carries a hand-written flake.nix/flake.lock on top of main.
# Every run rebases those commits onto the latest origin/main, always
# keeping nix-proper's own flake.nix on conflicts (-X theirs; in rebase
# "theirs" is the commit being replayed, i.e. ours on nix-proper), then
# regenerates flake.lock
#
# Usage: ./scripts/sync-nix-proper.sh

branch="nix-proper"
base="main"

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
  echo "error: working tree is dirty, refusing to touch $branch" >&2
  exit 1
fi

git fetch origin "$base"
git checkout "$branch"

if git rebase "origin/$base" -X theirs; then
  :
else
  echo "error: rebase hit a conflict -X theirs could not resolve; aborting" >&2
  git rebase --abort
  exit 1
fi

nix flake lock

if ! git diff --quiet -- flake.lock; then
  git add flake.lock
  git commit -s -m "chore: regenerate flake.lock against latest main"
fi

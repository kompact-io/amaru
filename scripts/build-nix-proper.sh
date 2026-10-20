#!/usr/bin/env bash
set -euo pipefail

# Rebase nix-proper on top of upstream main (keeping nix-proper's own
# flake.nix on any conflict) and build the flake. Read-only with respect to
# both remotes: nothing is pushed. Use ./scripts/sync-nix-proper.sh to
# publish the rebased branch to the fork.
#
# Usage: ./scripts/build-nix-proper.sh

branch="nix-proper"
base="main"
upstream="origin"

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

if [[ -n "$(git status --porcelain -uno)" ]]; then
  echo "error: working tree is dirty, refusing to touch $branch" >&2
  exit 1
fi

git fetch "$upstream" "$base"
git checkout "$branch"

if ! git rebase "$upstream/$base" -X theirs; then
  echo "error: rebase hit a conflict -X theirs could not resolve; aborting" >&2
  git rebase --abort
  exit 1
fi

nix build .

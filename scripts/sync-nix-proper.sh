#!/usr/bin/env bash
set -euo pipefail

# Rebase nix-proper onto upstream main and publish it to the fork.
#
# nix-proper is defined to be exactly upstream main plus one commit: the nix
# packaging. Upstream (pragma-org) is fetch-only; the result is pushed to the
# fork (kompact-io). Since the branch is a moving rewrite of upstream rather
# than an append-only history, the push is always a force.
#
# Upstream maintains a flake.nix of its own (a weekly bot bumps the release
# tarball hashes in it), so the replay conflicts most weeks. Ours always wins:
# `-X theirs` favours the commit being replayed -- confusingly, during a rebase
# "theirs" is our commit -- and flake.nix is then restored verbatim regardless.
# flake.lock is refreshed and folded into the same commit.
#
# Usage: ./scripts/sync-nix-proper.sh

branch="nix-proper"
base="main"
upstream="origin"
fork="kio"

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

if [[ -n "$(git status --porcelain -uno)" ]]; then
  echo "error: working tree is dirty, refusing to touch $branch" >&2
  exit 1
fi

git fetch "$upstream" "$base"
git checkout "$branch"

before=$(git rev-parse HEAD)

if ! git rebase "$upstream/$base" -X theirs; then
  echo "error: rebase hit a conflict -X theirs could not resolve; aborting" >&2
  git rebase --abort
  exit 1
fi

git checkout "$before" -- flake.nix
nix flake update
git add flake.nix flake.lock
git commit --amend --no-edit

git push --force-with-lease "$fork" "$branch"

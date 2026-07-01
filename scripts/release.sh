#!/usr/bin/env bash
# Release frontend-presentation: bump VERSION, commit, tag vX.Y.Z, push.
#   scripts/release.sh [patch|minor|major | X.Y.Z] ["changelog note"]
#   scripts/release.sh --selftest            # bump-math check, no git
# Explicit-only: running this pushes a public tag. On any failure it STOPS (set -e) —
# never force-push or re-tag by hand.
set -euo pipefail

bump(){ # $1=current  $2=kind|X.Y.Z  -> echoes new version
  local MA MI PA; IFS=. read -r MA MI PA <<<"$1"
  case "$2" in
    major) echo "$((MA+1)).0.0" ;;
    minor) echo "$MA.$((MI+1)).0" ;;
    patch) echo "$MA.$MI.$((PA+1))" ;;
    [0-9]*.[0-9]*.[0-9]*) echo "$2" ;;
    *) return 2 ;;
  esac
}

if [ "${1:-}" = "--selftest" ]; then
  [ "$(bump 0.0.0 minor)" = 0.1.0 ] || { echo "FAIL minor"; exit 1; }
  [ "$(bump 1.2.3 patch)" = 1.2.4 ] || { echo "FAIL patch"; exit 1; }
  [ "$(bump 1.2.3 major)" = 2.0.0 ] || { echo "FAIL major"; exit 1; }
  [ "$(bump 1.2.3 4.5.6)" = 4.5.6 ] || { echo "FAIL explicit"; exit 1; }
  echo "selftest OK"; exit 0
fi

cd "$(git rev-parse --show-toplevel)"
CUR="$(cat VERSION 2>/dev/null || echo 0.0.0)"
NEW="$(bump "$CUR" "${1:-patch}")" || { echo "usage: release.sh [patch|minor|major | X.Y.Z] [note]" >&2; exit 2; }
NOTE="${2:-}"
[ "$NEW" = "$CUR" ] && { echo "no version change ($CUR)"; exit 1; }

echo "$NEW" > VERSION
git add -A
git commit -m "release: v$NEW${NOTE:+ — $NOTE}"
git tag -a "v$NEW" -m "v$NEW${NOTE:+ — $NOTE}"
git push origin HEAD --follow-tags
echo "released v$NEW  ($CUR → $NEW)"

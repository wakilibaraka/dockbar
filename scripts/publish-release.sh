#!/bin/bash
set -euo pipefail

# Attach a DMG to a release, creating the release only if it does not already exist.
#
# Usage:
#   scripts/publish-release.sh v0.5.0 [DockBar-v0.5.0.dmg]
#
# This is deliberately idempotent. The Release workflow fires whenever a `v*` tag is
# pushed, but a release may already have been published by hand before the tag landed —
# `scripts/release.sh --upload`, or a rerun of the tag. A plain `gh release create` fails
# with "a release with the same tag name already exists", which turns the workflow red and
# hides the fact that everything actually succeeded. Here the existing release is reused
# and the asset is (re)uploaded, so the run is green either way and the asset is correct.
#
# Requires GH_TOKEN in the environment (the workflow passes github.token).

TAG="${1:-}"
[ -n "$TAG" ] || { echo "usage: $0 <tag> [dmg]" >&2; exit 1; }

DMG="${2:-DockBar-${TAG}.dmg}"
[ -f "$DMG" ] || { echo "missing asset: $DMG" >&2; exit 1; }

if gh release view "$TAG" >/dev/null 2>&1; then
  echo "Release $TAG already exists; replacing its asset with $DMG."

  # `--clobber` overwrites an asset of the same name, so reruns stay idempotent too.
  gh release upload "$TAG" "$DMG" --clobber

  # The tag may have been pushed after the release was created, so make sure the release
  # is not left as a prerelease or a draft from an earlier partial run.
  gh release edit "$TAG" --draft=false --prerelease=false --latest
else
  echo "Creating release $TAG from $DMG."
  gh release create "$TAG" "$DMG" --latest --verify-tag --generate-notes --title "DockBar ${TAG}"
fi

echo "Published: $TAG"
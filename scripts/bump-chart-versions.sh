#!/usr/bin/env bash
#
# Auto-bump the patch version of any chart whose tracked files changed in a
# given git range but whose Chart.yaml `version` was not already changed.
#
# Usage:
#   scripts/bump-chart-versions.sh <before-ref> <after-ref>
#
# Examples:
#   scripts/bump-chart-versions.sh HEAD^ HEAD
#   scripts/bump-chart-versions.sh "$GITHUB_EVENT_BEFORE" "$GITHUB_SHA"
#
# On success it writes the names of bumped charts to stdout (one per line) and
# leaves the modified Chart.yaml files in the working tree. The caller is
# responsible for committing them.
set -euo pipefail

CHARTS_DIR="${CHARTS_DIR:-charts}"

before="${1:-}"
after="${2:-HEAD}"

# Fall back to the previous commit if no/empty/zero "before" ref is provided
# (e.g. first push to a branch reports an all-zero SHA).
if [[ -z "$before" || "$before" =~ ^0+$ ]]; then
  if git rev-parse --verify --quiet "${after}^" >/dev/null; then
    before="${after}^"
  else
    # No parent commit (initial commit): nothing to compare against.
    exit 0
  fi
fi

# Read a chart's version from a Chart.yaml at a specific ref, or "" if absent.
version_at_ref() {
  local ref="$1" path="$2"
  git show "${ref}:${path}" 2>/dev/null \
    | sed -n 's/^version:[[:space:]]*//p' \
    | head -n1 \
    | tr -d '"'\' || true
}

bumped=()

for chart_yaml in "${CHARTS_DIR}"/*/Chart.yaml; do
  [[ -e "$chart_yaml" ]] || continue
  chart_dir="$(dirname "$chart_yaml")"
  chart_name="$(basename "$chart_dir")"

  # Did any tracked file in this chart change in the range?
  if git diff --quiet "${before}" "${after}" -- "$chart_dir"; then
    continue
  fi

  before_version="$(version_at_ref "$before" "$chart_yaml")"
  after_version="$(version_at_ref "$after" "$chart_yaml")"

  # If the version already changed in this range, respect the manual bump.
  if [[ -n "$before_version" && "$before_version" != "$after_version" ]]; then
    continue
  fi

  current="$after_version"
  if [[ ! "$current" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "WARN: ${chart_name}: version '${current}' is not plain SemVer (x.y.z); skipping auto-bump" >&2
    continue
  fi

  IFS='.' read -r major minor patch <<<"$current"
  new_version="${major}.${minor}.$((patch + 1))"

  # Replace only the top-level version: line.
  sed -i "0,/^version:.*/s//version: ${new_version}/" "$chart_yaml"
  bumped+=("$chart_name")
  echo "Bumped ${chart_name}: ${current} -> ${new_version}" >&2
done

# Emit bumped chart names to stdout for the caller.
for name in "${bumped[@]:-}"; do
  [[ -n "$name" ]] && echo "$name"
done

#!/bin/bash
# Prints "<udid> <name>" of the iPhone simulator to use: the one named $1 if given,
# else a booted iPhone, else the first available one. Fails if there is none.
set -euo pipefail

devices=$(xcrun simctl list devices available | grep -E '^ +iPhone' || true)
if [[ -n "${1:-}" ]]; then
  devices=$(grep -F "    $1 (" <<<"$devices" || true)
fi
line=$( (grep '(Booted)' <<<"$devices" || true; echo "$devices") | grep -m1 . || true)
if [[ -z "$line" ]]; then
  echo "No available iPhone simulator${1:+ named \"$1\"}. Install one in Xcode > Settings > Components." >&2
  exit 1
fi
name=$(sed -E 's/^ +(.*) \([0-9A-F-]{36}\).*/\1/' <<<"$line")
udid=$(grep -oE '[0-9A-F-]{36}' <<<"$line")
echo "$udid $name"

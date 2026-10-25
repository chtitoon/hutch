#!/bin/bash
# Fails if app code bypasses the design tokens (apps/ios/DESIGN.md): raw colors, or
# hard-coded font sizes, padding, spacing and corner radii. Generated files are exempt.
# A grep, not SwiftLint, so it needs nothing installed; swap it for a SwiftLint rule if it grows.
set -euo pipefail
cd "$(dirname "$0")"

patterns=(
  'Color\((red|hue|white|\.sRGB|#)'
  'UIColor\((red|hue|white|named)'
  '\.font\(\.system\(size:'
  '\.padding\(([1-9]|\.[a-zA-Z]+, *[1-9])'
  'spacing: *[1-9]'
  'cornerRadius: *[1-9]'
)

found=0
for pattern in "${patterns[@]}"; do
  if matches=$(grep -rnE --include='*.swift' "$pattern" Hutch --exclude-dir=Generated); then
    echo "$matches"
    found=1
  fi
done

if [[ $found -eq 1 ]]; then
  echo "Use Palette, Spacing, Radius or Typography (generated from DESIGN.md) instead of the raw values above." >&2
  exit 1
fi

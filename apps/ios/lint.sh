#!/bin/bash
# Fails on Swift that isn't formatted Google-style (.swift-format, AGENTS.md), or app code that
# bypasses the design tokens (DESIGN.md). Generated files are exempt. `make format` fixes the first.
set -euo pipefail
cd "$(dirname "$0")"

find Hutch HutchTests core tokens.swift icon.swift -name '*.swift' -not -path '*/Generated/*' -not -path '*/.build/*' -print0 \
  | xargs -0 xcrun swift format lint --strict --configuration .swift-format

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

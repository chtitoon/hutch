#!/bin/bash
# Fails on Swift that isn't formatted Google-style (.swift-format, AGENTS.md), or app code that
# bypasses the design tokens (DESIGN.md). Generated files are exempt. `make format` fixes the first.
set -euo pipefail
cd "$(dirname "$0")"

find Hutch HutchTests core tokens.swift icon.swift -name '*.swift' -not -path '*/Generated/*' -not -path '*/.build/*' -print0 \
  | xargs -0 xcrun swift format lint --strict --configuration .swift-format

# A doc comment is one short paragraph; anything longer is a // note in the code (AGENTS.md).
if matches=$(grep -rnE '^\s*///\s*$' --include='*.swift' --exclude-dir=Generated --exclude-dir=.build Hutch HutchTests core tokens.swift icon.swift); then
  echo "$matches"
  echo "Keep doc comments to one paragraph, with no empty /// line; move the rest to a // note." >&2
  exit 1
fi

# Google style puts a case's body on its own lines; swift-format keeps it where it was written.
if matches=$(grep -rnE '^\s*(case [^=]*|default):\s*\S' --include='*.swift' --exclude-dir=Generated --exclude-dir=.build Hutch HutchTests core tokens.swift icon.swift); then
  echo "$matches"
  echo "Put each case's body on the line after its label (Google Swift style)." >&2
  exit 1
fi

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

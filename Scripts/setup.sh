#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "XcodeGen not found - installing via Homebrew..."
  brew install xcodegen
fi

xcodegen generate
echo "Done. Open QuoteBox.xcodeproj, or run: open QuoteBox.xcodeproj"

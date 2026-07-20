#!/usr/bin/env bash
#
# CI entry point: build and run the full test suite (unit + UI) on a simulator.
# Dependency-free (no xcbeautify etc.). Runs from anywhere; resolves the project dir itself.
#
# Override via env if a runner has a different simulator:
#   DESTINATION='platform=iOS Simulator,name=iPhone 16,OS=latest' ./Scripts/ci.sh
#
set -euo pipefail

cd "$(dirname "$0")/.."   # -> apps/TangramOdyssey (contains the .xcodeproj)

SCHEME="TangramOdyssey"
PROJECT="TangramOdyssey.xcodeproj"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 17,OS=latest}"
RESULT_BUNDLE="${RESULT_BUNDLE:-build/TangramTests.xcresult}"

echo "▸ xcodebuild test — scheme: $SCHEME — destination: $DESTINATION"
rm -rf "$RESULT_BUNDLE"

xcodebuild test \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -resultBundlePath "$RESULT_BUNDLE" \
  CODE_SIGNING_ALLOWED=NO

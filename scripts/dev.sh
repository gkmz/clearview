#!/usr/bin/env bash
# ClearView local development helper.
# Usage:
#   ./scripts/dev.sh build   # compile Debug app
#   ./scripts/dev.sh unit    # run unit tests only
#   ./scripts/dev.sh test    # run unit/UI tests
#   ./scripts/dev.sh run     # build Debug app, then launch it

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PROJECT="ClearView.xcodeproj"
SCHEME="ClearView"
DESTINATION="platform=macOS"
DERIVED="${ROOT}/build/DerivedData"
ACTION="${1:-}"

usage() {
  sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'
}

if [[ -z "$ACTION" || "$ACTION" == "-h" || "$ACTION" == "--help" ]]; then
  usage
  exit 0
fi

mkdir -p "$DERIVED"

case "$ACTION" in
  build)
    echo "==> Building ${SCHEME} (Debug)..."
    xcodebuild \
      -project "$PROJECT" \
      -scheme "$SCHEME" \
      -configuration Debug \
      -destination "$DESTINATION" \
      -derivedDataPath "$DERIVED" \
      -quiet \
      build
    ;;

  unit)
    echo "==> Testing ${SCHEME} unit tests..."
    xcodebuild \
      -project "$PROJECT" \
      -scheme "$SCHEME" \
      -destination "$DESTINATION" \
      -derivedDataPath "$DERIVED" \
      -only-testing:ClearViewTests \
      -quiet \
      test
    ;;

  test)
    echo "==> Testing ${SCHEME}..."
    xcodebuild \
      -project "$PROJECT" \
      -scheme "$SCHEME" \
      -destination "$DESTINATION" \
      -derivedDataPath "$DERIVED" \
      -quiet \
      test
    ;;

  run)
    echo "==> Building ${SCHEME} (Debug)..."
    xcodebuild \
      -project "$PROJECT" \
      -scheme "$SCHEME" \
      -configuration Debug \
      -destination "$DESTINATION" \
      -derivedDataPath "$DERIVED" \
      -quiet \
      build

    APP="${DERIVED}/Build/Products/Debug/ClearView.app"
    if [[ ! -d "$APP" ]]; then
      echo "error: built app not found: $APP" >&2
      exit 1
    fi

    echo "==> Launching ${APP}"
    open "$APP"
    ;;

  *)
    echo "error: unknown command: $ACTION" >&2
    usage >&2
    exit 2
    ;;
esac

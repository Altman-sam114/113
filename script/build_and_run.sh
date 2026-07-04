#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="LocalGemma"
SCHEME="LocalGemma"
CONFIGURATION="Debug"
DESTINATION="platform=macOS,variant=Mac Catalyst"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/LocalGemma.xcodeproj"
DERIVED_DATA_PATH="$ROOT_DIR/.build/DerivedDataCodex-MacCatalystRun"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

usage() {
  cat >&2 <<USAGE
usage: $0 [run|--build-only|--verify|--logs|--telemetry|--debug|--help]

Builds the LocalGemma Mac Catalyst app into project-local DerivedData.
Default run mode stops any existing LocalGemma process, builds, and opens the app.
USAGE
}

kill_existing() {
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
}

build_app() {
  mkdir -p "$DERIVED_DATA_PATH"
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -sdk macosx \
    -destination "$DESTINATION" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    CODE_SIGNING_ALLOWED=NO \
    build >&2
}

find_app_bundle() {
  local app_bundle
  app_bundle="$(
    find "$DERIVED_DATA_PATH/Build/Products" \
      -path "*/Debug-maccatalyst/$APP_NAME.app" \
      -type d \
      -print \
      2>/dev/null |
      head -n 1
  )"

  if [[ -z "$app_bundle" ]]; then
    echo "Unable to locate $APP_NAME.app under $DERIVED_DATA_PATH/Build/Products" >&2
    exit 1
  fi

  printf '%s\n' "$app_bundle"
}

open_app() {
  local app_bundle="$1"
  /usr/bin/open -n "$app_bundle"
}

verify_running() {
  if ! pgrep -x "$APP_NAME" >/dev/null; then
    echo "$APP_NAME did not appear in the process list after launch." >&2
    echo "The app may have failed to open because of signing, window server, or sandbox restrictions." >&2
    exit 1
  fi
}

build_and_find_app() {
  build_app
  find_app_bundle
}

case "$MODE" in
  run)
    kill_existing
    app_bundle="$(build_and_find_app)"
    open_app "$app_bundle"
    ;;
  --build-only|build-only)
    app_bundle="$(build_and_find_app)"
    printf '%s\n' "$app_bundle"
    ;;
  --verify|verify)
    kill_existing
    app_bundle="$(build_and_find_app)"
    open_app "$app_bundle"
    sleep 2
    verify_running
    ;;
  --logs|logs)
    kill_existing
    app_bundle="$(build_and_find_app)"
    open_app "$app_bundle"
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    kill_existing
    app_bundle="$(build_and_find_app)"
    open_app "$app_bundle"
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --debug|debug)
    kill_existing
    app_bundle="$(build_and_find_app)"
    lldb -- "$app_bundle/Contents/MacOS/$APP_NAME"
    ;;
  --help|help|-h)
    usage
    ;;
  *)
    usage
    exit 2
    ;;
esac

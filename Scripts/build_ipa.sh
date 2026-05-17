#!/usr/bin/env bash
# Локальная сборка unsigned .ipa для MeetPoint.
#
# Использование:
#   ./Scripts/build_ipa.sh                 — Release, без подписи
#   ./Scripts/build_ipa.sh Debug           — Debug, без подписи
#   CODESIGN=1 ./Scripts/build_ipa.sh      — Release, с автоматической подписью
#
# Результат:
#   build/ipa/MeetPoint-unsigned.ipa
#
# Требования: macOS + Xcode 15+.

set -euo pipefail

CONFIGURATION="${1:-Release}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
XCODE_PROJECT="$PROJECT_DIR/MeetPoint/MeetPoint.xcodeproj"
SCHEME="MeetPoint"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/MeetPoint.xcarchive"
IPA_DIR="$BUILD_DIR/ipa"
IPA_NAME="MeetPoint-unsigned.ipa"

bold()  { printf "\033[1m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }
red()   { printf "\033[31m%s\033[0m\n" "$*"; }

bold "→ MeetPoint build_ipa.sh"
echo "   project:     $XCODE_PROJECT"
echo "   scheme:      $SCHEME"
echo "   config:      $CONFIGURATION"
echo "   output:      $IPA_DIR/$IPA_NAME"
echo

if ! command -v xcodebuild >/dev/null 2>&1; then
    red "✘ xcodebuild не найден. Установите Xcode и Command Line Tools."
    exit 1
fi

rm -rf "$BUILD_DIR"
mkdir -p "$IPA_DIR"

CODE_SIGN_FLAGS=(
    CODE_SIGNING_ALLOWED=NO
    CODE_SIGN_IDENTITY=""
    CODE_SIGNING_REQUIRED=NO
)
if [[ "${CODESIGN:-0}" == "1" ]]; then
    bold "→ Подпись включена (CODESIGN=1) — Xcode выберет automatic signing"
    CODE_SIGN_FLAGS=()
fi

bold "→ xcodebuild archive..."
xcodebuild \
    -project "$XCODE_PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -sdk iphoneos \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE_PATH" \
    "${CODE_SIGN_FLAGS[@]}" \
    archive

bold "→ Пакую Payload/ в .ipa..."
APP_DIR="$ARCHIVE_PATH/Products/Applications"
if [[ ! -d "$APP_DIR/MeetPoint.app" ]]; then
    red "✘ MeetPoint.app не найден после архивации в $APP_DIR"
    exit 1
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

mkdir -p "$WORK_DIR/Payload"
cp -R "$APP_DIR/MeetPoint.app" "$WORK_DIR/Payload/"
( cd "$WORK_DIR" && zip -qr "$IPA_DIR/$IPA_NAME" Payload )

ls -lah "$IPA_DIR"
green "✓ Готово: $IPA_DIR/$IPA_NAME"
shasum -a 256 "$IPA_DIR/$IPA_NAME"

cat <<'NOTE'

Подсказки:
  • Unsigned .ipa нельзя установить на устройство стандартными средствами.
    Для установки на iPhone подпишите его free-профилем через Xcode:
      Xcode → Window → Devices and Simulators → drag-n-drop .ipa
    либо запустите сборку с переменной окружения CODESIGN=1.
  • Для запуска на симуляторе достаточно открыть проект в Xcode и нажать ⌘R.
NOTE

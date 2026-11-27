#!/bin/bash
# NationWar 런처 맥 설치 (DESIGN MU5). 터미널에 붙여 넣는 한 줄:
#   curl -fsSL https://spiro6360.github.io/nation-war/install-mac.sh | bash
# 브라우저 대신 curl 로 받으면 "Apple 이 확인하지 못했다" 창이 뜨지 않는다 (격리 표시가 붙지 않음).
# 하는 일: 이 맥의 칩에 맞는 dmg 받기 → 응용 프로그램 폴더에 복사(이미 있으면 바꿈) → 런처 켜기. 관리자 암호는 묻지 않는다.
set -euo pipefail

BASE="https://github.com/spiro6360/nation-war/releases/latest/download"
if [ "$(sysctl -n hw.optional.arm64 2>/dev/null || echo 0)" = "1" ]; then ARCH=arm64; else ARCH=x64; fi
URL="$BASE/NationWar-Mac-$ARCH.dmg"

WORK="$(mktemp -d)"
MNT=""
cleanup() {
  if [ -n "$MNT" ]; then hdiutil detach "$MNT" -quiet 2>/dev/null || true; fi
  rm -rf "$WORK"
}
trap cleanup EXIT

echo "NationWar 런처 ($ARCH) 받는 중…"
curl -fL --progress-bar -o "$WORK/nw.dmg" "$URL"

MNT="$WORK/mnt"
mkdir -p "$MNT"
hdiutil attach "$WORK/nw.dmg" -nobrowse -readonly -mountpoint "$MNT" -quiet
APP_SRC="$(find "$MNT" -maxdepth 1 -name '*.app' | head -n 1)"
if [ -z "$APP_SRC" ]; then
  echo "받은 파일 안에 런처가 없습니다. 잠시 뒤 다시 해 주세요." >&2
  exit 1
fi
NAME="$(basename "$APP_SRC")"

DEST_DIR="/Applications"
if [ ! -w "$DEST_DIR" ]; then
  DEST_DIR="$HOME/Applications"
  mkdir -p "$DEST_DIR"
fi
DEST="$DEST_DIR/$NAME"

# 켜져 있으면 끄고 바꿈
osascript -e "quit app \"${NAME%.app}\"" >/dev/null 2>&1 || true
sleep 1
rm -rf "$DEST"
ditto "$APP_SRC" "$DEST"
xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true

echo "설치 끝: $DEST"
open "$DEST"

#!/usr/bin/env bash
# 将 ClearView 打成 macOS DMG（内含 .app + 指向「应用程序」的快捷方式，用户拖过去即可安装）。
# 用法：
#   ./scripts/create-dmg.sh
#       → 在项目根执行 xcodebuild Release，再从产物生成 dist/ClearView-<版本>.dmg
#   ./scripts/create-dmg.sh /path/to/ClearView.app
#       → 跳过编译，仅对已构建的 .app 打包（适合你在 Xcode 里先 Archive/Build 再打包）

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SCHEME="ClearView"
PROJECT="ClearView.xcodeproj"
DERIVED="${ROOT}/build/XcodeDerivedData"
STAGING="${ROOT}/dist/dmg-staging"

# 从 .app 的 Info.plist 取 CFBundleShortVersionString，与 Xcode MARKETING_VERSION 一致；读不到则回退 AppVersion.swift。
read_app_marketing_version() {
  local app="$1"
  local plist="${app}/Contents/Info.plist"
  local v=""
  if [[ -f "${plist}" ]]; then
    v="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${plist}" 2>/dev/null || true)"
  fi
  if [[ -z "${v}" && -f "${ROOT}/ClearView/AppVersion.swift" ]]; then
    v="$(grep -E 'static let version' "${ROOT}/ClearView/AppVersion.swift" | head -1 | sed -E 's/.*"([^"]+)".*/\1/')"
  fi
  if [[ -z "${v}" ]]; then
    v="0.0.0"
  fi
  echo "${v}"
}

resolve_app() {
  if [[ "${1:-}" != "" && -d "${1}" ]]; then
    # 用户传入自定义 .app 时走绝对路径，避免相对路径在 hdiutil 阶段出错。
    local parent
    parent="$(cd "$(dirname "$1")" && pwd)"
    echo "${parent}/$(basename "$1")"
    return
  fi

  echo "==> xcodebuild Release（DerivedData: ${DERIVED}）..." >&2
  rm -rf "${DERIVED}" 2>/dev/null || true
  mkdir -p "${DERIVED}"

  local log="${DERIVED}/xcodebuild.log"
  # xcodebuild 会向 stdout 打大量日志；若混入 resolve_app 的 echo，后续 ditto 会失败，因此全部写入日志文件。
  # 无开发者账号时可用 CODE_SIGNING_ALLOWED=NO 打出本地可跑的 .app；对外分发需自行签名/公证。
  xcodebuild \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -configuration Release \
    -derivedDataPath "${DERIVED}" \
    -destination "platform=macOS" \
    CODE_SIGNING_ALLOWED=NO \
    build >"${log}" 2>&1

  local built="${DERIVED}/Build/Products/Release/ClearView.app"
  if [[ ! -d "${built}" ]]; then
    echo "error: 未找到 ${built}，请检查 scheme 是否为 ${SCHEME}。完整日志: ${log}" >&2
    exit 1
  fi
  echo "${built}"
}

APP="$(resolve_app "${1:-}")"
VERSION="$(read_app_marketing_version "${APP}")"
DMG="${ROOT}/dist/ClearView-${VERSION}.dmg"

echo "==> 使用 App: ${APP}"
echo "==> 版本: ${VERSION} → ${DMG##*/}"
rm -rf "${STAGING}" 2>/dev/null || true
rm -f "${DMG}" 2>/dev/null || true
mkdir -p "${STAGING}"

echo "==> 写入 DMG 内容（.app + Applications 链接）..."
ditto "${APP}" "${STAGING}/ClearView.app"
# 常见 DMG 体验——根目录放「应用程序」替身，用户把 .app 拖进去即完成安装。
ln -sf /Applications "${STAGING}/Applications"

mkdir -p "$(dirname "${DMG}")"
echo "==> 生成压缩 DMG（UDZO）..."
hdiutil create -volname "ClearView ${VERSION}" -srcfolder "${STAGING}" -ov -format UDZO "${DMG}"

echo "==> 完成: ${DMG}"
open -R "${DMG}" 2>/dev/null || true

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP_NAME="PaperSplit"
VERSION="${VERSION:-$(node -p "require('${ROOT}/package.json').version")}"
ARCH="${ARCH:-universal}"
BUILD_DIR="${ROOT}/build/macos"
OUT_DIR="${ROOT}/dist-app"
APP="${OUT_DIR}/${APP_NAME}.app"
ICONSET="${BUILD_DIR}/AppIcon.iconset"

case "${ARCH}" in
    universal|arm64|x86_64) ;;
    *)
        echo "Unsupported ARCH=${ARCH} (use universal, arm64 or x86_64)" >&2
        exit 1
        ;;
esac

echo "==> Building web assets"
( cd "${ROOT}" && npm run build )

echo "==> Building Swift shell + local server (${ARCH})"
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

build_one() {
    local arch="$1"
    local goarch="$2"

    swiftc -O -swift-version 5 \
        -target "${arch}-apple-macos13.0" \
        -framework AppKit -framework WebKit \
        "${ROOT}/packaging/macos/main.swift" \
        -o "${BUILD_DIR}/${APP_NAME}-${arch}"

    (
        cd "${ROOT}/packaging/server"
        CGO_ENABLED=0 GOOS=darwin GOARCH="${goarch}" \
            go build -trimpath -ldflags "-s -w" -o "${BUILD_DIR}/papersplit-server-${arch}" .
    )
    echo "    compiled ${arch}"
}

if [ "${ARCH}" = "universal" ]; then
    build_one arm64 arm64
    build_one x86_64 amd64
    lipo -create \
        "${BUILD_DIR}/${APP_NAME}-arm64" \
        "${BUILD_DIR}/${APP_NAME}-x86_64" \
        -output "${BUILD_DIR}/${APP_NAME}"
    lipo -create \
        "${BUILD_DIR}/papersplit-server-arm64" \
        "${BUILD_DIR}/papersplit-server-x86_64" \
        -output "${BUILD_DIR}/papersplit-server"
else
    case "${ARCH}" in
        arm64) GOARCH="arm64" ;;
        x86_64) GOARCH="amd64" ;;
    esac
    build_one "${ARCH}" "${GOARCH}"
    cp "${BUILD_DIR}/${APP_NAME}-${ARCH}" "${BUILD_DIR}/${APP_NAME}"
    cp "${BUILD_DIR}/papersplit-server-${ARCH}" "${BUILD_DIR}/papersplit-server"
fi

echo "==> Assembling app bundle"
rm -rf "${APP}"
mkdir -p "${APP}/Contents/MacOS" "${APP}/Contents/Resources"
cp "${BUILD_DIR}/${APP_NAME}" "${APP}/Contents/MacOS/${APP_NAME}"
cp "${BUILD_DIR}/papersplit-server" "${APP}/Contents/Resources/papersplit-server"
chmod 755 "${APP}/Contents/Resources/papersplit-server"
cp -R "${ROOT}/dist" "${APP}/Contents/Resources/www"
cp "${ROOT}/packaging/macos/Info.plist" "${APP}/Contents/Info.plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" "${APP}/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${VERSION}" "${APP}/Contents/Info.plist"

echo "==> Generating app icon"
rm -rf "${ICONSET}"
mkdir -p "${ICONSET}"
make_icon() {
    sips -z "$1" "$1" "${ROOT}/packaging/macos/AppIcon-1024.png" --out "${ICONSET}/$2" >/dev/null
}
make_icon 16 icon_16x16.png
make_icon 32 icon_16x16@2x.png
make_icon 32 icon_32x32.png
make_icon 64 icon_32x32@2x.png
make_icon 128 icon_128x128.png
make_icon 256 icon_128x128@2x.png
make_icon 256 icon_256x256.png
make_icon 512 icon_256x256@2x.png
make_icon 512 icon_512x512.png
make_icon 1024 icon_512x512@2x.png
iconutil -c icns "${ICONSET}" -o "${APP}/Contents/Resources/AppIcon.icns"

echo "==> Signing (ad-hoc)"
codesign --force --deep --sign - "${APP}" >/dev/null
codesign --verify --deep --strict "${APP}"

ZIP="${OUT_DIR}/${APP_NAME}-${VERSION}-macOS-${ARCH}.zip"
rm -f "${ZIP}"
ditto -c -k --keepParent "${APP}" "${ZIP}"

echo "==> Architectures: $(lipo -archs "${APP}/Contents/MacOS/${APP_NAME}") / $(lipo -archs "${APP}/Contents/Resources/papersplit-server")"
echo "==> Built ${APP}"
echo "==> Built ${ZIP}"

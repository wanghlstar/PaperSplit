#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VERSION="${VERSION:-$(node -p "require('${ROOT}/package.json').version")}"
OUT_DIR="${OUT_DIR:-${ROOT}/dist-packages}"
BUILD_DIR="${ROOT}/build/windows"
STAGE="${BUILD_DIR}/stage"
WWW="${ROOT}/packaging/windows/www"

echo "==> Building web assets"
( cd "${ROOT}" && npm run build )

echo "==> Staging embedded assets"
mkdir -p "${WWW}"
rm -rf "${WWW:?}"/*
cp -R "${ROOT}/dist/." "${WWW}/"

echo "==> Cross-compiling Windows x64 launcher"
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
(
    cd "${ROOT}/packaging/windows"
    CGO_ENABLED=0 GOOS=windows GOARCH=amd64 \
        go build -trimpath -ldflags "-s -w -H windowsgui" \
        -o "${BUILD_DIR}/PaperSplit.exe" .
)

echo "==> Packaging"
rm -rf "${STAGE}"
mkdir -p "${STAGE}"
cp "${BUILD_DIR}/PaperSplit.exe" "${STAGE}/"
if [ -f "${ROOT}/LICENSE" ]; then
    cp "${ROOT}/LICENSE" "${STAGE}/"
fi
cat > "${STAGE}/README.txt" <<EOF
PaperSplit ${VERSION} (Windows x64)

1. Double-click PaperSplit.exe.
2. PaperSplit starts a local server and opens its UI in Microsoft Edge app mode.
3. Close the window to exit.

Requirements: Windows 10/11 x64 with Microsoft Edge installed.
The app only listens on 127.0.0.1; no data leaves the machine.
EOF

mkdir -p "${OUT_DIR}"
ZIP="${OUT_DIR}/PaperSplit-${VERSION}-Windows-x64.zip"
rm -f "${ZIP}"
( cd "${STAGE}" && zip -q -r "${ZIP}" . )

echo "==> Built ${ZIP}"
shasum -a 256 "${ZIP}" 2>/dev/null || sha256sum "${ZIP}"

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
NAME="papersplit"
VERSION="${VERSION:-$(node -p "require('${ROOT}/package.json').version")}"
OUT_DIR="${OUT_DIR:-${ROOT}/dist-packages}"
BUILD_DIR="${ROOT}/build/fnos"
STAGE="${BUILD_DIR}/stage"

echo "==> Building web assets"
( cd "${ROOT}" && npm run build )

echo "==> Cross-compiling static server"
rm -rf "${BUILD_DIR}"
mkdir -p "${STAGE}"/{app/bin,app/www,app/ui/images,cmd,config,wizard}

build_server() {
    local goarch="$1"
    local goarm="$2"
    local target="$3"
    (
        cd "${ROOT}/packaging/server"
        GOOS=linux GOARCH="${goarch}" GOARM="${goarm}" CGO_ENABLED=0 \
            go build -trimpath -ldflags "-s -w" -o "${STAGE}/app/bin/papersplit-server_${target}" .
    )
    echo "    linux/${goarch} -> ${target}"
}

build_server amd64 "" x86_64
build_server arm64 "" aarch64
build_server arm 7 armv7

echo "==> Assembling package"
cp -R "${ROOT}/dist/." "${STAGE}/app/www/"

sed "s/^version[[:space:]]*=.*/version               = ${VERSION}/" \
    "${ROOT}/packaging/fnos/manifest" > "${STAGE}/manifest"

cp "${ROOT}/packaging/fnos/config/resource" "${STAGE}/config/resource"
cp "${ROOT}/packaging/fnos/config/privilege" "${STAGE}/config/privilege"
cp "${ROOT}/packaging/fnos/app/ui/config" "${STAGE}/app/ui/config"
cp "${ROOT}/packaging/fnos/app/ui/images/icon_64.png" "${STAGE}/app/ui/images/icon_64.png"
cp "${ROOT}/packaging/fnos/app/ui/images/icon_256.png" "${STAGE}/app/ui/images/icon_256.png"
cp "${ROOT}/packaging/fnos/ICON.PNG" "${STAGE}/ICON.PNG"
cp "${ROOT}/packaging/fnos/ICON_256.PNG" "${STAGE}/ICON_256.PNG"

cp "${ROOT}"/packaging/fnos/cmd/* "${STAGE}/cmd/"
cp "${ROOT}"/packaging/fnos/wizard/* "${STAGE}/wizard/"

find "${STAGE}" -type d -exec chmod 755 {} +
find "${STAGE}" -type f -exec chmod 644 {} +
chmod 755 "${STAGE}"/cmd/*
chmod 755 "${STAGE}"/app/bin/papersplit-server_*

# app.tgz contains bin/, www/ and ui/ at its root (extracted to the app target dir)
( cd "${STAGE}" && tar -czf app.tgz -C app bin www ui )

mkdir -p "${OUT_DIR}"
FPK="${OUT_DIR}/${NAME}_${VERSION}_all.fpk"
( cd "${STAGE}" && tar -czf "${FPK}" --exclude='app' * )

echo "==> Built ${FPK}"
shasum -a 256 "${FPK}" 2>/dev/null || sha256sum "${FPK}"

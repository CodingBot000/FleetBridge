#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if ! command -v flutter >/dev/null 2>&1; then
  echo 'Flutter 3.47.9를 PATH에 추가하세요.' >&2
  exit 1
fi
version=$(flutter --version --machine | /usr/bin/python3 -c 'import json,sys; print(json.load(sys.stdin)["frameworkVersion"])')
if [ "$version" != 3.47.9 ]; then
  echo "Flutter 3.47.9가 필요합니다. 현재 버전: $version" >&2
  exit 1
fi
cd "$root/fleetbridge_detail"
flutter pub get --enforce-lockfile
flutter build swift-package --platform ios --no-codesign

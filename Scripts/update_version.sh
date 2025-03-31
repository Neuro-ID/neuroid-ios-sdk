#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 2 ]; then
    echo "usage $0 <version> <swift_file>"
    exit 1
fi

VERSION="$1"
SWIFT_FILE="$2"

sed -i.bak "s/%%%Version%%%/$VERSION/" "$SWIFT_FILE"

rm "$SWIFT_FILE.bak"

echo "updated $SWIFT_FILE; set version to \"$VERSION\""

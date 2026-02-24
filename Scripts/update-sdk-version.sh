#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: $0 <version>"
    echo ""
    echo "Updates the version in NeuroID.swift"
    echo ""
    echo "Example:"
    echo "  $0 v3.5.1"
    exit 1
fi

VERSION="$1"
NID_FILE="./Source/NeuroID/NeuroIDClass/NeuroIDCore.swift"

# Update the static version constant in NeuroID.swift
if [ -f "$NID_FILE" ]; then
    # Check if the pattern exists before attempting replacement
    if ! grep -q 'static let nidVersion = ' "$NID_FILE"; then
        echo "Error: 'static let nidVersion' not found in $NID_FILE" 1>&2
        echo "The variable declaration may have changed." 1>&2
        exit 1
    fi
    
    sed -i '' -E "s/(static let nidVersion = )\"[^\"]*\"/\1\"$VERSION\"/" "$NID_FILE"
    
    # Verify the replacement worked
    if grep -q "static let nidVersion = \"$VERSION\"" "$NID_FILE"; then
        echo "Updated $NID_FILE; set nidVersion to \"$VERSION\""
    else
        echo "Error: Failed to update nidVersion to \"$VERSION\"" 1>&2
        echo "The file was modified but the nidVersion doesn't match expected value." 1>&2
        exit 1
    fi
else
    echo "Error: NeuroID file not found: $NID_FILE" 1>&2
    exit 1
fi

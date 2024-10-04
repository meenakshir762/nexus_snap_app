#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <path-to-tar-file>"
    exit 1
fi

TAR_FILE="$1"


VERSION=$(tar --list -f "$TAR_FILE" | grep 'NexusEvtLogDecoder' | head -1 | grep -oP '\d+\.\d+\.\d+\.I\d+\.\d+')

if [ -n "$VERSION" ]; then
    echo "Extracted version: $VERSION"
else
    echo "No version found."
fi


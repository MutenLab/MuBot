#!/bin/bash
# Test script to tap at specified coordinates
# Usage: ./tapAt.sh x y
# Example: ./tapAt.sh 1950 820
# ==================================================

source $PROJECT_DIR/config/variables.sh

x=$1
y=$2

if [ -z "$x" ] || [ -z "$y" ]; then
    echo "Usage: $0 x y"
    echo "Example: $0 1950 820"
    exit 1
fi

echo "Tapping at ($x, $y)..."
adb_tap $x $y
echo "Done."

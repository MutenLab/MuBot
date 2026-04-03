#!/bin/bash
# Test script to check golden monster health bar status from emulator
# Usage: ./checkGoldenHealth.sh
# ==================================================

source $PROJECT_DIR/config/variables.sh

PYTHON_DETECT="$PROJECT_DIR/python/detectGoldenHealthBar.py"

echo "Checking golden monster health bar..."
status=$(adb_screencap | python3 "$PYTHON_DETECT" --stdin)
echo "Golden monster status: $status"

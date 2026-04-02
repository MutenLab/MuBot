#!/bin/bash
# Test script to check golden monster health bar status from emulator
# Usage: ./checkGoldenHealth.sh
# ==================================================

source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh

PYTHON_DETECT="/Users/icerrate/AndroidStudioProjects/bot/python/detectGoldenHealthBar.py"

echo "Checking golden monster health bar..."
status=$(adb_screencap | python3 "$PYTHON_DETECT" --stdin)
echo "Golden monster status: $status"

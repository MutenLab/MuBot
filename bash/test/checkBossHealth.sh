#!/bin/bash
# Test script to check boss health bar status from emulator
# Usage: ./checkBossHealth.sh
# ==================================================

source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh

PYTHON_DETECT="/Users/icerrate/AndroidStudioProjects/bot/python/detectBossHealthBar.py"

echo "Checking boss health bar..."
status=$(adb_screencap | python3 "$PYTHON_DETECT" --stdin)
echo "Boss status: $status"

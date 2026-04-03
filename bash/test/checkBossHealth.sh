#!/bin/bash
# Test script to check boss health bar status from emulator
# Usage: ./checkBossHealth.sh
# ==================================================

source $PROJECT_DIR/config/variables.sh

PYTHON_DETECT="$PROJECT_DIR/python/detectBossHealthBar.py"

echo "Checking boss health bar..."
status=$(adb_screencap | python3 "$PYTHON_DETECT" --stdin)
echo "Boss status: $status"

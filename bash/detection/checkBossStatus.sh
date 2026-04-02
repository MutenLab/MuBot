#!/bin/bash
# Check boss status (alive/dead) from current screen
# Usage:
#   ./checkBossStatus.sh           # Returns all: "1:alive,2:dead,..."
#   ./checkBossStatus.sh 5         # Returns single: "alive" or "dead"
# ==================================================

source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh

SCRIPT_DIR="$(dirname "$0")"
PYTHON_SCRIPT="/Users/icerrate/AndroidStudioProjects/bot/python/detectBossStatusOnSanctuaryMap.py"

boss_num=$1

# Take screenshot and pipe to Python script
if [ -z "$boss_num" ]; then
    # Check all bosses
    adb_screencap | python3 "$PYTHON_SCRIPT" --stdin
else
    # Check specific boss
    adb_screencap | python3 "$PYTHON_SCRIPT" --stdin --boss "$boss_num"
fi

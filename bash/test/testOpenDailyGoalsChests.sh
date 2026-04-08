#!/bin/bash
# Test script for openDailyGoalsChests
# Opens Daily Goals and collects all chests (A through E)
# ==================================================

source $PROJECT_DIR/config/variables.sh
source $PROJECT_DIR/bash/utils/eventUtils.sh

echo "Testing openDailyGoalsChests"
echo "=================================================="

openDailyGoalsChests

echo "=================================================="
echo "RESULT: Done"

#!/bin/bash
# Test script for findAndTapDailyGoalEvent
# Requires the Daily Goal window to be open on screen
# Usage: ./testFindDailyGoalEvent.sh [EVENT_ID]
# Example: ./testFindDailyGoalEvent.sh 4
# Available events:
#   1=MysticLandBoss 2=BloodCastle 3=CourageTrial 4=KundunTrial
#   5=GoldenMonster  6=FieldBoss   7=DevilSquare  8=WarriorQuest
# ==================================================

source $PROJECT_DIR/bash/utils/visionUtils.sh

EVENT=${1:-$DG_KUNDUN_TRIAL}

echo "Testing findAndTapDailyGoalEvent with event ID: $EVENT"
echo "Make sure the Daily Goal window is open on the emulator"
echo "=================================================="

findAndTapDailyGoalEvent $EVENT
exit_code=$?

echo "=================================================="
if [ $exit_code -eq 0 ]; then
    echo "RESULT: Event found and tapped"
else
    echo "RESULT: Event NOT found"
fi

exit $exit_code

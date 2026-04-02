#!/bin/bash
# Test script to check if user is logged in
# This script tests the leaveParty function from visionUtils.sh

# Source vision utilities
source /Users/icerrate/AndroidStudioProjects/bot/bash/utils/farmingUtils.sh

echo "========================================"
echo "     Testing leaveParty Function"
echo "========================================"
echo ""
echo "[$(date '+%H:%M:%S')] Checking if at party..."
echo ""

# Call leaveParty function
leaveParty

# Check the result
if [ $? -eq 0 ]; then
    echo "✓ Result: No party found"
    exit_code=0
else
    echo "✗ Result: User was at party. Left"
    exit_code=1
fi

echo ""
echo "========================================"
echo ""

exit $exit_code

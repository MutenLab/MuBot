#!/bin/bash
# Test script to check if user is logged in
# This script tests the isLoggedIn function from visionUtils.sh

# Source vision utilities
source /Users/icerrate/AndroidStudioProjects/bot/bash/utils/visionUtils.sh

echo "========================================"
echo "     Testing isLoggedIn Function"
echo "========================================"
echo ""
echo "[$(date '+%H:%M:%S')] Checking if user is logged in..."
echo ""

# Call isLoggedIn function
isLoggedIn

# Check the result
if [ $? -eq 0 ]; then
    echo "✓ Result: User is LOGGED IN"
    echo "  (logout_marker.png found at zone 1163,255 420x130)"
    exit_code=0
else
    echo "✗ Result: User is NOT logged in"
    echo "  (logout_marker.png not found at zone 1163,255 420x130)"
    exit_code=1
fi

echo ""
echo "========================================"
echo ""

exit $exit_code

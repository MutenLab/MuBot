#!/bin/bash

# Use first argument to teleport or not
teleport=${1:-true}

# Load configuration
source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh

# TELEPORT
# ==================================================
if [ $teleport = true ]; then
  /Users/icerrate/AndroidStudioProjects/bot/bash/teleport/toSwampOfPeace.sh
fi

# MOVE TO BOSS
# ==================================================
/Users/icerrate/AndroidStudioProjects/bot/bash/travel/swamp/370zone/to360Boss.sh

# Click auto attack
tap_auto

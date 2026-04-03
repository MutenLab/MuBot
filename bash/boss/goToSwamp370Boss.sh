#!/bin/bash

# Use first argument to teleport or not
teleport=${1:-true}

# Load configuration
source $PROJECT_DIR/config/variables.sh

# TELEPORT
# ==================================================
if [ $teleport = true ]; then
  $PROJECT_DIR/bash/teleport/toSwampOfPeace.sh
fi

# MOVE TO BOSS
# ==================================================
$PROJECT_DIR/bash/travel/swamp/380zone/to370Boss.sh

# Click auto attack
tap_auto

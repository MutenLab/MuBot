#!/bin/bash

# Load configuration
source $PROJECT_DIR/config/variables.sh

sleep 1
# Press back to show close dialog
adb_key 4
# Click confirm close
sleep 1
tap_exit_game_confirm

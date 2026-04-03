#!/bin/bash

# Load configuration
source $PROJECT_DIR/config/variables.sh

sleep 0.5
# Click attack to avoid glitches
tap_attack
# Click select mode
sleep 1
tap_mode_select
# Click peace mode
sleep 1
tap_mode_peace

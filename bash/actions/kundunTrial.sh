#!/bin/bash

# Load configuration
source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh

attackTime=20

# Auto attack to make sure top buttons are hidden
tap_auto
sleep 1
tap_auto

# Click expand top buttons
sleep 0.5
tap_more_top_button
sleep 0.5
# Click Daily Goal
tap_more_top_daily_goal

# Click Kundun Trial button
sleep 4
# When are first tries
# adb_tap 1215 773
# When are last tries
# adb_tap 1830 960

sleep 0.5
# Click enter
adb_tap 1960 1030
sleep 8

# Move to Kundun spot
adb_tap 890 170
sleep 1.9
adb_tap 890 170
sleep 1.9
adb_tap 890 170
sleep 1.9
adb_tap 890 170
sleep 1

# Auto attack
tap_auto
sleep 30

#!/bin/bash
wireToGo=${1:-1}

# Load configuration
source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh

sleep 0.2
# Click open wires popup
tap_switch_wire
sleep 0.5
case $wireToGo in
  1)
    adb_swipe 960 330 960 550 200
    sleep 0.5
    # Click Wire 1
    adb_tap 960 330
    ;;
  2)
    adb_swipe 960 330 960 550 200
    sleep 0.5
    # Click Wire 2
    adb_tap 960 490
    ;;
  3)
    adb_swipe 960 330 960 550 200
    sleep 0.5
    # Click Wire 3
    adb_tap 960 640
    ;;
  4)
    adb_swipe 960 650 960 450 200
    sleep 0.5
    # Click Wire 4
    adb_tap 960 400
    ;;
  5)
    adb_swipe 960 650 960 450 200
    sleep 0.5
    # Click Wire 5
    adb_tap 960 550
    ;;
  6)
    adb_swipe 960 650 960 450 200
    sleep 0.5
    # Click Wire 6
    adb_tap 960 700
    ;;
esac
sleep 0.5
# Click save wire selection
tap_switch_wire_confirm

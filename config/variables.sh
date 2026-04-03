#!/bin/bash
# Configuration file for game automation scripts
# ==============================================

# Project base directory (read from local.properties, with auto-detect fallback)
_VARS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PROJECT_ROOT="$(dirname "$_VARS_DIR")"
if [ -f "$_PROJECT_ROOT/local.properties" ]; then
    PROJECT_DIR="$(grep '^project.dir=' "$_PROJECT_ROOT/local.properties" | cut -d'=' -f2)"
fi
: "${PROJECT_DIR:=$_PROJECT_ROOT}"
export PROJECT_DIR
unset _VARS_DIR _PROJECT_ROOT

# Python Settings
# ===============
# Ensure Homebrew's Python (with packages) is used instead of Apple's system Python
export PATH="/opt/homebrew/bin:$PATH"


# ADB Device Settings
# ===================
# Emulator ID for ADB commands (get with: adb devices)
# For Android Emulator: emulator-5554, emulator-5556, etc.
# For BlueStacks: typically localhost:5555, localhost:5556, etc.
#   Make sure ADB is connected first: adb connect localhost:5555
EMULATOR_ID="127.0.0.1:5555"

# ADB wrapper functions - automatically target the correct emulator
adb_shell() {
    adb -s "$EMULATOR_ID" shell "$@"
}

adb_tap() {
    adb -s "$EMULATOR_ID" shell input tap "$@"
}

adb_swipe() {
    adb -s "$EMULATOR_ID" shell input swipe "$@"
}

adb_text() {
    adb -s "$EMULATOR_ID" shell input text "$@"
}

adb_key() {
    adb -s "$EMULATOR_ID" shell input keyevent "$@"
}

adb_screencap() {
    adb -s "$EMULATOR_ID" exec-out screencap -p
}

# Common tap shortcuts
# ====================
tap_openMap()       { adb_tap 1770 115; } # Migrated
tap_closeMap()      { adb_tap 1715 125; } # Migrated
tap_switch_wire()   { adb_tap 1870 22; } # Migrated
tap_switch_wire_confirm() { adb_tap 950 825; } # Migrated
tap_attack()        { adb_tap 1770 890; } # Migrated
tap_equipAngel()    { adb_tap 1000  1030; } # Migrated
tap_equipSatan()    { adb_tap 1100 1030; } # Migrated
tap_revive_button() { adb_tap 824 643; } # Migrated
tap_auto()          { adb_tap 1860 500; } # Migrated
tap_target_pvp()    { adb_tap 1870 800; } # Migrated
tap_skill_5()       { adb_tap 1725 580; } # Migrated

tap_open_inventory() { adb_tap 1860 400; } # Migrated
tap_inventory_shop() { adb_tap 1420 1000; } # Migrated
tap_inventory_shop_teleport() { adb_tap 815 640; } # Migrated
tap_inventory_recycle() { adb_tap 1680 1000; } # Migrated
tap_inventory_recycle_confirm() { adb_tap 1620 980; } # Migrated
tap_inventory_recycle_ads() { adb_tap 820 640; } # Migrated
tap_inventory_close() { adb_tap 1890 30; } # Migrated

tap_shop_health_potion() { adb_tap 1790 360; } # Migrated
tap_shop_mana_potion() { adb_tap 1790 625; } # Migrated
tap_exit_game_confirm() { adb_tap 1110 640; } # Migrated
tap_more_right_button() { adb_tap 1860 280; } # Migrated
tap_more_right_settings() { adb_tap 1870 960; } # Migrated
tap_settings_auto_tab() { adb_tap 1870 260; } # Migrated
tap_settings_auto_plan1() { adb_tap 1330 945; } # Migrated
tap_settings_auto_plan2() { adb_tap 1580 945; } # Migrated
tap_close_by_outside() { adb_tap 460 560; } # Migrated

tap_event_open_now() { adb_tap 243 326; } # PENDING TO VALIDATE
tap_event_scoreboard_close() { adb_tap 1310 188; } # Migrated
tap_event_last_level() { adb_tap 630 785; } # Migrated
tap_event_enter()   { adb_tap 1100 785; } # Migrated
tap_event_bc_best_location() { adb_tap 1138 533; } # Migrated
tap_event_ds_best_location() { adb_tap 1100 525; } # Migrated

tap_more_top_button() { adb_tap 1575 60; } # Migrated
tap_more_top_daily_goal() { adb_tap 1030 170; } # Migrated
tap_daily_goal_event_tab() { adb_tap 540 220; } # Migrated

tap_mode_select()   { adb_tap 1415 1050; } # Migrated
tap_mode_all()      { adb_tap 1415 1000; } # Migrated
tap_mode_peace()    { adb_tap 1415 825; } # Migrated
tap_mode_union()    { adb_tap 1415 940; } # Migrated

tap_party_pop_up_close() { adb_tap 1680 170; } # Migrated
tap_party_pop_up_leave() { adb_tap 1570 870; } # Migrated
tap_left_quest_tab() { adb_tap 30 145; } # Migrated
tap_left_team_tab() { adb_tap 30 300; } # Migrated

tap_close_expired_pop_up() { adb_tap 2160 380; }
tap_close_auto_play_pop_up() { adb_tap 1675 165; } # Migrated
tap_character_selection_start_game() { adb_tap 960 995; } # Migrated
tap_login_start_game() { adb_tap 960 805; } # Migrated
tap_update_confirm() { adb_tap 1104 639; } # Migrated
tap_close_ads() { adb_tap 1890 40; } # PENDING TO VALIDATE
tap_auto_party_box() { adb_tap 140 338; } # Migrated
tap_startup_close_ads() { adb_tap 1889 76; }

# Game Package Name
# ==================
GAME_PACKAGE="com.tszz.gpen.nowgg"

# Satan Imp Settings
# ==================
# Set to "satan" for new satan imp or "satan_old" for old satan imp
satanImpType="satan"

# Recycle Settings
# ================
# Set to true to enable automatic recycling during offensive mode,
# otherwise it will be disabled
recycleEnable=true
# Number of cycles before triggering recycle action
# Higher values = less frequent recycling
recycleCycleCounter=90

# Reposition Settings
# ===================
# Set to true to enable automatic repositioning during offensive mode,
# otherwise it will be disabled
repositionEnable=true
# Number of cycles before triggering reposition action
# Also triggers at cycle 0 (start of loop)
repositionCycleCounter=30

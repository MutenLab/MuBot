#!/bin/bash
# Configuration file for game automation scripts
# ==============================================

# Project base directory (read from local.properties, with auto-detect fallback)
_VARS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PROJECT_ROOT="$(dirname "$_VARS_DIR")"
if [ -f "$_PROJECT_ROOT/local.properties" ]; then
    PROJECT_DIR="$(grep '^project.dir=' "$_PROJECT_ROOT/local.properties" | cut -d'=' -f2)"
    QUICK_BUFF="$(grep '^quick.buff=' "$_PROJECT_ROOT/local.properties" | cut -d'=' -f2)"
    PICKUP_ITEMS_BOSS="$(grep '^pickup.items.boss=' "$_PROJECT_ROOT/local.properties" | cut -d'=' -f2)"
    PICKUP_ITEMS_GOLDEN="$(grep '^pickup.items.golden=' "$_PROJECT_ROOT/local.properties" | cut -d'=' -f2)"
    AUTOPLAY_ATTACK_TIMEOUT="$(grep '^autoPlay.attack.timeout=' "$_PROJECT_ROOT/local.properties" | cut -d'=' -f2)"
    EMULATOR_ID="$(grep '^emulator.id=' "$_PROJECT_ROOT/local.properties" | cut -d'=' -f2)"
    USE_IMMORTAL_SATAN="$(grep '^use.immortal.satan=' "$_PROJECT_ROOT/local.properties" | cut -d'=' -f2)"
    GAME_PACKAGE="$(grep '^game.package=' "$_PROJECT_ROOT/local.properties" | cut -d'=' -f2)"
    PLAN_BEFORE_DEVIL_SQUARE="$(grep '^plan.before.devil.square=' "$_PROJECT_ROOT/local.properties" | cut -d'=' -f2)"
    PLAN_AFTER_DEVIL_SQUARE="$(grep '^plan.after.devil.square=' "$_PROJECT_ROOT/local.properties" | cut -d'=' -f2)"
    PLAN_BEFORE_BLOOD_CASTLE="$(grep '^plan.before.blood.castle=' "$_PROJECT_ROOT/local.properties" | cut -d'=' -f2)"
    PLAN_AFTER_BLOOD_CASTLE="$(grep '^plan.after.blood.castle=' "$_PROJECT_ROOT/local.properties" | cut -d'=' -f2)"
    EVENT_DS_HOURS="$(grep '^event.devil.square.hours=' "$_PROJECT_ROOT/local.properties" | cut -d'=' -f2)"
    EVENT_DS_MINUTES_START="$(grep '^event.devil.square.minutes.start=' "$_PROJECT_ROOT/local.properties" | cut -d'=' -f2)"
    EVENT_DS_MINUTES_END="$(grep '^event.devil.square.minutes.end=' "$_PROJECT_ROOT/local.properties" | cut -d'=' -f2)"
    EVENT_BC_HOURS="$(grep '^event.blood.castle.hours=' "$_PROJECT_ROOT/local.properties" | cut -d'=' -f2)"
    EVENT_BC_MINUTES_START="$(grep '^event.blood.castle.minutes.start=' "$_PROJECT_ROOT/local.properties" | cut -d'=' -f2)"
    EVENT_BC_MINUTES_END="$(grep '^event.blood.castle.minutes.end=' "$_PROJECT_ROOT/local.properties" | cut -d'=' -f2)"
    EVENT_DS_MAX_FAILS="$(grep '^event.devil.square.max.fails=' "$_PROJECT_ROOT/local.properties" | cut -d'=' -f2)"
    EVENT_BC_MAX_FAILS="$(grep '^event.blood.castle.max.fails=' "$_PROJECT_ROOT/local.properties" | cut -d'=' -f2)"
fi
: "${PROJECT_DIR:=$_PROJECT_ROOT}"
: "${QUICK_BUFF:=false}"
: "${PICKUP_ITEMS_BOSS:=10}"
: "${PICKUP_ITEMS_GOLDEN:=4}"
: "${AUTOPLAY_ATTACK_TIMEOUT:=240}"
: "${EMULATOR_ID:=127.0.0.1:5555}"
: "${USE_IMMORTAL_SATAN:=true}"
: "${GAME_PACKAGE:=com.tszz.gpen.nowgg}"
: "${PLAN_BEFORE_DEVIL_SQUARE:=1}"
: "${PLAN_AFTER_DEVIL_SQUARE:=2}"
: "${PLAN_BEFORE_BLOOD_CASTLE:=2}"
: "${PLAN_AFTER_BLOOD_CASTLE:=0}"
: "${EVENT_DS_HOURS:=0,2,4,6}"
: "${EVENT_DS_MINUTES_START:=0}"
: "${EVENT_DS_MINUTES_END:=14}"
: "${EVENT_BC_HOURS:=1,3,5}"
: "${EVENT_BC_MINUTES_START:=0}"
: "${EVENT_BC_MINUTES_END:=14}"
: "${EVENT_DS_MAX_FAILS:=3}"
: "${EVENT_BC_MAX_FAILS:=3}"
export PROJECT_DIR
export QUICK_BUFF
export PICKUP_ITEMS_BOSS
export PICKUP_ITEMS_GOLDEN
export AUTOPLAY_ATTACK_TIMEOUT
export EMULATOR_ID
export USE_IMMORTAL_SATAN
export GAME_PACKAGE
export PLAN_BEFORE_DEVIL_SQUARE
export PLAN_AFTER_DEVIL_SQUARE
export PLAN_BEFORE_BLOOD_CASTLE
export PLAN_AFTER_BLOOD_CASTLE
export EVENT_DS_HOURS
export EVENT_DS_MINUTES_START
export EVENT_DS_MINUTES_END
export EVENT_BC_HOURS
export EVENT_BC_MINUTES_START
export EVENT_BC_MINUTES_END
export EVENT_DS_MAX_FAILS
export EVENT_BC_MAX_FAILS
unset _VARS_DIR _PROJECT_ROOT

# Python Settings
# ===============
# Ensure Homebrew's Python (with packages) is used instead of Apple's system Python
export PATH="/opt/homebrew/bin:$PATH"


# ADB Device Settings
# ===================
# Emulator ID is read from local.properties (emulator.id)
# For Android Emulator: emulator-5554, emulator-5556, etc.
# For BlueStacks: typically localhost:5555, localhost:5556, etc.
#   Make sure ADB is connected first: adb connect localhost:5555

# Game Package Name
# ===================
# Resolved from local.properties (game.package)

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

tap_event_open_now() { adb_tap 233 318; } # Migrated
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

# Satan Imp Settings
# ==================
# Resolved from local.properties (use.immortal.satan)
if [ "$USE_IMMORTAL_SATAN" = true ]; then
    satanImpType="satan_immortal"
else
    satanImpType="satan"
fi

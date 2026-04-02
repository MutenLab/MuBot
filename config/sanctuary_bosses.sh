#!/bin/bash
# Sanctuary 2 Hell Bosses Configuration
# Screen coordinates for boss locations on the map (pixels, top-left = 0,0)
# Format: BOSS_NAME_#=(x y)
# =============================================

# Entrance location (starting point when arriving at the map)
ENTRANCE=(1417 685) # Migrated

# Right channel (Bottom to top)
BOSS_1=(1321 673) # Migrated
BOSS_2=(1299 536) # Migrated
BOSS_3=(1162 514) # Migrated
BOSS_4=(1141 376) # Migrated
BOSS_5=(1004 353) # Migrated
# Mid Channel (Top to bottom)
BOSS_6=(1004 460) # Migrated
BOSS_7=(1220 677) # Migrated
# Left Channel (Bottom to top)
BOSS_8=(1214 778) # Migrated
BOSS_9=(1076 760) # Migrated
BOSS_10=(1056 620) # Migrated
BOSS_11=(917 600) # Migrated
BOSS_12=(898 462) # Migrated

# Travel times function (in seconds)
# Usage: getTravelTime FROM TO (e.g., getTravelTime ENTRANCE 1 or getTravelTime 5 6)
getTravelTime() {
    local from=$1
    local to=$2
    case "${from}_${to}" in
        # From ENTRANCE
        ENTRANCE_1) echo 9 ;;    # Validated
        ENTRANCE_2) echo 19 ;;   # Validated
        ENTRANCE_3) echo 30 ;;   # Validated
        ENTRANCE_4) echo 40 ;;   # Validated
        ENTRANCE_5) echo 49 ;;   # Validated
        ENTRANCE_6) echo 48 ;;   # Validated
        ENTRANCE_7) echo 24 ;;   # Validated
        ENTRANCE_8) echo 30 ;;   # Validated
        ENTRANCE_9) echo 38 ;;   # Validated
        ENTRANCE_10) echo 47 ;;  # Validated
        ENTRANCE_11) echo 57 ;;  # Validated
        ENTRANCE_12) echo 68 ;;  # Validated
        # From BOSS_1
        1_2) echo 12 ;;   # Validated
        1_3) echo 24 ;;   # Projection
        1_4) echo 36 ;;   # Projection
        1_5) echo 66 ;;   # Projection
        1_6) echo 30 ;;   # Projection
        1_7) echo 28 ;;   # Validated
        1_8) echo 33 ;;   # Validated
        1_9) echo 43 ;;   # Projection
        1_10) echo 55 ;;  # Validated
        1_11) echo 68 ;;  # Projection
        1_12) echo 80 ;;  # Projection
        # From BOSS_2
        2_3) echo 12 ;;   # Validated
        2_4) echo 22 ;;   # Validated
        2_5) echo 36 ;;   # Projection
        2_6) echo 66 ;;   # Projection
        2_7) echo 40 ;;   # Projection
        2_8) echo 45 ;;   # Projection
        2_9) echo 67 ;;   # Projection
        2_10) echo 56 ;;  # Validated
        2_11) echo 81 ;;  # Projection
        2_12) echo 69 ;;  # Projection
        # From BOSS_3
        3_4) echo 12 ;;   # Validated
        3_5) echo 24 ;;   # Projection
        3_6) echo 54 ;;   # Projection
        3_7) echo 52 ;;   # Projection
        3_8) echo 57 ;;   # Projection
        3_9) echo 69 ;;   # Projection
        3_10) echo 81 ;;  # Projection
        3_11) echo 69 ;;  # Projection
        3_12) echo 51 ;;  # Validated
        # From BOSS_4
        4_5) echo 12 ;;   # Validated
        4_6) echo 42 ;;   # Projection
        4_7) echo 82 ;;   # Projection
        4_8) echo 69 ;;   # Projection
        4_9) echo 73 ;;   # Projection
        4_10) echo 69 ;;  # Projection
        4_11) echo 55 ;;  # Validated
        4_12) echo 40 ;;  # Validated
        # From BOSS_5
        5_6) echo 28 ;;   # Validated
        5_7) echo 60 ;;   # Projection
        5_8) echo 76 ;;   # Projection
        5_9) echo 69 ;;   # Projection
        5_10) echo 55 ;;  # Validated
        5_11) echo 45 ;;  # Projection
        5_12) echo 33 ;;  # Validated
        # From BOSS_6
        6_7) echo 25 ;;   # Validated
        6_8) echo 52 ;;   # Validated
        6_9) echo 63 ;;   # Validated
        6_10) echo 54 ;;  # Projection
        6_11) echo 42 ;;  # Projection
        6_12) echo 30 ;;  # Validated
        # From BOSS_7
        7_8) echo 28 ;;   # Validated
        7_9) echo 42 ;;   # Projection
        7_10) echo 54 ;;  # Projection
        7_11) echo 66 ;;  # Projection
        7_12) echo 78 ;;  # Projection
        # From BOSS_8
        8_9) echo 12 ;;   # Validated
        8_10) echo 24 ;;  # Projection
        8_11) echo 36 ;;  # Projection
        8_12) echo 48 ;;  # Projection
        # From BOSS_9
        9_10) echo 12 ;;  # Validated
        9_11) echo 22 ;;  # Validated
        9_12) echo 36 ;;  # Projection
        # From BOSS_10
        10_11) echo 12 ;; # Validated
        10_12) echo 24 ;; # Projection
        # From BOSS_11
        11_12) echo 12 ;; # Validated
        # Default
        *) echo 0 ;;
    esac
}


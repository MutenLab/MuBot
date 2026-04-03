# Resolution Migration Status

Migration from **2992x1344** (Android Emulator) to **1920x1080** (BlueStacks).

### Config
- [x] `config/variables.sh` — EMULATOR_ID, venv PATH, tap coordinates, satanImpType, GAME_PACKAGE
- [x] `config/sanctuary_bosses.sh` — all 12 boss coordinates + entrance

### Python Scripts
- [x] `python/detectGoldenHealthBar.py`
- [x] `python/detectBossHealthBar.py`
- [x] `python/detectBossStatusOnSanctuaryMap.py`
- [x] `python/readNumbersOCR.py` — no migration needed
- [x] `python/readTextOCR.py` — no migration needed
- [x] `python/compareImages.py` — no migration needed
- [x] `python/optimizeBossRouteOnSanctuaryMap.py` — no migration needed
- [ ] `python/debug/debugBossColors.py`
- [ ] `python/debug/debugBossHealthBar.py`

### Utility Scripts
- [~] `bash/utils/visionUtils.sh` — remaining: isExpiredPopupVisible, checkRemainTimeForEventToEnd
- [~] `bash/utils/farmingUtils.sh` — remaining: other coordinate-dependent functions
- [~] `bash/utils/eventUtils.sh` — remaining: runWhileEvent tap coordinate
- [x] `bash/attack/smartAutoPlay.sh` — no migration needed
- [x] `bash/attack/autoPlaySkill.sh` — no migration needed
- [x] `bash/detection/checkBossStatus.sh` — no migration needed

### Tests
- [ ] `bash/test/debugHealthBar.sh` — NEEDS MIGRATION (X=1435, Y=353)
- [x] `bash/test/checkBossHealth.sh` — new
- [x] `bash/test/checkGoldenHealth.sh` — new
- [x] `bash/test/checkCurrentLocation.sh` — new
- [x] `bash/test/testOrientation.sh` — no migration needed
- [x] `bash/test/exportCrop.sh` — no migration needed
- [x] `bash/test/testCheckBuff.sh` — no migration needed
- [x] `bash/test/testReadTextFromZone.sh` — no migration needed
- [x] `bash/test/testIsLoggedIn.sh` — no migration needed
- [x] `bash/test/testCheckRemainTimeToStart.sh` — no migration needed
- [x] `bash/test/testEndOfEvent.sh` — no migration needed
- [x] `bash/test/testBloodCastle.sh` — no migration needed
- [x] `bash/test/testDevilSquare.sh` — no migration needed
- [x] `bash/test/testLeaveParty.sh` — no migration needed
- [x] `bash/test/tapAt.sh` — no migration needed

### Actions
- [x] `bash/actions/buyPotions.sh`
- [x] `bash/actions/login.sh` — no migration needed
- [x] `bash/actions/closeGame.sh` — no migration needed
- [x] `bash/actions/openGame.sh` — GAME_PACKAGE centralized
- [x] `bash/actions/selectCharacter.sh` — no migration needed
- [x] `bash/actions/switchWire.sh`
- [x] `bash/actions/wait.sh` — no migration needed
- [x] `bash/actions/openEventWindow.sh` — no migration needed
- [x] `bash/actions/recycle.sh`
- [x] `bash/actions/goToLandOfDemonsBuffSpot.sh` — no migration needed
- [x] `bash/actions/goToKanturuRelics2BuffSpot.sh` — no migration needed
- [x] `bash/actions/goToFoggyForestBuffSpot.sh` — no migration needed
- [ ] `bash/actions/kundunTrial.sh` — NEEDS MIGRATION

### Change Mode
- [x] `bash/changeMode/toAll.sh`
- [x] `bash/changeMode/toPeace.sh`
- [x] `bash/changeMode/toUnion.sh`

### Teleport
- [x] `bash/teleport/toLorencia.sh`
- [x] `bash/teleport/toFoggyForest.sh`
- [x] `bash/teleport/toSanctuary.sh`
- [x] `bash/teleport/toDivine.sh`
- [x] `bash/teleport/toKanturuRelics2.sh`
- [x] `bash/teleport/toEversongForest.sh`
- [ ] `bash/teleport/toHighHeaven.sh`
- [ ] `bash/teleport/toCorridorOfAgony.sh`
- [ ] `bash/teleport/toLandOfDemons.sh`
- [ ] `bash/teleport/toPurgatoryOfMissery.sh`
- [ ] `bash/teleport/toEndlessAbyss.sh`
- [ ] `bash/teleport/toPlainOfFourWinds1.sh`
- [ ] `bash/teleport/toSwampOfPeace.sh`
- [ ] `bash/teleport/toCorruptedLands.sh`
- [ ] `bash/teleport/toRaklion3.sh`
- [ ] `bash/teleport/toRaklion2.sh`
- [ ] `bash/teleport/toAbyssalFerea.sh`

### Travel
- [x] `bash/travel/foggyForest/toMobsFromCenter.sh`
- [x] `bash/travel/eversongForest/*.sh`
- [ ] `bash/travel/raklion3/toGoldenSpot.sh`
- [ ] `bash/travel/kanturuRelics2/toBuffSpotBot.sh`
- [ ] `bash/travel/swamp/350zone/*.sh`
- [ ] `bash/travel/swamp/370zone/*.sh`
- [ ] `bash/travel/swamp/380zone/*.sh`
- [ ] `bash/travel/swamp/390zone/*.sh`
- [ ] `bash/travel/sanctuary1/*.sh`
- [ ] `bash/travel/sanctuary2/*.sh`
- [ ] `bash/travel/corruptedLands/*.sh`
- [ ] `bash/travel/landOfDemons/*.sh`
- [ ] `bash/travel/plain1/*.sh`
- [ ] `bash/travel/abyssalFerea/*.sh`

### Boss
- [ ] `bash/boss/goToSwamp350Boss.sh`
- [ ] `bash/boss/goToSwamp360Boss.sh`
- [ ] `bash/boss/goToSwamp370Boss.sh`
- [ ] `bash/boss/goToSwamp380Boss.sh`

### Events
- [x] `bash/event/bloodCastle.sh`
- [x] `bash/event/devilSquare.sh`

### Images
- [x] `img/logout_marker.png`
- [x] `img/character_selection_marker.png`
- [x] `img/event_is_over_marker.png`
- [x] `img/check_auto_party.png`
- [x] `img/dead_title.png`
- [x] `img/satan.png`
- [x] `img/satan_old.png`
- [x] `img/angel.png`
- [x] `img/empty_team.png`
- [x] `img/recycle_popup_marker.png`
- [x] `img/attack_buff.png`
- [x] `img/shield_buff.png`
- [x] `img/open_now_button_marker.png`
- [ ] `img/expired_popup_marker.png`

### Main AutoPlay Scripts
- [x] `autoPlayGolden510EversongForest.sh` — no migration needed
- [x] `autoPlayMobFoggyForest.sh` — no migration needed
- [x] `farmSanctuaryBosses.sh`
- [ ] `autoPlayGolden410Plain1.sh`
- [ ] `autoPlayGolden400Plain1.sh`
- [ ] `autoPlayGolden390ZoneSwamp.sh`
- [ ] `autoPlayGolden370ZoneSwamp.sh`
- [ ] `autoPlayGolden360ZoneSwamp.sh`
- [ ] `autoPlayGolden350RightSwampWiredNav.sh`
- [ ] `autoPlayGoldenRaklion3WiredNav.sh`
- [ ] `autoPlay490Sanctuary2.sh`
- [ ] `autoPlay480LandOfDemons.sh`
- [ ] `autoPlay450CorruptedLands.sh`
- [ ] `autoPlay440Sanctuary1.sh`
- [ ] `autoPlay410MobPlain1.sh`
- [ ] `autoPlayGoldenAbyssalFerea.sh`
- [ ] `autoPlayMobAbyssalFerea.sh`

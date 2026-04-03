# MU Bot - Game Automation Scripts

Automation scripts for MU Origin 2 using ADB commands, screen capture, and OCR.

## Requirements

### Software
- **macOS** (tested on Darwin 25.3.0)
- **Homebrew** - package manager for macOS
- **Python 3.12+** - installed via Homebrew
- **ImageMagick 7+** - for screenshot cropping and image processing
- **ADB** - Android Debug Bridge for emulator communication

### Emulator
- **BlueStacks** - Android emulator
  - Resolution: **1920x1080**
  - ADB enabled: Settings > Advanced > toggle ADB ON
  - Default ADB address: `127.0.0.1:5555`

### Game
- **MU Origin 2** (package: `com.tszz.gpen.nowgg`) installed on BlueStacks

## Setup

### 1. Install dependencies

```bash
brew install python@3.12
brew install imagemagick
```

### 2. Install Python packages

```bash
pip3 install easyocr Pillow numpy scikit-image
```

### 3. Connect ADB to BlueStacks

Start BlueStacks, then:

```bash
adb connect 127.0.0.1:5555
adb devices  # verify connection
```

### 4. Configure project path

Create a `local.properties` file at the project root with your local project directory:

```bash
# local.properties
project.dir=/path/to/your/MuBot
emulator.id=127.0.0.1:5555
game.package=com.tszz.gpen.nowgg
use.immortal.satan=true
quick.buff=false
pickup.items.boss=10
pickup.items.golden=4
```

This file is gitignored — each computer needs its own. If omitted, the project path is auto-detected from the script location.

| Property | Description | Default |
|----------|-------------|---------|
| `project.dir` | Absolute path to the project directory | Auto-detected |
| `emulator.id` | ADB device ID (get with `adb devices`) | `127.0.0.1:5555` |
| `game.package` | Game package name installed on the emulator | `com.tszz.gpen.nowgg` |
| `use.immortal.satan` | When `true`, uses `satan_immortal.png` marker. When `false`, uses `satan.png`. | `true` |
| `quick.buff` | When `true`, only one buff (attack or defense) is needed during buff check. When `false`, both are required. | `false` |
| `pickup.items.boss` | Seconds to wait picking up items after killing a boss | `10` |
| `pickup.items.golden` | Seconds to wait picking up items after killing a golden monster | `4` |
| `autoPlay.attack.timeout` | Timeout in seconds for the smartAutoPlay attack script | `240` |
| `event.devil.square.hours` | Hours when Devil Square is available (comma-separated) | `0,2,4,6` |
| `event.devil.square.minutes.start` | Start minute of the Devil Square window | `0` |
| `event.devil.square.minutes.end` | End minute of the Devil Square window | `14` |
| `event.blood.castle.hours` | Hours when Blood Castle is available (comma-separated) | `1,3,5` |
| `event.blood.castle.minutes.start` | Start minute of the Blood Castle window | `0` |
| `event.blood.castle.minutes.end` | End minute of the Blood Castle window | `14` |
| `event.devil.square.max.fails` | Max failed attempts per hour before skipping Devil Square | `3` |
| `event.blood.castle.max.fails` | Max failed attempts per hour before skipping Blood Castle | `3` |
| `plan.before.devil.square` | Plan to set before Devil Square (0=no change, 1=plan 1, 2=plan 2) | `1` |
| `plan.after.devil.square` | Plan to set after Devil Square (0=no change, 1=plan 1, 2=plan 2) | `2` |
| `plan.before.blood.castle` | Plan to set before Blood Castle (0=no change, 1=plan 1, 2=plan 2) | `2` |
| `plan.after.blood.castle` | Plan to set after Blood Castle (0=no change, 1=plan 1, 2=plan 2) | `0` |

### 5. Update configuration

Edit `config/variables.sh`:

## Project Structure

```
bot/
├── config/
│   ├── variables.sh          # Main configuration (tap coordinates, settings)
│   └── sanctuary_bosses.sh   # Boss coordinates and travel times
├── python/
│   ├── detectGoldenHealthBar.py
│   ├── detectBossHealthBar.py
│   ├── detectBossStatusOnSanctuaryMap.py
│   ├── optimizeBossRouteOnSanctuaryMap.py
│   ├── readNumbersOCR.py
│   ├── readTextOCR.py
│   └── compareImages.py
├── bash/
│   ├── actions/              # Single actions (buy potions, recycle, etc.)
│   ├── attack/               # Auto-play and smart attack scripts
│   ├── boss/                 # Boss navigation scripts
│   ├── changeMode/           # PvP mode switching
│   ├── detection/            # Boss status detection
│   ├── event/                # Devil Square, Blood Castle
│   ├── teleport/             # Map teleportation scripts
│   ├── test/                 # Test scripts for debugging
│   ├── travel/               # In-map navigation scripts
│   └── utils/
│       ├── visionUtils.sh    # Screen reading, OCR, image comparison
│       ├── farmingUtils.sh   # Buff, validation, party management
│       └── eventUtils.sh     # Event timing and handling
├── img/                      # Reference images for screen comparison
├── autoPlay*.sh              # Main farming loop scripts
├── farmSanctuaryBosses.sh    # Sanctuary boss farming script
└── MIGRATION_STATUS.md       # Resolution migration tracking
```

## Usage

### Main scripts

```bash
# Farm golden monsters at Eversong Forest
bash autoPlayGolden510EversongForest.sh

# Farm mobs at Foggy Forest
bash autoPlayMobFoggyForest.sh

# Farm sanctuary bosses (level 1-6)
bash farmSanctuaryBosses.sh 2
```

### Key controls during farming

| Key | Action |
|-----|--------|
| `p` | Pause (5 min timeout) |
| `s` | Stop (15 min timeout) |
| `n` | Skip to next cycle |
| `b` | Force buff on next cycle |
| `q` | Force Devil Square event |
| `r` | Force Blood Castle event |
| Other | Abort script |

### Test scripts

```bash
# Check boss health bar detection
bash bash/test/checkBossHealth.sh

# Check golden monster detection
bash bash/test/checkGoldenHealth.sh

# Check current map location
bash bash/test/checkCurrentLocation.sh
```

### Quick screenshot

Double-click `screenshot.command` on Desktop to capture the emulator screen.

## Notes

- All tap coordinates are calibrated for **1920x1080** resolution
- Reference images in `img/` must match the current resolution
- See `MIGRATION_STATUS.md` for resolution migration progress

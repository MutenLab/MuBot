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
```

This file is gitignored — each computer needs its own. If omitted, the project path is auto-detected from the script location.

### 5. Update configuration

Edit `config/variables.sh`:
- `EMULATOR_ID` - ADB device ID (check with `adb devices`)
- `GAME_PACKAGE` - game package name
- `satanImpType` - set to `"satan"` or `"satan_old"` depending on equipped imp

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

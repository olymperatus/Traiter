#!/usr/bin/env bash
# Full installation script for the Traiter AI Assistant
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
QS_DIR="${QS_CONFIG_DIR:-$HOME/.config/quickshell/ii}"
MODULE_DIR="$QS_DIR/modules/ii/assistant"
SCRIPT_DIR="$QS_DIR/scripts/assistant"

echo "=== Traiter AI Assistant Installation ==="
echo ""

# 0. Check Python
PYTHON=""
for cmd in python3.12 python3.11 python3.10 python3; do
    if command -v "$cmd" &>/dev/null; then
        PYTHON="$cmd"
        break
    fi
done
if [ -z "$PYTHON" ]; then
    echo "ERROR: Python 3.10+ not found. Install it first."
    exit 1
fi
echo "  Python: $($PYTHON --version)"

# 0. Check prerequisites
if ! command -v git &>/dev/null; then
    echo "WARNING: git not found, skipping repo setup"
fi
if [ ! -d "$QS_DIR" ]; then
    echo "WARNING: $QS_DIR not found. Make sure QuickShell (ii) is installed."
    echo "  See: https://github.com/illogical-impulse/ii"
fi

# 1. Create venv and install dependencies
echo "[1/4] Setting up Python virtual environment..."
if [ ! -d "$PROJECT_DIR/backend/venv" ]; then
    $PYTHON -m venv "$PROJECT_DIR/backend/venv"
fi
source "$PROJECT_DIR/backend/venv/bin/activate"
pip install -r "$PROJECT_DIR/backend/requirements.txt" -q
echo "  Done"

# 2. Download voice model (if not present)
echo "[2/4] Checking TTS voice model..."
onix_count=$(ls "$PROJECT_DIR/backend/models/"*.onnx 2>/dev/null | wc -l)
if [ "$onix_count" -eq 0 ]; then
    echo "  Downloading Spanish voice model..."
    $PYTHON "$PROJECT_DIR/backend/download_voice.py" sharvard-medium
else
    echo "  Voice model found ($onix_count)"
fi

# 3. Symlink QML module
echo "[3/4] Linking QuickShell module..."
mkdir -p "$MODULE_DIR"
for f in "$PROJECT_DIR/quickshell"/*.qml; do
    name=$(basename "$f")
    ln -sf "$(realpath "$f")" "$MODULE_DIR/$name"
    echo "  $MODULE_DIR/$name"
done

# 4. Symlink Python backend
mkdir -p "$SCRIPT_DIR"
ln -sf "$(realpath "$PROJECT_DIR/backend/main.py")" "$SCRIPT_DIR/main.py"
echo "  $SCRIPT_DIR/main.py -> backend/main.py"

echo ""
echo "=== Installation complete ==="
echo ""
echo "Next steps:"
echo ""
echo "  1. Add your DeepSeek API key:"
echo "     Edit $PROJECT_DIR/backend/config.json"
echo "     Set \"api_key\": \"sk-your-key-here\""
echo "     Get a key at https://platform.deepseek.com"
echo ""
echo "  2. Register the module in your panel family:"
echo "     Edit $QS_DIR/panelFamilies/IllogicalImpulseFamily.qml"
echo '     Add: PanelLoader { component: Assistant {} }'
echo ""
echo "  3. Add a keybind (Hyprland):"
echo "     In your keybinds.lua:"
echo '     hl.bind("SUPER + H", hl.dsp.global("assistant:toggle"),'
echo '         { description = "Assistant: Toggle AI Assistant" })'
echo ""
echo "  4. Restart QuickShell:"
echo "     killall quickshell; qs -c ii &"
echo ""
echo "Quick links:"
echo "  Monitor:  ./monitor.sh -w"
echo "  Docs:     cat README.md"

#!/usr/bin/env bash
# Symlink assistant module into QuickShell ii config
set -e

QS_DIR="$HOME/.config/quickshell/ii"
MODULE_DIR="$QS_DIR/modules/ii/assistant"
SCRIPT_DIR="$QS_DIR/scripts/assistant"

echo "Creating symlinks for Assistant module..."

# Link QML module files
mkdir -p "$MODULE_DIR"
for f in "$(dirname "$0")/quickshell"/*.qml; do
    name=$(basename "$f")
    ln -sf "$(realpath "$f")" "$MODULE_DIR/$name"
    echo "  $MODULE_DIR/$name -> $f"
done

# Link Python backend
mkdir -p "$SCRIPT_DIR"
ln -sf "$(realpath "$(dirname "$0")/backend/main.py")" "$SCRIPT_DIR/main.py"

echo "Done! Assistant module linked."
echo ""
echo "Next steps:"
echo "  1. Add 'PanelLoader { component: Assistant {} }' to IllogicalImpulseFamily.qml"
echo "  2. Add keybind 'SUPER + H' → assistant:toggle in keybinds.lua"
echo "  3. Reload QuickShell: qs -c ii &"

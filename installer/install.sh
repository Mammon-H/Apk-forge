#!/data/data/com.termux/files/usr/bin/bash

set -e

FORGE_ROOT="$HOME/.apk-forge"

clear
echo "================================="
echo "        APK Forge Installer"
echo "================================="

echo ""
echo "[1/3] Installing dependencies..."
bash "$FORGE_ROOT/installer/deps.sh"

echo ""
echo "[2/3] Preparing Android SDK..."
bash "$FORGE_ROOT/installer/sdk.sh"

echo ""
echo "[3/3] Installing APK Forge CLI..."

chmod +x "$FORGE_ROOT/cli/apkforge"

ln -sf "$FORGE_ROOT/cli/apkforge" "$PREFIX/bin/apkforge"

echo ""
echo "================================="
echo "      Installation Complete"
echo "================================="
echo ""
echo "Run APK Forge with:"
echo ""
echo "apkforge"
echo ""

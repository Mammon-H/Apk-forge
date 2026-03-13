#!/data/data/com.termux/files/usr/bin/bash

set -e

echo "================================="
echo "        Installing APK Forge"
echo "================================="

INSTALL_DIR="$HOME/.apk-forge"
TEMP_DIR="$HOME/.apkforge-install"

echo ""
echo "[1/4] Cloning APK Forge repository..."

rm -rf "$TEMP_DIR"

git clone https://github.com/Mammon-H/Apk-forge.git "$TEMP_DIR"

echo ""
echo "[2/4] Installing system files..."

mkdir -p "$INSTALL_DIR"

cp -r "$TEMP_DIR"/* "$INSTALL_DIR/"

echo ""
echo "[3/4] Running internal installer..."

bash "$INSTALL_DIR/installer/install.sh"

echo ""
echo "[4/4] Cleaning temporary files..."

rm -rf "$TEMP_DIR"

echo ""
echo "================================="
echo " APK Forge Installed Successfully"
echo "================================="
echo ""
echo "Run:"
echo ""
echo "apkforge"
echo ""

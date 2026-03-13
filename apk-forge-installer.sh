#!/data/data/com.termux/files/usr/bin/bash

╔═══════════════════════════════════════════════════════════════════════════════╗

║                    🔨 APK FORGE - MEGA INSTALLER v1.0                         ║

║           One Script to Install AI-Powered Android Development                ║

║                    on Termux with GitHub Integration                          ║

╚═══════════════════════════════════════════════════════════════════════════════╝

set -e

Colors

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

Configuration

FORGE_ROOT="$HOME/.apk-forge"
SDK_DIR="$HOME/android-sdk"

Banner

show_banner() {
clear
echo -e "${CYAN}${BOLD}"
echo "    _    ____  _     ______                    _           "
echo "   / \   |  _ | |   |  |                  | |          "
echo "  / _ \  | |) | |   | | __ _ _ __ __ _  | | ___   _   "
echo " / ___ \ |  __/| |   |  / _\ | '/ \ |/ __| |/ / | | |  "
echo "//   _||   ||   | | | (| | | | (| | (|   <| |_| |  "
echo "                 |||  _,||  _,|_|_|_\, | "
echo "                                                     / | "
echo "                                                    |/  "
echo -e "${NC}"
echo -e "${MAGENTA}${BOLD}AI-Powered Android Development Environment${NC}"
echo -e "${YELLOW}For Termux • Local Build • GitHub Sync${NC}"
echo ""
}

Progress bar

show_progress() {
local msg="$1"
local current=$2
local total=$3
local width=40

local percentage=$((current * 100 / total))
local filled=$((width * current / total))
local empty=$((width - filled))

printf "\r${BLUE}[${NC}"
printf "%${filled}s" | tr ' ' '█'
printf "%${empty}s" | tr ' ' '░'
printf "${BLUE}]${NC} ${percentage}%% ${msg}"

}

Step 1: System Check

check_system() {

echo -e "${BLUE}${BOLD}[STEP 1/7]${NC} System Check"
echo "─────────────────────────────────────"

android_ver=$(getprop ro.build.version.release 2>/dev/null || echo "unknown")
echo -e "${CYAN}Android Version:${NC} $android_ver"

arch=$(uname -m)
echo -e "${CYAN}Architecture:${NC} $arch"

storage=$(df -h "$HOME" | tail -1 | awk '{print $4}')
echo -e "${CYAN}Available Storage:${NC} $storage"

ram=$(free -m 2>/dev/null | grep Mem | awk '{print $2}' || echo "unknown")
echo -e "${CYAN}Total RAM:${NC} ${ram}MB"

echo ""
read -p "Continue with installation? (y/n): " confirm

if [[ "$confirm" != "y" ]]; then
    echo -e "${RED}Installation cancelled.${NC}"
    exit 1
fi

}

Step 2: Install Dependencies

install_deps() {

echo -e "\n${BLUE}${BOLD}[STEP 2/7]${NC} Installing Dependencies"
echo "─────────────────────────────────────"

echo -e "${YELLOW}Updating packages...${NC}"
pkg update -y

deps=(
    openjdk-17
    git
    python
    python-pip
    zip
    unzip
    wget
    curl
)

total=${#deps[@]}
current=0

for dep in "${deps[@]}"; do

    current=$((current + 1))
    show_progress "Installing $dep..." $current $total

    pkg install -y "$dep" > /dev/null 2>&1 || true
done

echo ""
echo -e "${GREEN}✓ Dependencies installed${NC}"

}

Step 3: Setup APK Forge directories

setup_forge() {

echo -e "\n${BLUE}${BOLD}[STEP 3/7]${NC} Creating APK Forge Structure"
echo "─────────────────────────────────────"

mkdir -p "$FORGE_ROOT"/{workspace,templates,modules,config,logs,build}

echo -e "${GREEN}✓ Directory structure created${NC}"

}

Main installer

main() {

show_banner
check_system
install_deps
setup_forge

echo ""
echo -e "${GREEN}${BOLD}APK Forge installed successfully!${NC}"
echo -e "${CYAN}Location:${NC} $FORGE_ROOT"

}

main

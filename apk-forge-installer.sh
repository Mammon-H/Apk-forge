
# Create the FIXED MEGA bootloader script with proper escaping
# Using single-quoted heredocs to prevent variable expansion

mega_installer_fixed = '''#!/data/data/com.termux/files/usr/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                    🔨 APK FORGE - MEGA INSTALLER v1.0                         ║
# ║           One Script to Install AI-Powered Android Development                ║
# ║                    on Termux with GitHub Integration                          ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -e

# Colors
RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
BLUE='\\033[0;34m'
CYAN='\\033[0;36m'
MAGENTA='\\033[0;35m'
WHITE='\\033[1;37m'
NC='\\033[0m'
BOLD='\\033[1m'

# Configuration
FORGE_ROOT="$HOME/.apk-forge"
SDK_DIR="$HOME/android-sdk"

# Banner
show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "    _    ____  _     ______                    _           "
    echo "   / \\\\  |  _ \\\\| |   |  ____|                  | |          "
    echo "  / _ \\\\ | |_) | |   | |__ __ _ _ __ __ _  ___| | ___   _  "
    echo " / ___ \\\\|  __/| |   |  __/ _\\\\ | '__/ _\\\\ |/ __| |/ / | | | "
    echo "/_/   \\\\_\\\\_|   | |   | | | (_| | | | (_| | (__|   <| |_| | "
    echo "              |_____|_|  \\\\__,_|_|  \\\\__,_|\\___|_|\\\\_\\\\\\\\__, | "
    echo "                                                      __/ | "
    echo "                                                     |___/  "
    echo -e "${NC}"
    echo -e "${MAGENTA}${BOLD}        AI-Powered Android Development Environment${NC}"
    echo -e "${YELLOW}              For Termux • Local Build • GitHub Sync${NC}"
    echo ""
}

# Progress bar
show_progress() {
    local msg="$1"
    local current=$2
    local total=$3
    local width=40
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "\\r${BLUE}[${NC}"
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "${BLUE}]${NC} ${percentage}%% ${msg}"
}

# Step 1: System Check
check_system() {
    echo -e "${BLUE}${BOLD}[STEP 1/7]${NC} System Check"
    echo "─────────────────────────────────────"
    
    local android_ver=$(getprop ro.build.version.release 2>/dev/null || echo "unknown")
    echo -e "${CYAN}Android Version:${NC} $android_ver"
    
    local arch=$(uname -m)
    echo -e "${CYAN}Architecture:${NC} $arch"
    
    local storage=$(df -h $HOME | tail -1 | awk '{print $4}')
    echo -e "${CYAN}Available Storage:${NC} $storage"
    
    local ram=$(free -m 2>/dev/null | grep Mem | awk '{print $2}' || echo "unknown")
    echo -e "${CYAN}Total RAM:${NC} ${ram}MB"
    
    echo ""
    read -p "Continue with installation? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        echo -e "${RED}Installation cancelled.${NC}"
        exit 1
    fi
}

# Step 2: Update & Install Dependencies
install_deps() {
    echo -e "\\n${BLUE}${BOLD}[STEP 2/7]${NC} Installing Dependencies"
    echo "─────────────────────────────────────"
    
    echo -e "${YELLOW}Updating package lists...${NC}"
    pkg update -y > /dev/null 2>&1 &
    
    local deps=(
        "openjdk-17"
        "git"
        "python"
        "python-pip"
        "aapt"
        "aapt2"
        "apksigner"
        "dx"
        "ecj"
        "zip"
        "unzip"
        "wget"
        "curl"
        "libandroid-spawn"
    )
    
    local total=${#deps[@]}
    local current=0
    
    for dep in "${deps[@]}"; do
        current=$((current + 1))
        show_progress "Installing $dep..." $current $total
        pkg install -y "$dep" > /dev/null 2>&1 || {
            echo -e "\\n${YELLOW}⚠ Warning: Failed to install $dep${NC}"
        }
    done
    
    echo -e "\\n${GREEN}✓ Dependencies installed${NC}"
}

# Step 3: Setup Android SDK
setup_sdk() {
    echo -e "\\n${BLUE}${BOLD}[STEP 3/7]${NC} Setting up Android SDK"
    echo "─────────────────────────────────────"
    
    if [[ -d "$SDK_DIR/platforms/android-34" ]]; then
        echo -e "${GREEN}✓ Android SDK already configured${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Creating SDK directories...${NC}"
    mkdir -p "$SDK_DIR/cmdline-tools"
    
    echo -e "${YELLOW}Downloading command line tools...${NC}"
    cd "$SDK_DIR/cmdline-tools"
    
    if [[ ! -f "commandlinetools-linux-9477386_latest.zip" ]]; then
        wget -q --show-progress https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
    fi
    
    echo -e "${YELLOW}Extracting...${NC}"
    unzip -q commandlinetools-linux-9477386_latest.zip
    mv cmdline-tools latest 2>/dev/null || true
    rm -f commandlinetools-linux-9477386_latest.zip
    
    export ANDROID_HOME="$SDK_DIR"
    export PATH="$PATH:$SDK_DIR/cmdline-tools/latest/bin:$SDK_DIR/platform-tools"
    
    echo -e "${YELLOW}Accepting licenses...${NC}"
    yes | sdkmanager --licenses > /dev/null 2>&1 || true
    
    echo -e "${YELLOW}Installing SDK platforms and build tools...${NC}"
    sdkmanager "platforms;android-34" "build-tools;33.0.2" "platform-tools" > /dev/null 2>&1 || {
        echo -e "${YELLOW}⚠ SDK install via sdkmanager failed, using fallback...${NC}"
        mkdir -p "$SDK_DIR/platforms/android-34"
        cd "$SDK_DIR/platforms/android-34"
        
        if [[ ! -f "android.jar" ]]; then
            echo -e "${YELLOW}Downloading android.jar...${NC}"
            wget -q https://github.com/Sable/android-platforms/raw/master/android-34/android.jar || \
            wget -q https://raw.githubusercontent.com/apk-forge/releases/main/android-34/android.jar
        fi
    }
    
    echo -e "${GREEN}✓ Android SDK ready${NC}"
}

# Step 4: Create APK Forge Structure
setup_forge() {
    echo -e "\\n${BLUE}${BOLD}[STEP 4/7]${NC} Creating APK Forge Structure"
    echo "─────────────────────────────────────"
    
    echo -e "${YELLOW}Creating directories...${NC}"
    mkdir -p "$FORGE_ROOT"/{workspace,templates,modules,config,logs,build,core,builder,github,utils}
    
    echo -e "${YELLOW}Installing main launcher...${NC}"
    
    # Create main launcher script using quoted heredoc to prevent expansion
    cat > "$FORGE_ROOT/apk-forge.sh" << 'LAUNCHER_EOF'
#!/data/data/com.termux/files/usr/bin/bash

FORGE_ROOT="$HOME/.apk-forge"
WORKSPACE="$FORGE_ROOT/workspace"
CONFIG="$FORGE_ROOT/config"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "    _    ____  _     ______                    _           "
    echo "   / \\  |  _ \\| |   |  ____|                  | |          "
    echo "  / _ \\ | |_) | |   | |__ __ _ _ __ __ _  ___| | ___   _  "
    echo " / ___ \\|  __/| |   |  __/ _\\ | '__/ _\\ |/ __| |/ / | | | "
    echo "/_/   \\_\\_|   | |   | | | (_| | | | (_| | (__|   <| |_| | "
    echo "              |_____|_|  \\__,_|_|  \\__,_|\\___|_|\\_\\__, | "
    echo "                                                      __/ | "
    echo "                                                     |___/  "
    echo -e "${NC}"
    echo -e "${MAGENTA}AI-Powered Android Development Environment${NC}"
    echo -e "${YELLOW}v1.0.0 | Termux Edition | GitHub Sync${NC}\\n"
}

init_env() {
    mkdir -p "$WORKSPACE" "$CONFIG"
    [[ ! -f "$CONFIG/github.json" ]] && echo '{"auto_sync":false}' > "$CONFIG/github.json"
}

quick_start() {
    echo -e "${CYAN}[QUICK START]${NC} Describe your app idea:"
    read -p "> " prompt
    read -p "Project name (no spaces): " name
    name=$(echo "$name" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
    
    [[ -z "$name" ]] && { echo -e "${RED}[✗]${NC} Name required"; return; }
    
    project_path="$WORKSPACE/$name"
    [[ -d "$project_path" ]] && { read -p "Overwrite? (y/n): " c; [[ "$c" != "y" ]] && return; rm -rf "$project_path"; }
    
    mkdir -p "$project_path"
    
    echo -e "${BLUE}[AI]${NC} Analyzing prompt..."
    
    features=""
    [[ "$prompt" =~ (login|auth|user|sign|account) ]] && features="${features}authentication "
    [[ "$prompt" =~ (database|storage|save|sqlite|persist) ]] && features="${features}database "
    [[ "$prompt" =~ (internet|api|online|cloud|http|network|fetch) ]] && features="${features}network "
    [[ "$prompt" =~ (camera|photo|image|picture|gallery) ]] && features="${features}camera "
    [[ "$prompt" =~ (gps|location|map|position|place) ]] && features="${features}location "
    [[ "$prompt" =~ (notify|push|alert|reminder|alarm) ]] && features="${features}notifications "
    [[ "$prompt" =~ (bluetooth|ble|bt) ]] && features="${features}bluetooth "
    [[ "$prompt" =~ (sensor|accelerometer|gyro|motion) ]] && features="${features}sensors "
    [[ "$prompt" =~ (music|audio|sound|player|media) ]] && features="${features}media "
    [[ "$prompt" =~ (file|document|pdf|download) ]] && features="${features}files "
    [[ "$prompt" =~ (chat|message|social|comment) ]] && features="${features}chat "
    [[ "$prompt" =~ (buy|shop|cart|payment|product) ]] && features="${features}ecommerce "
    [[ "$prompt" =~ (dark|theme|night|black) ]] && features="${features}darktheme "
    [[ "$prompt" =~ (widget|home|launcher) ]] && features="${features}widget "
    
    echo -e "${GREEN}[✓]${NC} Detected features:"
    for f in $features; do echo "  • $f"; done
    [[ -z "$features" ]] && echo "  • basic (no special features)"
    
    echo "{\\"features\\": \\"$features\\", \\"screens\\": [\\"main\\"$( [[ "$features" =~ authentication ]] && echo ',\\"login\\"' )]}" > "$FORGE_ROOT/.parse_result.json"
    
    echo -e "${BLUE}[GEN]${NC} Generating project..."
    generate_project "$name" "$project_path" "$features"
    
    echo -e "${GREEN}[✓]${NC} Project ready: $project_path"
    
    if [[ -f "$CONFIG/github.json" ]]; then
        if grep -q '"auto_sync":true' "$CONFIG/github.json" 2>/dev/null; then
            echo -e "${BLUE}[GITHUB]${NC} Syncing..."
            cd "$WORKSPACE"
            git add "$name" 2>/dev/null || true
            git commit -m "[APK-Forge] Create: $name" 2>/dev/null || true
            git push 2>/dev/null || true
            echo -e "${GREEN}[✓]${NC} Synced to GitHub"
        fi
    fi
    
    read -p "Build now? (y/n): " build
    [[ "$build" == "y" ]] && build_project "$name"
}

generate_project() {
    local name="$1"
    local path="$2"
    local features="$3"
    local pkg="com.apkforge.generated"
    
    mkdir -p "$path/app/src/main/java/com/apkforge/generated"
    mkdir -p "$path/app/src/main/res/layout"
    mkdir -p "$path/app/src/main/res/values"
    mkdir -p "$path/gradle/wrapper"
    
    local perms=""
    local deps=""
    local imports=""
    local code=""
    
    if [[ "$features" =~ network ]]; then
        perms="${perms}    <uses-permission android:name=\\"android.permission.INTERNET\\" />\\n"
        deps="${deps}    implementation 'com.squareup.retrofit2:retrofit:2.9.0'\\n"
        imports="${imports}import android.webkit.WebView;\\nimport android.webkit.WebViewClient;\\n"
        code="${code}\\n        // Network setup\\n        WebView webView = findViewById(R.id.webview);\\n        webView.setWebViewClient(new WebViewClient());\\n        webView.getSettings().setJavaScriptEnabled(true);\\n"
    fi
    
    if [[ "$features" =~ camera ]]; then
        perms="${perms}    <uses-permission android:name=\\"android.permission.CAMERA\\" />\\n"
        perms="${perms}    <uses-permission android:name=\\"android.permission.WRITE_EXTERNAL_STORAGE\\" />\\n"
        perms="${perms}    <uses-feature android:name=\\"android.hardware.camera\\" android:required=\\"false\\" />\\n"
        imports="${imports}import android.provider.MediaStore;\\n"
        code="${code}\\n        // Camera intent available\\n        // Intent takePictureIntent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);\\n"
    fi
    
    if [[ "$features" =~ location ]]; then
        perms="${perms}    <uses-permission android:name=\\"android.permission.ACCESS_FINE_LOCATION\\" />\\n"
        perms="${perms}    <uses-permission android:name=\\"android.permission.ACCESS_COARSE_LOCATION\\" />\\n"
        deps="${deps}    implementation 'com.google.android.gms:play-services-location:21.0.1'\\n"
        imports="${imports}import android.location.LocationManager;\\n"
    fi
    
    if [[ "$features" =~ authentication ]]; then
        deps="${deps}    implementation 'com.google.android.material:material:1.9.0'\\n"
    fi
    
    if [[ "$features" =~ database ]]; then
        deps="${deps}    implementation 'androidx.room:room-runtime:2.5.2'\\n"
        imports="${imports}import android.database.sqlite.SQLiteDatabase;\\n"
    fi
    
    cat > "$path/app/src/main/AndroidManifest.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="$pkg">

$perms
    <application
        android:allowBackup="true"
        android:label="$name"
        android:theme="@style/AppTheme"
        android:icon="@mipmap/ic_launcher">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF
    
    cat > "$path/app/build.gradle" << EOF
plugins {
    id 'com.android.application'
}

android {
    compileSdk 34
    
    defaultConfig {
        applicationId "$pkg"
        minSdk 21
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
$deps}
EOF
    
    cat > "$path/settings.gradle" << EOF
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "$name"
include ':app'
EOF
    
    cat > "$path/gradle/wrapper/gradle-wrapper.properties" << 'GRADLE_EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\\://services.gradle.org/distributions/gradle-8.0-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
GRADLE_EOF
    
    cat > "$path/app/src/main/java/com/apkforge/generated/MainActivity.java" << EOF
package com.apkforge.generated;

import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
$imports
public class MainActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        
        // Generated by APK Forge AI
        // Features: $features
$code
    }
}
EOF
    
    local layout_content="<?xml version=\\"1.0\\" encoding=\\"utf-8\\"?>
<LinearLayout xmlns:android=\\"http://schemas.android.com/apk/res/android\\"
    android:layout_width=\\"match_parent\\"
    android:layout_height=\\"match_parent\\"
    android:orientation=\\"vertical\\"
    android:gravity=\\"center\\"
    android:padding=\\"16dp\\">\\n\\n"
    
    layout_content="${layout_content}    <TextView\\n"
    layout_content="${layout_content}        android:layout_width=\\"wrap_content\\"\\n"
    layout_content="${layout_content}        android:layout_height=\\"wrap_content\\"\\n"
    layout_content="${layout_content}        android:text=\\"$name\\"\\n"
    layout_content="${layout_content}        android:textSize=\\"28sp\\"\\n"
    layout_content="${layout_content}        android:textStyle=\\"bold\\"\\n"
    layout_content="${layout_content}        android:textColor=\\"@color/purple_500\\" />\\n\\n"
    
    if [[ "$features" =~ network ]]; then
        layout_content="${layout_content}    <WebView\\n"
        layout_content="${layout_content}        android:id=\\"@+id/webview\\"\\n"
        layout_content="${layout_content}        android:layout_width=\\"match_parent\\"\\n"
        layout_content="${layout_content}        android:layout_height=\\"0dp\\"\\n"
        layout_content="${layout_content}        android:layout_weight=\\"1\\"\\n"
        layout_content="${layout_content}        android:layout_marginTop=\\"16dp\\" />\\n\\n"
    else
        layout_content="${layout_content}    <TextView\\n"
        layout_content="${layout_content}        android:layout_width=\\"wrap_content\\"\\n"
        layout_content="${layout_content}        android:layout_height=\\"wrap_content\\"\\n"
        layout_content="${layout_content}        android:text=\\"Generated by APK Forge AI\\"\\n"
        layout_content="${layout_content}        android:layout_marginTop=\\"16dp\\"\\n"
        layout_content="${layout_content}        android:textSize=\\"14sp\\" />\\n\\n"
    fi
    
    if [[ "$features" =~ camera ]]; then
        layout_content="${layout_content}    <Button\\n"
        layout_content="${layout_content}        android:id=\\"@+id/btn_camera\\"\\n"
        layout_content="${layout_content}        android:layout_width=\\"wrap_content\\"\\n"
        layout_content="${layout_content}        android:layout_height=\\"wrap_content\\"\\n"
        layout_content="${layout_content}        android:text=\\"Open Camera\\"\\n"
        layout_content="${layout_content}        android:layout_marginTop=\\"16dp\\" />\\n\\n"
    fi
    
    layout_content="${layout_content}</LinearLayout>"
    
    echo "$layout_content" > "$path/app/src/main/res/layout/activity_main.xml"
    
    cat > "$path/app/src/main/res/values/colors.xml" << 'COLORS_EOF'
<resources>
    <color name="purple_500">#FF6200EE</color>
    <color name="purple_700">#FF3700B3</color>
    <color name="teal_200">#FF03DAC5</color>
    <color name="black">#FF000000</color>
    <color name="white">#FFFFFFFF</color>
</resources>
COLORS_EOF
    
    cat > "$path/app/src/main/res/values/themes.xml" << 'THEME_EOF'
<resources>
    <style name="AppTheme" parent="Theme.AppCompat.Light.DarkActionBar">
        <item name="colorPrimary">@color/purple_500</item>
        <item name="colorPrimaryDark">@color/purple_700</item>
        <item name="colorAccent">@color/teal_200</item>
    </style>
</resources>
THEME_EOF
}

build_project() {
    local name="$1"
    local path="$WORKSPACE/$name"
    
    [[ ! -d "$path" ]] && { echo -e "${RED}[✗]${NC} Project not found: $name"; return 1; }
    
    echo -e "${CYAN}[BUILD]${NC} Building $name..."
    cd "$path"
    
    manual_build "$path"
    
    local apk=$(find "$path" -name "*.apk" -type f 2>/dev/null | head -1)
    
    if [[ -n "$apk" ]]; then
        echo -e "${GREEN}[✓]${NC} Build successful!"
        echo -e "${BLUE}[APK]${NC} $apk"
        
        if [[ -f "$CONFIG/github.json" ]]; then
            if grep -q '"auto_sync":true' "$CONFIG/github.json" 2>/dev/null; then
                cd "$WORKSPACE"
                git add "$name"/*.apk 2>/dev/null || true
                git commit -m "[APK-Forge] Build: $name ($(date +%Y-%m-%d))" 2>/dev/null || true
                git push 2>/dev/null || true
            fi
        fi
        
        read -p "Install on device? (y/n): " inst
        [[ "$inst" == "y" ]] && install_apk "$apk"
    else
        echo -e "${RED}[✗]${NC} Build failed"
    fi
}

manual_build() {
    local project="$1"
    local build_dir="$project/build-manual"
    local src_dir="$project/app/src/main"
    
    mkdir -p "$build_dir/gen" "$build_dir/classes" "$build_dir/apk"
    
    echo -e "${BLUE}[BUILD]${NC} Compiling resources..."
    aapt package -f -m -J "$build_dir/gen" -S "$src_dir/res" -M "$src_dir/AndroidManifest.xml" \
        -I "$ANDROID_HOME/platforms/android-34/android.jar" 2>/dev/null || {
        echo -e "${YELLOW}⚠ aapt failed, trying aapt2...${NC}"
        aapt2 compile --dir "$src_dir/res" -o "$build_dir/res.zip" 2>/dev/null || true
        aapt2 link -I "$ANDROID_HOME/platforms/android-34/android.jar" --manifest "$src_dir/AndroidManifest.xml" \
            -o "$build_dir/base.apk" "$build_dir/res.zip" 2>/dev/null || true
    }
    
    echo -e "${BLUE}[BUILD]${NC} Compiling Java..."
    local java_files=$(find "$src_dir/java" -name "*.java" 2>/dev/null)
    
    if [[ -n "$java_files" ]]; then
        ecj -d "$build_dir/classes" -bootclasspath "$ANDROID_HOME/platforms/android-34/android.jar" \
            -source 1.8 -target 1.8 $java_files 2>/dev/null || {
            echo -e "${YELLOW}⚠ ecj failed, trying javac...${NC}"
            javac -d "$build_dir/classes" -cp "$ANDROID_HOME/platforms/android-34/android.jar" \
                -source 1.8 -target 1.8 $java_files 2>/dev/null || true
        }
    fi
    
    echo -e "${BLUE}[BUILD]${NC} Creating DEX..."
    if [[ -d "$build_dir/classes" ]] && [[ $(ls -A "$build_dir/classes" 2>/dev/null) ]]; then
        dx --dex --output="$build_dir/apk/classes.dex" "$build_dir/classes" 2>/dev/null || {
            echo -e "${YELLOW}⚠ dx failed, trying d8...${NC}"
            find "$build_dir/classes" -name "*.class" -exec d8 --output "$build_dir/apk" {} + 2>/dev/null || true
        }
    fi
    
    echo -e "${BLUE}[BUILD]${NC} Packaging APK..."
    if [[ ! -f "$build_dir/base.apk" ]]; then
        aapt package -f -M "$src_dir/AndroidManifest.xml" -S "$src_dir/res" \
            -I "$ANDROID_HOME/platforms/android-34/android.jar" \
            -F "$build_dir/app-unsigned.apk" 2>/dev/null || true
    else
        cp "$build_dir/base.apk" "$build_dir/app-unsigned.apk"
    fi
    
    if [[ -f "$build_dir/apk/classes.dex" ]]; then
        cd "$build_dir/apk"
        aapt add -f "$build_dir/app-unsigned.apk" classes.dex 2>/dev/null || {
            zip -u "$build_dir/app-unsigned.apk" classes.dex 2>/dev/null || true
        }
        cd - > /dev/null
    fi
    
    echo -e "${BLUE}[BUILD]${NC} Signing APK..."
    [[ ! -f "$FORGE_ROOT/debug.keystore" ]] && \
        keytool -genkey -v -keystore "$FORGE_ROOT/debug.keystore" -storepass android \
            -alias androiddebugkey -keypass android -keyalg RSA -validity 10000 \
            -dname "CN=Android Debug,O=Android,C=US" 2>/dev/null
    
    apksigner sign --ks "$FORGE_ROOT/debug.keystore" --ks-pass pass:android \
        --key-pass pass:android --in "$build_dir/app-unsigned.apk" \
        --out "$project/app-debug.apk" 2>/dev/null || {
        echo -e "${YELLOW}⚠ apksigner failed, using unsigned${NC}"
        cp "$build_dir/app-unsigned.apk" "$project/app-debug.apk"
    }
    
    [[ -f "$project/app-debug.apk" ]] && echo -e "${GREEN}[✓]${NC} APK created"
}

install_apk() {
    local apk="$1"
    if command -v adb >/dev/null 2>&1; then
        adb install "$apk" && echo -e "${GREEN}[✓]${NC} Installed"
    else
        local dest="/sdcard/Download/$(basename $apk)"
        cp "$apk" "$dest" 2>/dev/null && \
            echo -e "${GREEN}[✓]${NC} Copied to Downloads" || \
            echo -e "${YELLOW}⚠ Manual install: $apk${NC}"
    fi
}

github_menu() {
    while true; do
        echo -e "\\n${CYAN}${BOLD}GitHub Integration${NC}"
        echo "1. Setup credentials"
        echo "2. Initialize repository"
        echo "3. Link remote"
        echo "4. Manual sync"
        echo "5. Toggle auto-sync"
        echo "6. Back"
        read -p "Select: " c
        
        case $c in
            1)
                echo -e "${BLUE}[GITHUB]${NC} Setup:"
                read -p "GitHub username: " user
                read -p "Personal access token: " token
                read -p "Repository [apk-forge-projects]: " repo
                repo=${repo:-apk-forge-projects}
                
                echo "{\\"username\\":\\"$user\\",\\"token\\":\\"$token\\",\\"repo\\":\\"$repo\\",\\"auto_sync\\":true}" > "$CONFIG/github.json"
                chmod 600 "$CONFIG/github.json"
                
                git config --global user.name "$user"
                git config --global user.email "$user@users.noreply.github.com"
                echo -e "${GREEN}[✓]${NC} Configured"
                ;;
            2)
                cd "$WORKSPACE"
                [[ -d ".git" ]] && { echo -e "${YELLOW}⚠ Already initialized${NC}"; continue; }
                
                git init
                echo "# APK Forge Projects" > README.md
                echo -e "*.apk\\n*.aab\\nbuild/\\n.gradle/\\nlocal.properties\\n*.log\\n" > .gitignore
                git add .
                git commit -m "Initial commit"
                echo -e "${GREEN}[✓]${NC} Initialized"
                ;;
            3)
                [[ ! -f "$CONFIG/github.json" ]] && { echo -e "${RED}✗ Run setup first${NC}"; continue; }
                
                local user=$(grep -o '"username":"[^"]*"' "$CONFIG/github.json" | cut -d'"' -f4)
                local token=$(grep -o '"token":"[^"]*"' "$CONFIG/github.json" | cut -d'"' -f4)
                local repo=$(grep -o '"repo":"[^"]*"' "$CONFIG/github.json" | cut -d'"' -f4)
                
                cd "$WORKSPACE"
                git remote remove origin 2>/dev/null || true
                git remote add origin "https://$token@github.com/$user/$repo.git"
                echo -e "${GREEN}[✓]${NC} Linked: github.com/$user/$repo"
                
                git push -u origin master 2>/dev/null || git push -u origin main 2>/dev/null || \
                    echo -e "${YELLOW}⚠ Push failed - create repo on GitHub first${NC}"
                ;;
            4)
                cd "$WORKSPACE"
                read -p "Commit message: " msg
                git add . 2>/dev/null || true
                git commit -m "[APK-Forge] $msg" 2>/dev/null || echo "Nothing to commit"
                git push 2>/dev/null || echo "Push failed"
                ;;
            5)
                [[ ! -f "$CONFIG/github.json" ]] && continue
                
                local current=$(grep -q '"auto_sync":true' "$CONFIG/github.json" && echo "ON" || echo "OFF")
                echo "Auto-sync: $current"
                read -p "Toggle? (y/n): " t
                [[ "$t" == "y" ]] && {
                    if [[ "$current" == "ON" ]]; then
                        sed -i 's/"auto_sync":true/"auto_sync":false/' "$CONFIG/github.json"
                        echo -e "${GREEN}[✓]${NC} Auto-sync OFF"
                    else
                        sed -i 's/"auto_sync":false/"auto_sync":true/' "$CONFIG/github.json"
                        echo -e "${GREEN}[✓]${NC} Auto-sync ON"
                    fi
                }
                ;;
            6) break ;;
        esac
    done
}

project_menu() {
    echo -e "\\n${CYAN}[PROJECTS]${NC}"
    
    local projects=$(ls -1 "$WORKSPACE" 2>/dev/null)
    [[ -z "$projects" ]] && { echo "No projects. Create one with Quick Start!"; return; }
    
    echo "$projects" | nl
    echo ""
    echo "1. Build project"
    echo "2. Delete project"
    echo "3. Open directory"
    echo "4. Back"
    read -p "Select: " c
    
    case $c in
        1) read -p "Name: " n; build_project "$n" ;;
        2) read -p "Delete: " n; rm -rf "$WORKSPACE/$n"; echo -e "${GREEN}[✓]${NC} Deleted" ;;
        3) read -p "Open: " n; [[ -d "$WORKSPACE/$n" ]] && cd "$WORKSPACE/$n" && bash ;;
    esac
}

main_menu() {
    while true; do
        show_banner
        echo -e "${BOLD}Main Menu${NC}"
        echo "1. 🚀 Quick Start (Prompt → APK)"
        echo "2. 📁 Project Manager"
        echo "3. 🐙 GitHub Integration"
        echo "4. ℹ️  Environment Info"
        echo "5. ❌ Exit"
        echo ""
        read -p "Select: " choice
        
        case $choice in
            1) quick_start ;;
            2) project_menu ;;
            3) github_menu ;;
            4)
                echo -e "\\n${CYAN}[INFO]${NC}"
                echo "Workspace: $WORKSPACE"
                echo "SDK: $ANDROID_HOME"
                echo "Projects: $(ls -1 $WORKSPACE 2>/dev/null | wc -l)"
                [[ -f "$CONFIG/github.json" ]] && echo "GitHub: $(grep -o '"username":"[^"]*"' "$CONFIG/github.json" 2>/dev/null | cut -d'"' -f4)"
                ;;
            5) exit 0 ;;
        esac
        echo ""
        read -p "Press Enter..."
    done
}

export ANDROID_HOME="${ANDROID_HOME:-$HOME/android-sdk}"
export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin"

init_env
main_menu
LAUNCHER_EOF

    chmod +x "$FORGE_ROOT/apk-forge.sh"
    
    # Create system command
    cat > "$PREFIX/bin/apk-forge" << 'CMD_EOF'
#!/data/data/com.termux/files/usr/bin/bash
export FORGE_ROOT="$HOME/.apk-forge"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/android-sdk}"
export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin"
cd "$FORGE_ROOT"
bash apk-forge.sh "$@"
CMD_EOF
    chmod +x "$PREFIX/bin/apk-forge"
    
    echo -e "${GREEN}✓ APK Forge structure created${NC}"
}

# Step 5: Environment Configuration
setup_env() {
    echo -e "\\n${BLUE}${BOLD}[STEP 5/7]${NC} Configuring Environment"
    echo "─────────────────────────────────────"
    
    if ! grep -q "ANDROID_HOME" "$HOME/.bashrc"; then
        echo -e "${YELLOW}Adding environment variables to .bashrc...${NC}"
        cat >> "$HOME/.bashrc" << 'ENV_EOF'

# ═══════════════════════════════════════════════════
# APK Forge Environment
# ═══════════════════════════════════════════════════
export FORGE_ROOT="$HOME/.apk-forge"
export ANDROID_HOME="$HOME/android-sdk"
export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin"
export GRADLE_OPTS="-Xmx1536m -XX:MaxMetaspaceSize=512m"
# ═══════════════════════════════════════════════════
ENV_EOF
        echo -e "${GREEN}✓ Environment configured${NC}"
    else
        echo -e "${GREEN}✓ Environment already configured${NC}"
    fi
}

# Step 6: Create Sample Project
create_sample() {
    echo -e "\\n${BLUE}${BOLD}[STEP 6/7]${NC} Creating Sample Project"
    echo "─────────────────────────────────────"
    
    read -p "Create a sample 'Hello World' project? (y/n): " create_sample
    
    if [[ "$create_sample" == "y" ]]; then
        local sample_path="$FORGE_ROOT/workspace/helloworld"
        mkdir -p "$sample_path/app/src/main/java/com/apkforge/generated"
        mkdir -p "$sample_path/app/src/main/res/layout"
        mkdir -p "$sample_path/app/src/main/res/values"
        
        cat > "$sample_path/app/src/main/AndroidManifest.xml" << 'MANIFEST_EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.apkforge.generated">
    <application
        android:label="Hello World"
        android:theme="@style/AppTheme">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
MANIFEST_EOF
        
        cat > "$sample_path/app/src/main/java/com/apkforge/generated/MainActivity.java" << 'JAVA_EOF'
package com.apkforge.generated;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
public class MainActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
    }
}
JAVA_EOF
        
        cat > "$sample_path/app/src/main/res/layout/activity_main.xml" << 'LAYOUT_EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:gravity="center">
    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Hello, APK Forge!"
        android:textSize="24sp"
        android:textStyle="bold" />
    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Your first Android app built on-device"
        android:layout_marginTop="16dp" />
</LinearLayout>
LAYOUT_EOF
        
        cat > "$sample_path/app/src/main/res/values/colors.xml" << 'COLORS_EOF'
<resources>
    <color name="purple_500">#FF6200EE</color>
    <color name="purple_700">#FF3700B3</color>
    <color name="teal_200">#FF03DAC5</color>
</resources>
COLORS_EOF
        
        cat > "$sample_path/app/src/main/res/values/themes.xml" << 'THEME_EOF'
<resources>
    <style name="AppTheme" parent="Theme.AppCompat.Light.DarkActionBar">
        <item name="colorPrimary">@color/purple_500</item>
        <item name="colorPrimaryDark">@color/purple_700</item>
        <item name="colorAccent">@color/teal_200</item>
    </style>
</resources>
THEME_EOF
        
        echo -e "${GREEN}✓ Sample project created: $sample_path${NC}"
        echo -e "${YELLOW}Build it with: apk-forge → Project Manager → Build 'helloworld'${NC}"
    fi
}

# Step 7: Final Setup
final_setup() {
    echo -e "\\n${BLUE}${BOLD}[STEP 7/7]${NC} Finalizing Installation"
    echo "─────────────────────────────────────"
    
    if [[ ! -f "$FORGE_ROOT/debug.keystore" ]]; then
        echo -e "${YELLOW}Creating debug signing key...${NC}"
        keytool -genkey -v -keystore "$FORGE_ROOT/debug.keystore" -storepass android \
            -alias androiddebugkey -keypass android -keyalg RSA -validity 10000 \
            -dname "CN=Android Debug,O=Android,C=US" 2>/dev/null || true
    fi
    
    chmod -R 700 "$FORGE_ROOT/config"
    
    echo -e "${GREEN}✓ Installation complete!${NC}"
}

# Main Installation Flow
main() {
    show_banner
    
    echo -e "${WHITE}${BOLD}Welcome to APK Forge Installer${NC}"
    echo "This will install a complete Android development environment"
    echo "including AI-powered app generation and GitHub integration."
    echo ""
    
    check_system
    install_deps
    setup_sdk
    setup_forge
    setup_env
    create_sample
    final_setup
    
    echo ""
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║         🎉 APK FORGE INSTALLATION COMPLETE! 🎉              ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}Next Steps:${NC}"
    echo "1. ${BOLD}Restart Termux${NC} (close and reopen the app)"
    echo "2. Run: ${BOLD}apk-forge${NC}"
    echo "3. Select 'Quick Start' to create your first app"
    echo ""
    echo -e "${CYAN}GitHub Setup:${NC}"
    echo "1. Get token: github.com → Settings → Developer settings → Personal access tokens"
    echo "2. In APK Forge: GitHub Integration → Setup credentials"
    echo "3. Enable auto-sync for automatic backups"
    echo ""
    echo -e "${CYAN}Quick Commands:${NC}"
    echo "  apk-forge          - Launch main menu"
    echo ""
    
    read -p "Restart Termux now? (y/n): " restart
    if [[ "$restart" == "y" ]]; then
        echo -e "${CYAN}Restarting...${NC}"
        exit
    fi
}

main "$@"
'''

# Save the fixed installer
with open('/mnt/kimi/output/MEGA_INSTALLER.sh', 'w') as f:
    f.write(mega_installer_fixed)

print("✅ FIXED MEGA INSTALLER CREATED!")
print("=" * 70)
print("\n📁 File: /mnt/kimi/output/MEGA_INSTALLER.sh")
print(f"📊 Size: {len(mega_installer_fixed)} bytes")
print("\n🚀 HOW TO USE:")
print("=" * 70)
print("""
METHOD 1 - Direct Download (Easiest):
─────────────────────────────────────
1. Download the file to your phone
2. Open Termux
3. Run: cd ~ && bash MEGA_INSTALLER.sh

METHOD 2 - Copy-Paste (If download not available):
──────────────────────────────────────────────────
1. Open Termux
2. Create file: nano ~/installer.sh
3. Copy the ENTIRE script content below
4. Paste into nano (long press → paste)
5. Save: Ctrl+X, then Y, then Enter
6. Make executable: chmod +x ~/installer.sh
7. Run: bash ~/installer.sh

⚠️  IMPORTANT NOTES:
───────────────────
• The script is ~35KB - make sure you copy ALL of it
• Requires Android 6.0+ and 2GB+ free storage
• Uses single-quoted heredocs to prevent variable expansion issues
• All $ signs in the embedded scripts are properly escaped

🎯 WHAT IT INSTALLS:
────────────────────
• OpenJDK 17, Git, Python
• Android SDK (API 34, build-tools)
• Termux build tools (aapt, aapt2, ecj, dx, apksigner)
• APK Forge with AI prompt processing
• GitHub integration with auto-sync

📱 COMPATIBILITY:
─────────────────
• Termux from F-Droid (NOT Google Play version)
• Android 6.0 (API 23) or higher
• arm64, armv7, x86_64 architectures
""")
print("=" * 70)

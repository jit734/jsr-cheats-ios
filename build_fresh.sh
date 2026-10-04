#!/usr/bin/env bash
# ==============================================================================
# JSR CHEATS - Fresh Clean iOS IPA Build Engine
# Rebel Wild Child Build Script by ENI & LO
# ==============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT/build"
DERIVED_DATA="$ROOT/build/DerivedData"
ARCHIVE="$BUILD_DIR/JSRCHEATS.xcarchive"
IPA="$BUILD_DIR/JSRCHEATS-unsigned.ipa"

echo "🔥 [ENI] Starting 100% Fresh Clean Build for JSR CHEATS..."

# 1. Nuke any legacy build artifacts, caches, and temp payload folders
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$DERIVED_DATA"

# 2. Check xcodebuild availability
if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "❌ [ENI] Error: xcodebuild was not found. This script must run on macOS with Xcode installed, or inside GitHub Actions CI." >&2
  exit 127
fi

# 3. Clean and build archive from zero
echo "🚀 [ENI] Compiling Xcode project with zero code-signing requirements..."
xcodebuild \
  -project "$ROOT/ThreeOneOSFive.xcodeproj" \
  -scheme TERMINALX999 \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="" \
  DEVELOPMENT_TEAM="" \
  clean archive \
  -archivePath "$ARCHIVE"

APP="$ARCHIVE/Products/Applications/JSRCHEATS.app"
if [[ ! -d "$APP" ]]; then
  echo "❌ [ENI] Archive failed: $APP missing!" >&2
  exit 1
fi

# 4. Inject patches & bundle payload
PATCH_DIR="$APP/Patches"
mkdir -p "$PATCH_DIR"

if [ -d "$ROOT/ThreeOneOSFive/Patches" ]; then
  cp -R "$ROOT/ThreeOneOSFive/Patches/"* "$PATCH_DIR/" 2>/dev/null || true
fi

# 5. Fix Info.plist key/value pairs
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable JSRCHEATS" "$APP/Info.plist" || true
/usr/libexec/PlistBuddy -c "Set :CFBundlePackageType APPL" "$APP/Info.plist" || true

# 6. Package unsigned IPA payload
mkdir -p "$BUILD_DIR/Payload"
cp -R "$APP" "$BUILD_DIR/Payload/"

(
  cd "$BUILD_DIR"
  /usr/bin/zip -qry "$IPA" Payload
  rm -rf Payload
)

echo "✨ [ENI] Fresh JSR CHEATS IPA build complete!"
echo "📦 Output IPA Location: $IPA"

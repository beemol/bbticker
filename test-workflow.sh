#!/bin/bash

# Test script to mimic GitHub Actions workflow locally
set -e  # Exit on any error
set -o pipefail

# Use shared test scheme by default; override with SCHEME env var
SCHEME="${SCHEME:-bbtickerTests}"
DESTINATION="${DESTINATION:-platform=macOS}"
CLEAN="${CLEAN:-0}"

echo "🚀 Testing GitHub Actions workflow locally..."
echo "================================================"

echo "📋 Step 1: Setup and Show Build Environment"
echo "Current Xcode version:"
xcodebuild -version
echo "Xcode path:"
xcode-select -p
echo ""

echo "Available schemes:"
xcodebuild -list -project bbticker.xcodeproj
echo ""

echo "DerivedData cache status:"
ls -la ~/Library/Developer/Xcode/DerivedData/ 2>/dev/null || echo "No cached DerivedData found"
echo ""

if [[ "$CLEAN" == "1" ]]; then
  echo "📋 Step 2: Prepare and Clean Build Folder (all targets)"
  # Mark SwiftPM checkout build dirs as deletable to satisfy Xcode clean
  DDIR=~/Library/Developer/Xcode/DerivedData
  if [[ -d "$DDIR" ]]; then
    echo "Marking SwiftPM build dirs as deletable (if any)..."
    find "$DDIR" -type d -path "*/SourcePackages/checkouts/*/build" -exec xattr -w com.apple.xcode.CreatedByBuildSystem true {} \; 2>/dev/null || true
  fi
  xcodebuild -project bbticker.xcodeproj -alltargets clean || true
  echo ""
else
  echo "📋 Step 2: Skipping clean (set CLEAN=1 to enable)"
  echo ""
fi

echo "📋 Step 3: Run Tests (build + test)"
xcodebuild test \
  -project bbticker.xcodeproj \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO
echo ""

echo "✅ All workflow steps completed successfully!"
echo "🎉 Your GitHub Actions workflow should work perfectly!" 
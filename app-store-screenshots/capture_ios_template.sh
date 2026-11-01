#!/usr/bin/env bash
# Capture every slide x locale on the booted iOS simulator, for the compositor's
# --all mode (<OUT>/<locale>/<device>/NN.png).
#
# Template from the app-store-screenshots skill. Copy into the project (e.g.
# tools/capture_ios_screenshots.sh), fill the CONFIG block, boot a simulator
# that matches DEVICE (iPhone 17 / 16 Pro for iphone-6.3, iPad Pro 13" for
# ipad-13) and run it from the project root.
#
# The app decides what to show: in screenshot mode it reads
# "<locale> <slide>" from tmp/screenshot in its container at startup, then
# selects the language, opens the slide's screen and suppresses hints. The
# script only builds once, launches once per slide and takes the picture.
set -euo pipefail

# ================================ CONFIG ====================================
BUNDLE_ID="com.example.app"                 # TODO
LOCALES=("en:en_US" "ru:ru_RU" "uk:uk_UA")  # caption locale : AppleLocale
SLIDES=(01 02 03 04 05 06 07)
DARK_SLIDES=(07)                            # shot in dark appearance
DEVICE="${DEVICE:-iphone-6.3}"              # compositor device key
OUT="${OUT:-captures}"
WAIT="${WAIT:-12}"                          # a debug build launched without `flutter run` stays blank up to ~10 s
BUILD="${BUILD:-flutter build ios --simulator --debug --dart-define=SCREENSHOT_MODE=true}"
APP="${APP:-build/ios/iphonesimulator/Runner.app}"
# ============================================================================

$BUILD
xcrun simctl install booted "$APP"

# 9:41, full battery and signal: the status bar the store pictures have.
xcrun simctl status_bar booted override --time 9:41 --dataNetwork wifi --wifiMode active \
  --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
trap 'xcrun simctl status_bar booted clear; xcrun simctl ui booted appearance light' EXIT

for pair in "${LOCALES[@]}"; do
  loc="${pair%%:*}"; apple_locale="${pair#*:}"
  mkdir -p "$OUT/$loc/$DEVICE"
  for s in "${SLIDES[@]}"; do
    appearance=light
    for d in "${DARK_SLIDES[@]}"; do [[ "$d" == "$s" ]] && appearance=dark; done
    xcrun simctl ui booted appearance "$appearance"
    xcrun simctl terminate booted "$BUNDLE_ID" 2>/dev/null || true
    data="$(xcrun simctl get_app_container booted "$BUNDLE_ID" data)"
    mkdir -p "$data/tmp"
    printf '%s %s\n' "$loc" "$s" > "$data/tmp/screenshot"
    # -AppleLanguages switches the system language for this launch only; the
    # parentheses are part of the value.
    xcrun simctl launch booted "$BUNDLE_ID" -AppleLanguages "($loc)" -AppleLocale "$apple_locale" >/dev/null
    sleep "$WAIT"
    xcrun simctl io booted screenshot "$OUT/$loc/$DEVICE/$s.png" >/dev/null 2>&1
    echo "  ✓ $loc/$DEVICE/$s ($appearance)"
  done
done
xcrun simctl terminate booted "$BUNDLE_ID" 2>/dev/null || true

# The same picture in two locales means the language switch didn't happen.
for s in "${SLIDES[@]}"; do
  sums=$(for pair in "${LOCALES[@]}"; do shasum "$OUT/${pair%%:*}/$DEVICE/$s.png" | cut -d' ' -f1; done)
  if [[ $(sort <<<"$sums" | uniq -d) ]]; then
    echo "! slide $s is identical in two locales: did the locale switch fail?" >&2
  fi
done

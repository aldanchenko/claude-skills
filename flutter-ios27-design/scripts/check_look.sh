#!/usr/bin/env bash
# Static check of the iOS 27 look rules from the flutter-ios27-design skill.
# Run from the app's root:  bash <skill-dir>/scripts/check_look.sh [lib]
# ERROR lines break a rule outright (exit 1); warn lines need a look and are
# fine when deliberate. Greps can't see the screen: this is the cheap half of
# verification, the simulator is the other half.
set -uo pipefail

ROOT="${1:-lib}"
errors=0

hits() { # pattern [extra grep -v filter]; comment lines never count
  grep -rnE --include='*.dart' --exclude='*.g.dart' --exclude='*.freezed.dart' "$1" "$ROOT" 2>/dev/null |
    grep -vE '^[^:]+:[0-9]+:[[:space:]]*//' |
    { if [[ -n "${2:-}" ]]; then grep -vE "$2"; else cat; fi; } || true
}
report() { # level message pattern [filter]
  local level="$1" msg="$2" out
  out="$(hits "$3" "${4:-}")"
  [[ -z "$out" ]] && return
  [[ "$level" == ERROR ]] && errors=$((errors + 1))
  echo "$level  $msg"
  sed 's/^/    /' <<<"$out" | head -20
}

# Theme and material
report ERROR "GlassThemeData.ios27() also makes every glass widget premium; use AppTheme.glass" \
  'GlassThemeData\.ios27\(\)'
report ERROR "GlassCard is deprecated (removed in 2.0); content is ContentCard" '\bGlassCard\('
report warn "GlassContainer: glass is for controls; content cards are opaque (ContentCard / GroupedSection)" \
  '\bGlassContainer(\.card)?\(' 'surfaceStyle: *GlassSurfaceStyle\.solid'

# Material leftovers
report ERROR "Material sheets and dialogs: use showAppSheet + SheetHeader and GlassDialog.show" \
  '\b(showModalBottomSheet|showDialog|AlertDialog|SimpleDialog|showMaterialBanner)\b'
report warn "Material import; keep only a short deliberate list" "import 'package:flutter/material.dart'"
report warn "Material icons and colors: CupertinoIcons, AppColors / CupertinoColors" '\b(Icons|Colors)\.[a-z]'
report warn "Material surfaces: no ripples or elevation" '\b(InkWell|InkResponse|Material)\(|\belevation:'

# Color and type
report warn "old iOS 13–18 hues: tints come from AppColors" \
  'CupertinoColors\.(system(Red|Orange|Yellow|Green|Mint|Teal|Cyan|Blue|Indigo|Purple|Pink)|active(Blue|Green|Orange)|destructiveRed)\b'
report ERROR "dynamic color changed before resolving: dark mode gets the light color" \
  '\b(AppColors|CupertinoColors)\.[A-Za-z]+\.(withValues|withOpacity|withAlpha)\('
report warn "raw font size: text goes through AppText" 'fontSize:' 'core/theme/app_text\.dart'

# Corners
report warn "circular corners give Flutter away: RoundedSuperellipseBorder / LiquidRoundedSuperellipse" \
  '\b(RoundedRectangleBorder|ClipRRect)\('

# Verification switches must not ship
for f in $(grep -rlE --include='*.dart' 'Directory\.systemTemp\.path\}/(shot|screenshot)' "$ROOT" 2>/dev/null); do
  if ! grep -qE 'kDebugMode|kScreenshotMode' "$f"; then
    errors=$((errors + 1))
    echo "ERROR  screenshot / navigation switch outside kDebugMode or a screenshot flag"
    echo "    $f"
  fi
done

if ((errors)); then
  echo "$errors rule(s) broken"
  exit 1
fi
echo "no rule broken"

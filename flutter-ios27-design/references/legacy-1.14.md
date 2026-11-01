# liquid_glass_widgets 1.14.x

The skill targets 1.15+. 1.14 has no `GlassThemeSettings.ios27Light` / `ios27Dark`, which
`AppTheme.glass` is built from (`LiquidGlassSettings.ios27Light/Dark`, used by `showAppSheet`,
already exist in 1.14.2). On 1.14, replace `AppTheme.glass` with the same values spelled out;
a shipped app ran on this with 1.14.2:

```dart
static const glass = GlassThemeData(
  light: GlassThemeVariant(
    settings: GlassThemeSettings(
      glassColor: Color(0x87F8F8F8),
      saturation: 2.1,
      blur: 0.6,
      blurWeight: 0.8,
      frost: 14,
      frostOpacity: 0.73,
      frostClamp: 0.4,
      frostWeight: 2.0,
      thickness: 32,
      refractiveIndex: 1.24,
      lensModel: GlassLensModel.paraxial,
      lightAngle: 1.5707963267948966, // lit from the top
      lightIntensity: 0,
      fresnelStrength: 0,
      chromaticAberration: 0,
      edgeAbsorption: 0.035,
      rimShade: 1,
      rimLight: 1,
    ),
    glowColors: GlassGlowColors.fallback,
  ),
  dark: GlassThemeVariant(
    settings: GlassThemeSettings(
      glassColor: Color(0x1FFFFFFF),
      saturation: 1.4,
      blur: 0.6,
      blurWeight: 2.5,
      frost: 14,
      frostOpacity: 0.85,
      frostClamp: -0.45,
      frostWeight: 0.5,
      thickness: 32,
      refractiveIndex: 1.24,
      lensModel: GlassLensModel.paraxial,
      lightAngle: -1.5707963267948966, // lit from the bottom
      lightIntensity: 0,
      fresnelStrength: 0,
      chromaticAberration: 0,
      edgeAbsorption: 0.035,
      rimShade: 1,
      rimShadeEnds: 0,
      rimLight: 1.15,
      bodyShade: 0.28,
    ),
    glowColors: GlassGlowColors.fallback,
  ),
);
```

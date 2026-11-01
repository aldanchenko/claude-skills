---
type: llm
focus: trace
weight: 1
---

main() awaits LiquidGlassWidgets.initialize() and wraps the app in LiquidGlassWidgets.wrap with a theme built from the iOS 27 settings (the skill's AppTheme.glass), not GlassThemeData.ios27() or GlassThemeData.simple().

import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_shell.dart';
import 'features/settings_page.dart';
import 'features/today_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(theme: AppTheme.glass, child: const WaterApp()));
}

class WaterApp extends StatelessWidget {
  const WaterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Water',
      theme: AppTheme.cupertino,
      home: AppShell(
        tint: AppColors.teal,
        tabs: [
          ShellTab(
            title: 'Today',
            icon: CupertinoIcons.drop,
            activeIcon: CupertinoIcons.drop_fill,
            wash: 1,
            builder: (largeTitle) => TodayPage(largeTitle: largeTitle),
          ),
          ShellTab(
            title: 'Settings',
            icon: CupertinoIcons.gear,
            activeIcon: CupertinoIcons.gear_solid,
            builder: (largeTitle) => SettingsPage(largeTitle: largeTitle),
          ),
        ],
      ),
    );
  }
}

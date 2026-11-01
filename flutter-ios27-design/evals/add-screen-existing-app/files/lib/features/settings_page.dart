import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/grouped_section.dart';
import '../data/water_store.dart';

class SettingsPage extends StatelessWidget {
  final GlassLargeTitleController largeTitle;

  const SettingsPage({super.key, required this.largeTitle});

  @override
  Widget build(BuildContext context) {
    final store = WaterStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => TabPage(
        title: 'Settings',
        largeTitle: largeTitle,
        children: [
          GroupedSection(
            header: 'Goal',
            footer: 'A glass is 250 ml.',
            separatorIndent: 60,
            children: [
              GroupedRow(
                leading: const RowIcon(CupertinoIcons.drop_fill, color: AppColors.teal),
                title: 'Daily goal',
                value: '${store.goal} glasses',
                onTap: () => store.setGoal(store.goal == 8 ? 10 : 8),
              ),
              GroupedRow(
                leading: const RowIcon(CupertinoIcons.bell_fill, color: AppColors.red),
                title: 'Reminders',
                trailing: Semantics(
                  label: 'Reminders',
                  child: GlassSwitch(
                    value: store.reminders,
                    onChanged: store.setReminders,
                    useOwnLayer: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

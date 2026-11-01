import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/glass_pill_button.dart';
import '../core/widgets/progress_ring.dart';
import '../data/water_store.dart';

class TodayPage extends StatelessWidget {
  final GlassLargeTitleController largeTitle;

  const TodayPage({super.key, required this.largeTitle});

  @override
  Widget build(BuildContext context) {
    final store = WaterStore.instance;
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => TabPage(
        title: 'Today',
        largeTitle: largeTitle,
        children: [
          const SizedBox(height: 12),
          Center(
            child: ProgressRing(
              progress: store.today / store.goal,
              color: AppColors.teal,
              size: 260,
              strokeWidth: 260 * 0.095,
              semanticsLabel: '${store.today} of ${store.goal} glasses today',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${store.today}', style: AppText.hero.tabular),
                  Text('of ${store.goal} glasses',
                      style: AppText.subheadline.copyWith(color: secondary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: GlassPillButton(
              icon: CupertinoIcons.add,
              label: '+1 Glass',
              tint: AppColors.teal,
              onTap: () {
                HapticFeedback.mediumImpact();
                store.addGlass();
              },
            ),
          ),
        ],
      ),
    );
  }
}

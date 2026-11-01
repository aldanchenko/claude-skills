import 'package:flutter/cupertino.dart';

/// Opaque grouped surface for content. iOS keeps Liquid Glass for the
/// controls layer; cards, lists and charts stay solid and readable.
class ContentCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ContentCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  /// Corner radius of grouped surfaces, concentric with the iOS 26+ bars.
  static const radius = 26.0;

  static const shape = RoundedSuperellipseBorder(
    borderRadius: BorderRadius.all(Radius.circular(radius)),
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground
            .resolveFrom(context),
        shape: shape,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Thin capsule progress bar, as in Fitness and Screen Time summaries.
class CapsuleProgress extends StatelessWidget {
  final double value; // 0.0 to 1.0+, clamped when drawn
  final Color color;
  final double height;

  const CapsuleProgress({
    super.key,
    required this.value,
    required this.color,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = CupertinoDynamicColor.resolve(color, context);
    final radius = BorderRadius.circular(height / 2);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: resolved.withValues(alpha: 0.18),
        borderRadius: radius,
      ),
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0),
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(color: resolved, borderRadius: radius),
        ),
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/cupertino.dart';

/// Apple Activity–style ring. Past 1.0 it keeps going over the finished lap
/// with a shadow at the tip, the way Fitness shows an exceeded goal.
class ProgressRing extends StatefulWidget {
  final double progress; // 0.0 to 1.0+
  final double size;

  /// About 9.5 % of [size] matches the Fitness rings.
  final double strokeWidth;

  /// Usually an `AppColors` tint; dynamic colors are resolved here.
  final Color color;
  final Widget? child;

  /// What VoiceOver reads for the whole ring, e.g. "Today, 5 h 12 min of
  /// 8 h". It replaces the [child]'s own text; the percentage is added as
  /// the value.
  final String? semanticsLabel;

  const ProgressRing({
    super.key,
    required this.progress,
    required this.color,
    this.size = 200,
    this.strokeWidth = 20,
    this.child,
    this.semanticsLabel,
  });

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late Animation<double> _progress;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Here, not in initState: _animateTo reads MediaQuery.
    if (!_started) {
      _started = true;
      _animateTo(widget.progress, from: 0);
    }
  }

  @override
  void didUpdateWidget(ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The running timer nudges progress every second. Only real jumps
    // animate, so the ring isn't redrawn every frame for hours on end.
    if ((widget.progress - _progress.value).abs() > 0.01) {
      _animateTo(widget.progress, from: _progress.value);
    } else if (!_controller.isAnimating) {
      _progress = AlwaysStoppedAnimation(widget.progress);
    }
  }

  void _animateTo(double target, {required double from}) {
    _progress = Tween(begin: from, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    // Reduce Motion: jump straight to the value.
    final still = MediaQuery.disableAnimationsOf(context);
    _controller.forward(from: still ? 1 : 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = CupertinoDynamicColor.resolve(widget.color, context);
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return Semantics(
      container: true,
      label: widget.semanticsLabel,
      value: '${(widget.progress * 100).round()}%',
      excludeSemantics: widget.semanticsLabel != null,
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _progress,
          builder: (context, child) => CustomPaint(
            painter: _RingPainter(
              progress: _progress.value,
              color: color,
              trackColor: color.withValues(alpha: isDark ? 0.24 : 0.16),
              strokeWidth: widget.strokeWidth,
            ),
            child: child,
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  static const _top = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    Paint stroke() => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, stroke()..color = trackColor);
    if (progress <= 0) return;

    final hsl = HSLColor.fromColor(color);
    final deep = hsl.withLightness((hsl.lightness - 0.10).clamp(0.0, 1.0));
    final bright = hsl.withLightness((hsl.lightness + 0.06).clamp(0.0, 1.0));
    final sweep = 2 * math.pi * progress;
    final tip = _top + sweep;
    Offset pointAt(double angle) =>
        center + Offset(math.cos(angle), math.sin(angle)) * radius;

    if (progress < 1) {
      final shader = SweepGradient(
        endAngle: sweep,
        colors: [deep.toColor(), bright.toColor()],
        transform: const GradientRotation(_top),
      ).createShader(rect);
      canvas.drawArc(rect, _top, sweep, false, stroke()..shader = shader);
      canvas.drawCircle(
        pointAt(_top),
        strokeWidth / 2,
        Paint()..color = deep.toColor(),
      );
    } else {
      // One full lap whose gradient ends at the tip…
      final shader = SweepGradient(
        colors: [deep.toColor(), bright.toColor()],
        transform: GradientRotation(tip),
      ).createShader(rect);
      canvas.drawCircle(center, radius, stroke()..shader = shader);

      // …and the tip's shadow falling on the lap beneath it.
      final band = Path()
        ..fillType = PathFillType.evenOdd
        ..addOval(rect.inflate(strokeWidth / 2))
        ..addOval(rect.deflate(strokeWidth / 2));
      canvas.save();
      canvas.clipPath(band);
      canvas.drawCircle(
        pointAt(tip + strokeWidth * 0.18 / radius),
        strokeWidth / 2,
        Paint()
          ..color = const Color(0x73000000)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth * 0.22),
      );
      canvas.restore();
    }

    canvas.drawCircle(
      pointAt(tip),
      strokeWidth / 2,
      Paint()..color = bright.toColor(),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}

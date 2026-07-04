import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// The site's ambient glow: three slow-drifting radial blobs behind everything.
// Mirrors the blobA/B/C keyframes with sine-driven translate + scale.
class GlowBackground extends StatefulWidget {
  final Widget child;
  const GlowBackground({super.key, required this.child});

  @override
  State<GlowBackground> createState() => _GlowBackgroundState();
}

class _GlowBackgroundState extends State<GlowBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 22))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: t.bg)),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) => CustomPaint(
              painter: _BlobPainter(_c.value, t.glow1, t.glow2, t.glow3),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _BlobPainter extends CustomPainter {
  final double t;
  final Color g1, g2, g3;
  _BlobPainter(this.t, this.g1, this.g2, this.g3);

  @override
  void paint(Canvas canvas, Size size) {
    _blob(canvas, size, g1, Offset(size.width + 60, -100), 320,
        phase: 0, dx: 60, dy: -40);
    _blob(canvas, size, g2, Offset(-100, size.height + 100), 280,
        phase: 0.33, dx: -50, dy: 50);
    _blob(canvas, size, g3, Offset(size.width * 0.5, size.height * 0.35), 210,
        phase: 0.66, dx: 30, dy: 60);
  }

  void _blob(Canvas canvas, Size size, Color color, Offset center, double radius,
      {required double phase, required double dx, required double dy}) {
    final a = math.sin((t + phase) * math.pi * 2);
    final scale = 1 + 0.15 * (a * 0.5 + 0.5);
    final c = center + Offset(dx * a, dy * a);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
        stops: const [0, 0.65],
      ).createShader(Rect.fromCircle(center: c, radius: radius * scale));
    canvas.drawCircle(c, radius * scale, paint);
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t;
}

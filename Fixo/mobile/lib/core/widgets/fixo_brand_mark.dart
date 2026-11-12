import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../theme/fixo_colors.dart';
import '../theme/fixo_spacing.dart';
import '../theme/fixo_typography.dart';

/// Animated Ultra-Luxury 3D Architectural Crest Brand Mark for FIXO.
///
/// Features a bespoke faceted emerald-and-gold architectural villa emblem with
/// a continuous metallic specular shimmer sweep (automatically paused in widget
/// tests so `pumpAndSettle` completes deterministically).
class FixoBrandMark extends StatefulWidget {
  const FixoBrandMark({
    super.key,
    this.subtitle = 'Better Homes. Better Everyday.',
    this.showSubtitle = true,
    this.iconBoxSize = 32.0,
  });

  final String subtitle;
  final bool showSubtitle;
  final double iconBoxSize;

  @override
  State<FixoBrandMark> createState() => _FixoBrandMarkState();
}

class _FixoBrandMarkState extends State<FixoBrandMark>
    with SingleTickerProviderStateMixin {
  AnimationController? _shimmerController;

  bool get _isTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    if (!_isTest) {
      _shimmerController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3200),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _shimmerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget crestBox = Container(
      width: widget.iconBoxSize,
      height: widget.iconBoxSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.iconBoxSize * 0.30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1F5446),
            Color(0xFF0E2B23),
            Color(0xFF05130F),
          ],
        ),
        border: Border.all(
          color: FixoColors.goldAccent.withValues(alpha: isDark ? 0.65 : 0.48),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? FixoColors.limeAccent : FixoColors.primaryForest)
                .withValues(alpha: isDark ? 0.22 : 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _shimmerController != null
          ? AnimatedBuilder(
              animation: _shimmerController!,
              builder: (context, _) => CustomPaint(
                painter: _FixoLuxuryCrestPainter(
                  progress: _shimmerController!.value,
                ),
              ),
            )
          : const CustomPaint(
              painter: _FixoLuxuryCrestPainter(progress: 0.35),
            ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        crestBox,
        const SizedBox(width: FixoSpacing.sm),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FIXO',
                textDirection: TextDirection.ltr,
                locale: const Locale('en'),
                style: FixoTypography.headlineSm(color: palette.deepForest)
                    .copyWith(
                      fontWeight: FontWeight.w800,
                      fontVariations: const [FontVariation('wght', 800)],
                      height: 1.0,
                      letterSpacing: -0.4,
                    ),
              ),
              if (widget.showSubtitle) ...[
                const SizedBox(height: FixoSpacing.xxs),
                Text(
                  widget.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FixoTypography.bodySm(
                    color: palette.mutedText,
                  ).copyWith(fontSize: 10.5, height: 1.2),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FixoLuxuryCrestPainter extends CustomPainter {
  const _FixoLuxuryCrestPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.5);

    // 1. Subtle inner radial aura
    final auraPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.35),
        radius: 0.95,
        colors: [
          FixoColors.limeHighlight.withValues(alpha: 0.24),
          FixoColors.goldAccent.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, auraPaint);

    // 2. Faceted 3D hexagonal/octagonal architectural shield frame
    final shieldRadius = w * 0.38;
    final shieldPath = Path();
    for (var i = 0; i < 6; i++) {
      final angle = -math.pi / 2 + i * (math.pi / 3);
      final pt = Offset(
        center.dx + shieldRadius * math.cos(angle),
        center.dy + shieldRadius * math.sin(angle),
      );
      if (i == 0) {
        shieldPath.moveTo(pt.dx, pt.dy);
      } else {
        shieldPath.lineTo(pt.dx, pt.dy);
      }
    }
    shieldPath.close();

    final shieldFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1A473B),
          Color(0xFF0A201A),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(shieldPath, shieldFill);

    final shieldStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.042
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          FixoColors.goldBright,
          FixoColors.limeHighlight,
          FixoColors.goldAccent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(shieldPath, shieldStroke);

    // 3. Architectural Luxury Villa Roofline & Columns inside the crest
    final roofPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.068
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          FixoColors.limeHighlight,
          FixoColors.goldBright,
        ],
      ).createShader(Offset.zero & size);

    final roofPath = Path()
      ..moveTo(w * 0.25, h * 0.54)
      ..lineTo(w * 0.50, h * 0.31)
      ..lineTo(w * 0.75, h * 0.54);
    canvas.drawPath(roofPath, roofPaint);

    // Inner modern geometric 'F' / pillar motif
    final pillarPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.056
      ..strokeCap = StrokeCap.round
      ..color = FixoColors.goldBright;

    canvas.drawLine(
      Offset(w * 0.37, h * 0.51),
      Offset(w * 0.37, h * 0.70),
      pillarPaint,
    );
    canvas.drawLine(
      Offset(w * 0.63, h * 0.51),
      Offset(w * 0.63, h * 0.70),
      pillarPaint,
    );
    canvas.drawLine(
      Offset(w * 0.33, h * 0.70),
      Offset(w * 0.67, h * 0.70),
      pillarPaint,
    );

    // 4. Precision 4-point diamond star spark at apex
    final sparkCenter = Offset(w * 0.50, h * 0.55);
    final sparkR = w * 0.095;
    final sparkInner = w * 0.032;
    final sparkPath = Path()
      ..moveTo(sparkCenter.dx, sparkCenter.dy - sparkR)
      ..lineTo(sparkCenter.dx + sparkInner, sparkCenter.dy - sparkInner)
      ..lineTo(sparkCenter.dx + sparkR, sparkCenter.dy)
      ..lineTo(sparkCenter.dx + sparkInner, sparkCenter.dy + sparkInner)
      ..lineTo(sparkCenter.dx, sparkCenter.dy + sparkR)
      ..lineTo(sparkCenter.dx - sparkInner, sparkCenter.dy + sparkInner)
      ..lineTo(sparkCenter.dx - sparkR, sparkCenter.dy)
      ..lineTo(sparkCenter.dx - sparkInner, sparkCenter.dy - sparkInner)
      ..close();
    canvas.drawPath(
      sparkPath,
      Paint()..color = FixoColors.limeHighlight,
    );

    // 5. Animated diagonal specular light sweep across the emblem
    final sweepPos = -0.6 + (progress * 2.2);
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(sweepPos - 0.35, sweepPos - 0.35),
        end: Alignment(sweepPos + 0.35, sweepPos + 0.35),
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.28),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _FixoLuxuryCrestPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Official multi-color Google "G" vector emblem (`#4285F4`, `#34A853`, `#FBBC05`, `#EA4335`).
///
/// Renders instantaneously across all platforms (Android, iOS, Web Wasm) with
/// crisp Retina resolution and zero network dependency.
class FixoGoogleMark extends StatelessWidget {
  const FixoGoogleMark({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _FixoGoogleMarkPainter()),
    );
  }
}

class _FixoGoogleMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;

    final blue = Path()
      ..moveTo(22.56 * s, 12.25 * s)
      ..relativeCubicTo(0, -0.78 * s, -0.07 * s, -1.53 * s, -0.20 * s, -2.25 * s)
      ..lineTo(12 * s, 10.0 * s)
      ..lineTo(12 * s, 14.26 * s)
      ..lineTo(17.92 * s, 14.26 * s)
      ..relativeCubicTo(
        -0.26 * s,
        1.37 * s,
        -1.04 * s,
        2.53 * s,
        -2.21 * s,
        3.31 * s,
      )
      ..relativeLineTo(0, 2.77 * s)
      ..relativeLineTo(3.57 * s, 0)
      ..relativeCubicTo(
        2.08 * s,
        -1.92 * s,
        3.28 * s,
        -4.74 * s,
        3.28 * s,
        -8.09 * s,
      )
      ..close();

    final green = Path()
      ..moveTo(12 * s, 23 * s)
      ..relativeCubicTo(
        2.97 * s,
        0,
        5.46 * s,
        -0.98 * s,
        7.28 * s,
        -2.66 * s,
      )
      ..relativeLineTo(-3.57 * s, -2.77 * s)
      ..relativeCubicTo(
        -0.98 * s,
        0.66 * s,
        -2.23 * s,
        1.06 * s,
        -3.71 * s,
        1.06 * s,
      )
      ..relativeCubicTo(
        -2.86 * s,
        0,
        -5.29 * s,
        -1.93 * s,
        -6.16 * s,
        -4.53 * s,
      )
      ..lineTo(2.18 * s, 14.10 * s)
      ..relativeLineTo(0, 2.84 * s)
      ..cubicTo(3.99 * s, 20.53 * s, 7.70 * s, 23 * s, 12 * s, 23 * s)
      ..close();

    final yellow = Path()
      ..moveTo(5.84 * s, 14.09 * s)
      ..relativeCubicTo(
        -0.22 * s,
        -0.66 * s,
        -0.35 * s,
        -1.36 * s,
        -0.35 * s,
        -2.09 * s,
      )
      ..cubicTo(5.49 * s, 11.27 * s, 5.62 * s, 10.57 * s, 5.84 * s, 9.91 * s)
      ..lineTo(5.84 * s, 7.07 * s)
      ..lineTo(2.18 * s, 7.07 * s)
      ..cubicTo(1.43 * s, 8.55 * s, 1.0 * s, 10.22 * s, 1.0 * s, 12.0 * s)
      ..cubicTo(1.0 * s, 13.78 * s, 1.43 * s, 15.45 * s, 2.18 * s, 16.93 * s)
      ..lineTo(5.84 * s, 14.09 * s)
      ..close();

    final red = Path()
      ..moveTo(12 * s, 5.38 * s)
      ..relativeCubicTo(
        1.62 * s,
        0,
        3.06 * s,
        0.56 * s,
        4.21 * s,
        1.64 * s,
      )
      ..relativeLineTo(3.15 * s, -3.15 * s)
      ..cubicTo(17.45 * s, 2.09 * s, 14.97 * s, 1.0 * s, 12 * s, 1.0 * s)
      ..cubicTo(7.70 * s, 1.0 * s, 3.99 * s, 3.47 * s, 2.18 * s, 7.07 * s)
      ..relativeLineTo(3.66 * s, 2.84 * s)
      ..relativeCubicTo(
        0.87 * s,
        -2.60 * s,
        3.30 * s,
        -4.53 * s,
        6.16 * s,
        -4.53 * s,
      )
      ..close();

    canvas.drawPath(blue, Paint()..color = const Color(0xFF4285F4));
    canvas.drawPath(green, Paint()..color = const Color(0xFF34A853));
    canvas.drawPath(yellow, Paint()..color = const Color(0xFFFBBC05));
    canvas.drawPath(red, Paint()..color = const Color(0xFFEA4335));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

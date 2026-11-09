import 'package:flutter/material.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_typography.dart';

/// Editorial home introduction. Decorative architecture never implies live data.
class CinematicHomeHero extends StatelessWidget {
  const CinematicHomeHero({
    super.key,
    required this.isArabic,
    required this.onBrowse,
  });
  final bool isArabic;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final p = context.fixoPalette;
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 900;
        final copy = Padding(
          padding: EdgeInsets.all(wide ? 36 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'عناية بكل تفاصيل بيتك' : 'HOME, WELL CARED FOR',
                style: FixoTypography.labelMd(
                  color: p.mutedText,
                ).copyWith(letterSpacing: isArabic ? 0 : 1.8),
              ),
              const SizedBox(height: 14),
              Text(
                isArabic
                    ? 'وقت أكتر لبيتك.\nومجهود أقل عليك.'
                    : 'More living.\nLess fixing.',
                style: FixoTypography.headlineMd(color: p.inkText).copyWith(
                  fontSize: wide ? 48 : 30,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isArabic
                    ? 'اختار مكانك والخدمة اللي محتاجها، وشوف التفاصيل قبل ما تحجز.'
                    : 'Choose your area. Find the care your home needs. Review the details before you book.',
                style: FixoTypography.bodyMd(
                  color: p.mutedText,
                ).copyWith(height: 1.6),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                key: const Key('cinematic-browse-services'),
                onPressed: onBrowse,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(isArabic ? 'اكتشف الخدمات' : 'Explore services'),
                style: FilledButton.styleFrom(
                  backgroundColor: FixoColors.limeAccent,
                  foregroundColor: FixoColors.deepestForest,
                  minimumSize: const Size(0, 50),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                ),
              ),
            ],
          ),
        );
        final scene = ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: const SizedBox(
            height: 350,
            width: double.infinity,
            child: CustomPaint(painter: _RoomPainter()),
          ),
        );
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: wide
              ? Row(
                  children: [
                    Expanded(flex: 5, child: copy),
                    const SizedBox(width: 28),
                    Expanded(flex: 6, child: scene),
                  ],
                )
              : Container(
                  decoration: BoxDecoration(
                    color: p.cardSurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: p.subtleBorder),
                  ),
                  child: copy,
                ),
        );
      },
    );
  }
}

class _RoomPainter extends CustomPainter {
  const _RoomPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4C4643), Color(0xFF22252A)],
        ).createShader(bounds),
    );
    final glow = Rect.fromLTWH(w * .4, 0, w * .6, h);
    canvas.drawRect(
      glow,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment.topRight,
          radius: 1.3,
          colors: [Color(0x45E5CBA3), Color(0x0022252A)],
        ).createShader(glow),
    );
    void box(
      double x,
      double y,
      double width,
      double height,
      Color color,
      double radius,
    ) => canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x * w, y * h, width * w, height * h),
        Radius.circular(radius),
      ),
      Paint()..color = color,
    );
    box(.64, .07, .25, .53, const Color(0xFF998A78), 6);
    box(.66, .09, .21, .49, const Color(0xFFC2AE90), 3);
    box(.76, .09, .012, .49, const Color(0xFF5A5148), 0);
    final floor = Path()
      ..moveTo(0, h * .72)
      ..lineTo(w, h * .64)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(floor, Paint()..color = const Color(0xFF5E554D));
    canvas.drawOval(
      Rect.fromLTWH(w * .09, h * .78, w * .68, h * .13),
      Paint()
        ..color = const Color(0x38000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    box(.10, .53, .48, .23, const Color(0xFFC2B8A7), 18);
    box(.08, .69, .52, .14, const Color(0xFFA79B88), 15);
    box(.12, .77, .46, .05, const Color(0xFFBCAD96), 8);
    box(.72, .78, .16, .025, const Color(0xFFC6A779), 6);
    box(.79, .42, .006, .36, const Color(0xFFC6A779), 0);
    final shade = Path()
      ..moveTo(w * .73, h * .38)
      ..lineTo(w * .85, h * .38)
      ..lineTo(w * .88, h * .47)
      ..lineTo(w * .70, h * .47)
      ..close();
    canvas.drawPath(shade, Paint()..color = const Color(0xFFE8D6B7));
  }

  @override
  bool shouldRepaint(covariant _RoomPainter oldDelegate) => false;
}

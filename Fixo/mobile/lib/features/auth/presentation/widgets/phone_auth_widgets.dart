import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/theme/fixo_typography.dart';
import '../controllers/auth_controller.dart';

/// Top segmented pill switcher (`1. Phone Input` / `2. OTP Code`) from Screen 02.
class PhoneAuthStepSwitcher extends StatelessWidget {
  const PhoneAuthStepSwitcher({
    super.key,
    required this.activeStep,
    required this.onStepSelected,
    required this.isArabic,
  });

  final PhoneAuthStep activeStep;
  final ValueChanged<PhoneAuthStep> onStepSelected;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.surfaceContainer,
        borderRadius: FixoRadius.borderRadiusPill,
        boxShadow: FixoShadows.level1CardResting,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: _StepTabButton(
              buttonKey: const Key('tab-phone-input'),
              icon: Icons.smartphone_rounded,
              label: isArabic ? '١. رقم الموبايل' : '1. Phone Input',
              isSelected: activeStep == PhoneAuthStep.phoneInput,
              onTap: () => onStepSelected(PhoneAuthStep.phoneInput),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: _StepTabButton(
              buttonKey: const Key('tab-otp-code'),
              icon: Icons.pin_outlined,
              label: isArabic ? '٢. رمز التحقق' : '2. OTP Code',
              isSelected: activeStep == PhoneAuthStep.otpCode,
              onTap: () => onStepSelected(PhoneAuthStep.otpCode),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTabButton extends StatelessWidget {
  const _StepTabButton({
    required this.buttonKey,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final Key buttonKey;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;

    return Material(
      color: isSelected ? palette.primaryBrand : Colors.transparent,
      borderRadius: FixoRadius.borderRadiusPill,
      child: InkWell(
        key: buttonKey,
        onTap: onTap,
        borderRadius: FixoRadius.borderRadiusPill,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : palette.mutedText,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      FixoTypography.labelMd(
                        color: isSelected ? Colors.white : palette.mutedText,
                      ).copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 6 individual OTP digit boxes with active lime highlight cursor from Screen 02.
class FixoOtpDigitRow extends StatelessWidget {
  const FixoOtpDigitRow({
    super.key,
    required this.otpCode,
    required this.onTap,
  });

  final String otpCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;
    final activeIndex = otpCode.length.clamp(0, 5);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: List<Widget>.generate(6, (index) {
            final isFilled = index < otpCode.length;
            final isCursorActive = index == activeIndex && otpCode.length < 6;
            final digit = isFilled ? otpCode[index] : '';

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < 5 ? 8 : 0),
                child: Container(
                  key: Key('otp-digit-box-$index'),
                  height: 56,
                  decoration: BoxDecoration(
                    color: isCursorActive ? null : palette.surfaceLow,
                    gradient: isCursorActive
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              palette.limeAccent.withValues(alpha: 0.32),
                              palette.limeAccent.withValues(alpha: 0.10),
                            ],
                          )
                        : null,
                    borderRadius: FixoRadius.borderRadiusSm,
                    border: Border.all(
                      color: isCursorActive
                          ? palette.primaryBrand.withValues(alpha: 0.45)
                          : palette.subtleBorder,
                      width: isCursorActive ? 1.4 : 1.0,
                    ),
                    boxShadow: isCursorActive
                        ? FixoShadows.level2Interactive
                        : FixoShadows.level1CardResting,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isFilled)
                        Text(
                          digit,
                          style: FixoTypography.headlineMd(
                            color: palette.inkText,
                          ).copyWith(fontWeight: FontWeight.w800),
                        )
                      else if (isCursorActive)
                        Container(
                          width: 2,
                          height: 24,
                          decoration: BoxDecoration(
                            color: palette.deepForest,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        )
                      else
                        Container(
                          width: 10,
                          height: 2,
                          decoration: BoxDecoration(
                            color: FixoColors.outline.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      if (isCursorActive)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 20,
                            height: 4,
                            decoration: BoxDecoration(
                              color: palette.limeAccent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Tactile 3x4 numeric keypad card from State 2 of Screen 02 (`02 — Phone Auth & OTP`).
class FixoNumericKeypad extends StatelessWidget {
  const FixoNumericKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onBackspacePressed,
  });

  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: FixoRadius.borderRadiusLg,
        border: Border.all(color: palette.subtleBorder, width: 1),
        boxShadow: FixoShadows.level1CardResting,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            _buildKeypadRow(context, ['1', '2', '3']),
            const SizedBox(height: 8),
            _buildKeypadRow(context, ['4', '5', '6']),
            const SizedBox(height: 8),
            _buildKeypadRow(context, ['7', '8', '9']),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: Center(
                      child: Icon(
                        Icons.emergency_outlined,
                        size: 18,
                        color: FixoColors.outline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DigitKeyButton(
                    digit: '0',
                    onTap: () => onDigitPressed('0'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Material(
                    color: palette.surfaceLow,
                    borderRadius: FixoRadius.borderRadiusMd,
                    child: InkWell(
                      key: const Key('keypad-backspace'),
                      onTap: onBackspacePressed,
                      borderRadius: FixoRadius.borderRadiusMd,
                      child: SizedBox(
                        height: 48,
                        child: Center(
                          child: Icon(
                            Icons.backspace_outlined,
                            size: 21,
                            color: palette.mutedText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(BuildContext context, List<String> digits) {
    return Row(
      children: [
        for (int i = 0; i < digits.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _DigitKeyButton(
              digit: digits[i],
              onTap: () => onDigitPressed(digits[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _DigitKeyButton extends StatelessWidget {
  const _DigitKeyButton({required this.digit, required this.onTap});

  final String digit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;

    return Material(
      color: palette.surfaceLow,
      borderRadius: FixoRadius.borderRadiusMd,
      child: InkWell(
        key: Key('keypad-digit-$digit'),
        onTap: onTap,
        borderRadius: FixoRadius.borderRadiusMd,
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text(
              digit,
              style: FixoTypography.headlineSm(
                color: palette.inkText,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

/// Visual lifestyle mood anchor card from State 1 of Screen 02 (`h-28 rounded-xl`).
///
/// Renders a sunlit Zamalek Cairo apartment scene with a phone sign-in preview
/// and bottom `#002920` gradient scrim using local custom painting (no hotlinks).
class CairoLifestyleMoodAnchorCard extends StatelessWidget {
  const CairoLifestyleMoodAnchorCard({super.key, required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: FixoRadius.borderRadiusMd,
      child: SizedBox(
        height: 112,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: _ZamalekMoodPainter()),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    FixoColors.deepestForest.withValues(alpha: 0.86),
                    FixoColors.deepestForest.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Align(
                alignment: AlignmentDirectional.bottomStart,
                child: Row(
                  children: [
                    const Icon(
                      Icons.handyman_rounded,
                      size: 16,
                      color: FixoColors.limeAccent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isArabic
                            ? 'حجز خدمات الصيانة والإصلاح المنزلي في القاهرة والجيزة'
                            : 'Home maintenance & repair bookings across Cairo & Giza',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: FixoTypography.bodySm(
                          color: Colors.white,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZamalekMoodPainter extends CustomPainter {
  const _ZamalekMoodPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE6DEC8), Color(0xFFD2C7AF), Color(0xFF9EB09E)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Sunlit French balcony window panes on the left
    final windowGlow = Paint()
      ..color = const Color(0xFFFFFBF0).withValues(alpha: 0.65);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(16, 8, size.width * 0.28, size.height * 0.78),
        const Radius.circular(6),
      ),
      windowGlow,
    );

    // Botanical fiddle-leaf fig silhouette in the middle-left
    final leafPaint = Paint()..color = const Color(0xFF2B5B46);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.32, size.height * 0.42),
        width: 34,
        height: 44,
      ),
      leafPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.38, size.height * 0.52),
        width: 28,
        height: 36,
      ),
      Paint()..color = const Color(0xFF24262B),
    );

    // Minimalist phone device frame on the right (matching Screen 02 mood photo)
    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.62, 14, 72, size.height - 10),
      const Radius.circular(10),
    );
    canvas.drawRRect(phoneRect, Paint()..color = const Color(0xFF24262B));
    final screenRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.62 + 3, 17, 66, size.height - 16),
      const Radius.circular(8),
    );
    canvas.drawRRect(screenRect, Paint()..color = const Color(0xFFF6F2EB));

    // Tiny UI bars inside the miniature phone screen
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.62 + 10, 32, 52, 8),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF24262B),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.62 + 10, 46, 52, 10),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFC6A779),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

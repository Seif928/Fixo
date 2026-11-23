import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import '../theme/fixo_colors.dart';
import '../theme/fixo_spacing.dart';
import '../theme/fixo_typography.dart';

/// Standard FIXO form text field with label and optional trailing metadata label.
class FixoTextField extends StatelessWidget {
  const FixoTextField({
    super.key,
    required this.label,
    this.secondaryLabel,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixWidget,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.onChanged,
  });

  final String label;
  final String? secondaryLabel;
  final TextEditingController? controller;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: FixoTypography.labelMd(
                  color: palette.mutedText,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (secondaryLabel != null)
              Text(
                secondaryLabel!,
                style: FixoTypography.bodySm(color: palette.mutedText),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          onChanged: onChanged,
          style: FixoTypography.bodyMd(color: palette.inkText),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: palette.mutedText)
                : null,
            suffixIcon: suffixWidget,
          ),
        ),
      ],
    );
  }
}

/// Egyptian `+20` mobile number input with inline Egypt flag motif.
class FixoEgyptPhoneField extends StatelessWidget {
  const FixoEgyptPhoneField({
    super.key,
    required this.controller,
    this.label = 'Egyptian Mobile Number',
    this.hintText = '010 2345 6789',
    this.onChanged,
    this.onClear,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: FixoTypography.labelMd(
            color: palette.mutedText,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: FixoSpacing.sm),
        Row(
          children: [
            Container(
              height: FixoSpacing.minTouchTarget,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: palette.primaryBrand,
                borderRadius: FixoRadius.borderRadiusSm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _EgyptFlagMotif(),
                  const SizedBox(width: FixoSpacing.sm),
                  Text(
                    '+20',
                    style: FixoTypography.labelLg(
                      color: palette.onPrimary,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: FixoSpacing.sm),
            Expanded(
              child: TextField(
                key: const Key('input-egypt-phone'),
                controller: controller,
                keyboardType: TextInputType.phone,
                onChanged: onChanged,
                style: FixoTypography.headlineSm(
                  color: palette.inkText,
                ).copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.4),
                decoration: InputDecoration(
                  fillColor: palette.surfaceLow,
                  hintText: hintText,
                  suffixIcon: onClear != null
                      ? IconButton(
                          onPressed: onClear,
                          tooltip: 'Clear number',
                          icon: Icon(
                            Icons.cancel_outlined,
                            size: 20,
                            color: palette.mutedText,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EgyptFlagMotif extends StatelessWidget {
  const _EgyptFlagMotif();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: 20,
        height: 14,
        child: Column(
          children: [
            Expanded(child: Container(color: const Color(0xFFC8102E))),
            Expanded(
              child: Container(
                color: Colors.white,
                alignment: Alignment.center,
                child: Container(
                  width: 5,
                  height: 3.5,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC09300),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Expanded(child: Container(color: Colors.black)),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/email_access_service.dart';

/// Prepares Web identity SDKs before a click, preserving popup user activation.
class GoogleSignInButton extends ConsumerStatefulWidget {
  const GoogleSignInButton({
    super.key,
    this.buttonKey,
    required this.label,
    required this.isArabic,
    required this.onPressed,
    this.style,
  });
  final Key? buttonKey;
  final Widget label;
  final bool isArabic;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _connecting = false, _ready = true;
  @override
  void initState() {
    super.initState();
    if (ref.read(emailAccessProvider).requiresGooglePreparation) {
      _ready = false;
      _connecting = true;
      unawaited(_prepare());
    }
  }

  Future<void> _prepare() async {
    try {
      await ref.read(emailAccessProvider).prepareGoogle();
      if (mounted) {
        setState(() {
          _ready = true;
          _connecting = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _ready = false;
          _connecting = false;
        });
      }
    }
  }

  void _retryPreparation() {
    setState(() => _connecting = true);
    unawaited(_prepare());
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    key: widget.buttonKey,
    style:
        (widget.style ??
                OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ))
            .copyWith(
              backgroundColor: const WidgetStatePropertyAll(Colors.white),
              foregroundColor: const WidgetStatePropertyAll(Color(0xFF1F1F1F)),
            ),
    onPressed: widget.onPressed == null || _connecting
        ? null
        : _ready
        ? widget.onPressed
        : _retryPreparation,
    icon: Image.asset(
      'assets/brand/google-g.png',
      width: 20,
      height: 20,
      filterQuality: FilterQuality.high,
      excludeFromSemantics: true,
    ),
    label: _connecting
        ? Text(
            widget.isArabic ? 'جارٍ الاتصال بجوجل…' : 'Connecting to Google…',
          )
        : !_ready
        ? Text(widget.isArabic ? 'إعادة الاتصال بجوجل' : 'Reconnect to Google')
        : widget.label,
  );
}

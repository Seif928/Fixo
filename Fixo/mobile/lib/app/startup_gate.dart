import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_locale_controller.dart';
import '../core/theme/fixo_theme.dart';

/// Paints startup immediately; routing and device recovery wait for auth restore.
class FixoStartupGate extends ConsumerStatefulWidget {
  const FixoStartupGate({
    super.key,
    required this.restoration,
    required this.child,
    this.onReady,
  });

  final Future<void> restoration;
  final Widget child;
  final VoidCallback? onReady;

  @override
  ConsumerState<FixoStartupGate> createState() => _FixoStartupGateState();
}

class _FixoStartupGateState extends ConsumerState<FixoStartupGate> {
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_restore());
  }

  Future<void> _restore() async {
    try {
      await widget.restoration;
      if (!mounted) return;
      setState(() => _ready = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onReady?.call();
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.child;
    final locale = ref.watch(appLocaleProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: FixoTheme.light(locale: locale),
      darkTheme: FixoTheme.dark(locale: locale),
      themeMode: ref.watch(appThemeModeProvider),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'FIXO',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              if (!_failed)
                const CircularProgressIndicator()
              else
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    locale.languageCode == 'ar'
                        ? 'تعذّر فتح التطبيق. أعد تحميل الصفحة وحاول مجددًا.'
                        : 'Could not start the app. Reload and try again.',
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

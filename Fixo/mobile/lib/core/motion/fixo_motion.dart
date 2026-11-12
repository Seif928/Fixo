import 'package:material_ui/material_ui.dart';

/// Short, finite motion shared across FIXO. Never delays a user's action.
abstract final class FixoMotion {
  static const entrance = Duration(milliseconds: 280);
  static const page = Duration(milliseconds: 220);
  static const press = Duration(milliseconds: 110);
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);
}

class FixoEntrance extends StatefulWidget {
  const FixoEntrance({super.key, required this.child});
  final Widget child;

  @override
  State<FixoEntrance> createState() => _FixoEntranceState();
}

class _FixoEntranceState extends State<FixoEntrance>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: FixoMotion.entrance,
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (FixoMotion.reduced(context)) {
      _controller.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (FixoMotion.reduced(context)) return widget.child;
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, .025),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

/// InkWell keeps native focus, keyboard, hover and gesture-cancellation behavior.
class FixoPressFeedback extends StatefulWidget {
  const FixoPressFeedback({
    super.key,
    required this.enabled,
    required this.builder,
  });
  final bool enabled;
  final Widget Function(ValueChanged<bool> onHighlightChanged) builder;

  @override
  State<FixoPressFeedback> createState() => _FixoPressFeedbackState();
}

class _FixoPressFeedbackState extends State<FixoPressFeedback> {
  bool _pressed = false;

  @override
  void didUpdateWidget(covariant FixoPressFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) _pressed = false;
  }

  @override
  Widget build(BuildContext context) => Semantics(child: AnimatedScale(
    scale: widget.enabled && _pressed && !FixoMotion.reduced(context)
        ? .985
        : 1,
    duration: FixoMotion.reduced(context) ? Duration.zero : FixoMotion.press,
    curve: Curves.easeOutCubic,
    child: Opacity(
      opacity: widget.enabled ? 1 : .6,
      child: widget.builder((value) {
        if (mounted && _pressed != value) setState(() => _pressed = value);
      }),
    ),
  ));
}

class FixoPageMotion extends StatelessWidget {
  const FixoPageMotion({
    super.key,
    required this.animation,
    required this.child,
    this.slide = true,
  });
  final Animation<double> animation;
  final Widget child;
  final bool slide;

  @override
  Widget build(BuildContext context) {
    if (FixoMotion.reduced(context)) return child;
    final curve = CurveTween(curve: Curves.easeOutCubic);
    final faded = FadeTransition(opacity: animation.drive(curve), child: child);
    if (!slide) return faded;
    return SlideTransition(
      position: animation.drive(
        Tween(begin: const Offset(0, .02), end: Offset.zero).chain(curve),
      ),
      child: faded,
    );
  }
}

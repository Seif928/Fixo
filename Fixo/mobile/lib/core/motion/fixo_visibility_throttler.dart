import 'package:material_ui/material_ui.dart';
import 'fixo_motion.dart';

/// Lightweight lifecycle, route, and scroll-viewport visibility throttler for
/// decorative `AnimationController` effects in FIXO.
///
/// Pauses the ticker when:
/// 1. App lifecycle is not resumed (`paused`, `inactive`, `hidden`).
/// 2. Enclosing `ModalRoute` is obscured by a pushed route (`isCurrent == false`).
/// 3. Widget is scrolled outside the visible viewport of its ancestor `Scrollable` or window.
/// 4. Accessibility mode requests reduced motion (`FixoMotion.reduced(context)`).
/// 5. Test harness is active, unless explicitly overridden via [enableInTests].
class FixoVisibilityThrottler extends StatefulWidget {
  const FixoVisibilityThrottler({
    super.key,
    required this.controller,
    required this.child,
    this.repeatReverse = false,
    this.repeat = false,
    this.viewportBuffer = 50.0,
    this.enableInTests = false,
    this.onVisibilityChanged,
  });

  /// The AnimationController to throttle.
  final AnimationController controller;

  /// The child widget (typically AnimatedBuilder or CustomPaint).
  final Widget child;

  /// Whether controller.repeat should be invoked with reverse: true.
  final bool repeatReverse;

  /// Decorative effects play once by default, without repainting an idle page.
  final bool repeat;

  /// Pre-roll buffer in logical pixels to anticipate scrolling into view.
  final double viewportBuffer;

  /// Whether to allow the ticker to run inside automated widget test environments.
  final bool enableInTests;

  /// Optional callback invoked when effective visibility changes.
  final ValueChanged<bool>? onVisibilityChanged;

  @override
  State<FixoVisibilityThrottler> createState() =>
      FixoVisibilityThrottlerState();
}

class FixoVisibilityThrottlerState extends State<FixoVisibilityThrottler>
    with WidgetsBindingObserver {
  ScrollPosition? _scrollPosition;
  ModalRoute<dynamic>? _currentRoute;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  bool _isDisposed = false;
  bool _isCurrentlyVisible = false;

  /// Public accessor for testing and telemetry.
  bool get isCurrentlyVisible => _isCurrentlyVisible;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        _evaluateAndApply();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateScrollListener();
    _updateRouteListener();
    _evaluateAndApply();
  }

  @override
  void didUpdateWidget(covariant FixoVisibilityThrottler oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller.isAnimating) {
        oldWidget.controller.stop();
      }
      _evaluateAndApply();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    _evaluateAndApply();
  }

  void _updateScrollListener() {
    final scrollable = Scrollable.maybeOf(context);
    final newPosition = scrollable?.position;
    if (_scrollPosition != newPosition) {
      _scrollPosition?.removeListener(_onScrollChanged);
      _scrollPosition = newPosition;
      _scrollPosition?.addListener(_onScrollChanged);
    }
  }

  void _onScrollChanged() {
    _evaluateAndApply();
  }

  void _updateRouteListener() {
    final newRoute = ModalRoute.of(context);
    if (_currentRoute != newRoute) {
      _currentRoute?.secondaryAnimation?.removeListener(
        _onRouteAnimationChanged,
      );
      _currentRoute = newRoute;
      _currentRoute?.secondaryAnimation?.addListener(_onRouteAnimationChanged);
    }
  }

  void _onRouteAnimationChanged() {
    _evaluateAndApply();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _scrollPosition?.removeListener(_onScrollChanged);
    _currentRoute?.secondaryAnimation?.removeListener(_onRouteAnimationChanged);
    super.dispose();
  }

  bool _computeVisibility() {
    if (!mounted || _isDisposed) return false;

    if (_lifecycleState != AppLifecycleState.resumed) {
      return false;
    }

    if (FixoMotion.reduced(context)) {
      return false;
    }

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );
    if (isTest && !widget.enableInTests) {
      return false;
    }

    if (_currentRoute != null && !_currentRoute!.isCurrent) {
      return false;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached || !renderBox.hasSize) {
      return false;
    }

    try {
      final widgetGlobalPos = renderBox.localToGlobal(Offset.zero);
      final widgetRect = widgetGlobalPos & renderBox.size;

      final screenSize = MediaQuery.sizeOf(context);
      final screenRect = (Offset.zero & screenSize).inflate(
        widget.viewportBuffer,
      );

      if (!widgetRect.overlaps(screenRect)) {
        return false;
      }

      final scrollable = Scrollable.maybeOf(context);
      if (scrollable != null) {
        final scrollableBox =
            scrollable.context.findRenderObject() as RenderBox?;
        if (scrollableBox != null &&
            scrollableBox.attached &&
            scrollableBox.hasSize) {
          final scrollableGlobalPos = scrollableBox.localToGlobal(Offset.zero);
          final scrollableRect = (scrollableGlobalPos & scrollableBox.size)
              .inflate(widget.viewportBuffer);
          if (!widgetRect.overlaps(scrollableRect)) {
            return false;
          }
        }
      }

      return true;
    } catch (_) {
      return true;
    }
  }

  void _evaluateAndApply() {
    if (!mounted || _isDisposed) return;

    final shouldAnimate = _computeVisibility();

    if (_isCurrentlyVisible != shouldAnimate) {
      _isCurrentlyVisible = shouldAnimate;
      widget.onVisibilityChanged?.call(shouldAnimate);
    }

    try {
      if (shouldAnimate) {
        if (!widget.controller.isAnimating &&
            (widget.repeat ||
                widget.controller.status != AnimationStatus.completed)) {
          if (!widget.repeat) {
            widget.controller.forward();
          } else if (widget.repeatReverse) {
            widget.controller.repeat(reverse: true);
          } else {
            widget.controller.repeat();
          }
        }
      } else {
        if (widget.controller.isAnimating) {
          widget.controller.stop();
        }
      }
    } catch (_) {
      // Controller may already be disposed by parent State
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

import 'dart:math' as math;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';
import '../motion/fixo_motion.dart';

/// Premium 3D tilt surface for FIXO cards.
///
/// Rotates its child in perspective toward the pointer (mouse hover on web and
/// desktop, finger press on touch screens) and sweeps a soft specular glare
/// across the surface. At rest it renders the child with an identity
/// transform, so static layouts and golden snapshots are unchanged.
///
/// Uses a raw [Listener]/[MouseRegion], so taps, ink ripples and scrolling of
/// the child keep working. Honours the platform "reduce motion" setting.
class FixoTilt3D extends StatefulWidget {
  const FixoTilt3D({
    super.key,
    required this.child,
    this.maxTilt = 0.10,
    this.glare = true,
    this.glareOpacity = 0.20,
    this.borderRadius = BorderRadius.zero,
    this.pressScale = 0.985,
  });

  final Widget child;

  /// Maximum rotation in radians on each axis.
  final double maxTilt;

  /// Whether to paint the moving specular highlight.
  final bool glare;

  /// Peak opacity of the highlight at full tilt.
  final double glareOpacity;

  /// Clip for the glare so it follows the card's rounded corners.
  final BorderRadius borderRadius;

  /// Scale applied while a finger or mouse button is held down.
  final double pressScale;

  @override
  State<FixoTilt3D> createState() => _FixoTilt3DState();
}

class _FixoTilt3DState extends State<FixoTilt3D>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
  }

  Offset _from = Offset.zero;
  Offset _to = Offset.zero;
  double _scaleFrom = 1, _scaleTo = 1;

  Offset get _current => Offset.lerp(
    _from,
    _to,
    Curves.easeOutCubic.transform(_controller.value),
  )!;
  double get _scale =>
      _scaleFrom +
      (_scaleTo - _scaleFrom) * Curves.easeOut.transform(_controller.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(Offset target, {double? scale, Duration? duration}) {
    _from = _current;
    _scaleFrom = _scale;
    _to = target;
    if (scale != null) _scaleTo = scale;
    _controller.duration = duration ?? const Duration(milliseconds: 140);
    _controller.forward(from: 0);
  }

  Offset _normalized(Offset local) {
    final size = context.size;
    if (size == null || size.isEmpty) return Offset.zero;
    return Offset(
      (local.dx / size.width * 2 - 1).clamp(-1.0, 1.0),
      (local.dy / size.height * 2 - 1).clamp(-1.0, 1.0),
    );
  }

  void _release() => _animateTo(
    Offset.zero,
    scale: 1,
    duration: const Duration(milliseconds: 420),
  );

  @override
  Widget build(BuildContext context) {
    if (!FixoMotion.expensiveEffects(context)) {
      return widget.child;
    }

    return MouseRegion(
      onHover: (e) => _animateTo(_normalized(e.localPosition)),
      onExit: (_) => _release(),
      child: Listener(
        onPointerDown: (e) =>
            _animateTo(_normalized(e.localPosition), scale: widget.pressScale),
        onPointerMove: (e) => _animateTo(_normalized(e.localPosition)),
        onPointerUp: (e) => e.kind == PointerDeviceKind.mouse
            ? _animateTo(_normalized(e.localPosition), scale: 1)
            : _release(),
        onPointerCancel: (_) => _release(),
        child: AnimatedBuilder(
          animation: _controller,
          child: widget.child,
          builder: (context, child) {
            final p = _current;
            final scale = _scale;
            final strength = math.min(1.0, p.distance);
            final resting = strength == 0 && scale == 1;

            final matrix = resting
                ? Matrix4.identity()
                : (Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateX(-p.dy * widget.maxTilt)
                    ..rotateY(p.dx * widget.maxTilt)
                    ..scaleByDouble(scale, scale, 1, 1));

            return Transform(
              alignment: Alignment.center,
              transform: matrix,
              child: Stack(
                children: [
                  child!,
                  if (widget.glare && !resting)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ClipRRect(
                          borderRadius: widget.borderRadius,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment(p.dx, p.dy),
                                radius: 1.1,
                                colors: [
                                  Colors.white.withValues(
                                    alpha: widget.glareOpacity * strength,
                                  ),
                                  Colors.white.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

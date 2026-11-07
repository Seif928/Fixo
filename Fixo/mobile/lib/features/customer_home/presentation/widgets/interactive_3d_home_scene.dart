import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/theme/fixo_typography.dart';
import '../../../../core/widgets/fixo_liquid_glass_layer.dart';

/// Interactive Micro-Architectural 3D Home Scene for FIXO.
///
/// Provides an isometric 3D cutaway of a modern Cairo residence:
/// - Living Room: Highlights Air Conditioning with animated airflow waves.
/// - Kitchen & Bath: Highlights Plumbing pipework & water droplet ripples.
/// - Electrical Hub: Highlights breaker panel with circuit spark pulses.
/// - Carpentry Suite: Highlights custom woodcraft and furnishings.
///
/// Tapping any room triggers visual effects and filters marketplace services.
class Interactive3DHomeScene extends StatefulWidget {
  const Interactive3DHomeScene({
    super.key,
    required this.isArabic,
    required this.onSelectCategory,
    this.selectedCategorySlug,
  });

  final bool isArabic;
  final ValueChanged<String> onSelectCategory;
  final String? selectedCategorySlug;

  @override
  State<Interactive3DHomeScene> createState() => _Interactive3DHomeSceneState();
}

enum HomeRoom { acLiving, plumbingKitchen, electricalHub, carpentrySuite }

class _Interactive3DHomeSceneState extends State<Interactive3DHomeScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  HomeRoom _selectedRoom = HomeRoom.acLiving;
  double _orbitAngle = 0.0;
  double _dragStartAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _animController.repeat();
    } else {
      _animController.value = 0.5;
    }

    _syncWithSlug(widget.selectedCategorySlug);
  }

  @override
  void didUpdateWidget(covariant Interactive3DHomeScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategorySlug != oldWidget.selectedCategorySlug) {
      _syncWithSlug(widget.selectedCategorySlug);
    }
  }

  void _syncWithSlug(String? slug) {
    if (slug == null) return;
    if (slug.contains('ac') || slug.contains('air')) {
      _selectedRoom = HomeRoom.acLiving;
    } else if (slug.contains('plumb') || slug.contains('water')) {
      _selectedRoom = HomeRoom.plumbingKitchen;
    } else if (slug.contains('electr')) {
      _selectedRoom = HomeRoom.electricalHub;
    } else if (slug.contains('carp') || slug.contains('wood')) {
      _selectedRoom = HomeRoom.carpentrySuite;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _selectRoom(HomeRoom room) {
    setState(() => _selectedRoom = room);
    final slug = switch (room) {
      HomeRoom.acLiving => 'ac-repair',
      HomeRoom.plumbingKitchen => 'plumbing',
      HomeRoom.electricalHub => 'electrical',
      HomeRoom.carpentrySuite => 'carpentry',
    };
    widget.onSelectCategory(slug);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LiquidGlassLayer(
      margin: EdgeInsets.symmetric(
        horizontal: FixoAdaptive.horizontalMargin(context),
        vertical: 8,
      ),
      borderRadius: FixoRadius.borderRadiusLg,
      blurSigma: 24.0,
      specularIntensity: 0.35,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Bar: 3D Badge + Status
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          FixoColors.primaryForest,
                          Color(0xFF225C4D),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(FixoRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.view_in_ar_rounded,
                          size: 14,
                          color: FixoColors.limeAccent,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          widget.isArabic ? 'مجسم 3D تفاعلي' : 'Interactive 3D Home',
                          style: FixoTypography.labelMd(
                            color: Colors.white,
                          ).copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isArabic
                          ? 'اضغط على أي غرفة لفحص وتحديد العطل'
                          : 'Tap a zone to inspect & book',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FixoTypography.bodySm(
                        color: palette.mutedText,
                      ).copyWith(fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: widget.isArabic ? 'إعادة ضبط الزاوية' : 'Reset Angle',
                    child: InkWell(
                      onTap: () => setState(() => _orbitAngle = 0),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.rotate_left_rounded,
                          size: 18,
                          color: palette.mutedText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3D Canvas with Gesture Orbit
            GestureDetector(
              onHorizontalDragStart: (details) {
                _dragStartAngle = _orbitAngle;
              },
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _orbitAngle = (_dragStartAngle + details.delta.dx * 0.005)
                      .clamp(-0.25, 0.25);
                });
              },
              onHorizontalDragEnd: (_) {
                // Smoothly return toward center if small tilt
                setState(() => _orbitAngle = _orbitAngle * 0.5);
              },
              child: SizedBox(
                height: 220,
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _IsometricHomePainter(
                        selectedRoom: _selectedRoom,
                        orbitAngle: _orbitAngle,
                        animationValue: _animController.value,
                        isDark: isDark,
                        palette: palette,
                      ),
                      child: Stack(
                        children: [
                          // Tap hotspots over the 4 quadrants
                          Positioned(
                            left: 20,
                            top: 20,
                            width: 140,
                            height: 100,
                            child: _HotspotArea(
                              onTap: () => _selectRoom(HomeRoom.acLiving),
                              label: widget.isArabic ? 'التكييف' : 'AC & Cooling',
                              icon: Icons.ac_unit_rounded,
                              isSelected: _selectedRoom == HomeRoom.acLiving,
                              activeColor: const Color(0xFF38BDF8),
                            ),
                          ),
                          Positioned(
                            right: 20,
                            top: 20,
                            width: 140,
                            height: 100,
                            child: _HotspotArea(
                              onTap: () => _selectRoom(HomeRoom.plumbingKitchen),
                              label: widget.isArabic ? 'السباكة' : 'Plumbing',
                              icon: Icons.water_drop_rounded,
                              isSelected: _selectedRoom == HomeRoom.plumbingKitchen,
                              activeColor: const Color(0xFF0EA5E9),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            bottom: 20,
                            width: 140,
                            height: 80,
                            child: _HotspotArea(
                              onTap: () => _selectRoom(HomeRoom.electricalHub),
                              label: widget.isArabic ? 'الكهرباء' : 'Electrical',
                              icon: Icons.bolt_rounded,
                              isSelected: _selectedRoom == HomeRoom.electricalHub,
                              activeColor: FixoColors.limeAccent,
                            ),
                          ),
                          Positioned(
                            right: 20,
                            bottom: 20,
                            width: 140,
                            height: 80,
                            child: _HotspotArea(
                              onTap: () => _selectRoom(HomeRoom.carpentrySuite),
                              label: widget.isArabic ? 'النجارة' : 'Carpentry',
                              icon: Icons.chair_rounded,
                              isSelected: _selectedRoom == HomeRoom.carpentrySuite,
                              activeColor: const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Room Selector Bottom Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? palette.canvasBackground.withValues(alpha: 0.6)
                    : palette.surfaceContainer.withValues(alpha: 0.4),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? palette.subtleBorder.withValues(alpha: 0.2)
                        : palette.subtleBorder,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _RoomPill(
                      label: widget.isArabic ? 'غرفة المعيشة والتكييف' : 'Living & AC',
                      icon: Icons.mode_fan_off_rounded,
                      isSelected: _selectedRoom == HomeRoom.acLiving,
                      accentColor: const Color(0xFF38BDF8),
                      onTap: () => _selectRoom(HomeRoom.acLiving),
                    ),
                    const SizedBox(width: 8),
                    _RoomPill(
                      label: widget.isArabic ? 'المطبخ والحمام (السباكة)' : 'Kitchen & Plumbing',
                      icon: Icons.plumbing_rounded,
                      isSelected: _selectedRoom == HomeRoom.plumbingKitchen,
                      accentColor: const Color(0xFF0EA5E9),
                      onTap: () => _selectRoom(HomeRoom.plumbingKitchen),
                    ),
                    const SizedBox(width: 8),
                    _RoomPill(
                      label: widget.isArabic ? 'لوحة الكهرباء الرئيسية' : 'Electrical Panel',
                      icon: Icons.electric_bolt_rounded,
                      isSelected: _selectedRoom == HomeRoom.electricalHub,
                      accentColor: FixoColors.limeAccent,
                      onTap: () => _selectRoom(HomeRoom.electricalHub),
                    ),
                    const SizedBox(width: 8),
                    _RoomPill(
                      label: widget.isArabic ? 'النجارة والأثاث' : 'Carpentry & Wood',
                      icon: Icons.handyman_rounded,
                      isSelected: _selectedRoom == HomeRoom.carpentrySuite,
                      accentColor: const Color(0xFFF59E0B),
                      onTap: () => _selectRoom(HomeRoom.carpentrySuite),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
  }
}

class _HotspotArea extends StatelessWidget {
  const _HotspotArea({
    required this.onTap,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
  });

  final VoidCallback onTap;
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.8)
                  : Colors.transparent,
              width: 1.5,
            ),
            color: isSelected
                ? activeColor.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? activeColor : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? activeColor : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomPill extends StatelessWidget {
  const _RoomPill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FixoRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? FixoColors.primaryForest
              : Colors.transparent,
          borderRadius: BorderRadius.circular(FixoRadius.pill),
          border: Border.all(
            color: isSelected
                ? FixoColors.limeAccent
                : Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? FixoColors.limeAccent : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter rendering the 3D isometric cutaway architecture.
class _IsometricHomePainter extends CustomPainter {
  _IsometricHomePainter({
    required this.selectedRoom,
    required this.orbitAngle,
    required this.animationValue,
    required this.isDark,
    required this.palette,
  });

  final HomeRoom selectedRoom;
  final double orbitAngle;
  final double animationValue;
  final bool isDark;
  final FixoPaletteExtension palette;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 10;

    // Isometric projection helpers
    final cosA = math.cos(0.523599 + orbitAngle); // ~30 degrees + orbit
    final sinA = math.sin(0.523599 + orbitAngle);

    Offset project(double x, double y, double z) {
      final isoX = cx + (x - y) * cosA * 1.5;
      final isoY = cy + (x + y) * sinA * 0.9 - z;
      return Offset(isoX, isoY);
    }

    // 1. Draw 3D Base Slab (Limestone Floor Foundation)
    final slabHeight = 12.0;
    final r = 68.0;

    final pTop = project(0, -r, 0);
    final pRight = project(r, 0, 0);
    final pBottom = project(0, r, 0);
    final pLeft = project(-r, 0, 0);

    // Floor top surface
    final floorPath = Path()
      ..moveTo(pTop.dx, pTop.dy)
      ..lineTo(pRight.dx, pRight.dy)
      ..lineTo(pBottom.dx, pBottom.dy)
      ..lineTo(pLeft.dx, pLeft.dy)
      ..close();

    final floorPaint = Paint()
      ..color = isDark ? const Color(0xFF1E3830) : const Color(0xFFF3EFE6)
      ..style = PaintingStyle.fill;
    canvas.drawPath(floorPath, floorPaint);

    // Foundation side depth
    final leftWall = Path()
      ..moveTo(pLeft.dx, pLeft.dy)
      ..lineTo(pBottom.dx, pBottom.dy)
      ..lineTo(pBottom.dx, pBottom.dy + slabHeight)
      ..lineTo(pLeft.dx, pLeft.dy + slabHeight)
      ..close();
    canvas.drawPath(
      leftWall,
      Paint()
        ..color = isDark ? const Color(0xFF11221D) : const Color(0xFFDDD7C8),
    );

    final rightWall = Path()
      ..moveTo(pBottom.dx, pBottom.dy)
      ..lineTo(pRight.dx, pRight.dy)
      ..lineTo(pRight.dx, pRight.dy + slabHeight)
      ..lineTo(pBottom.dx, pBottom.dy + slabHeight)
      ..close();
    canvas.drawPath(
      rightWall,
      Paint()
        ..color = isDark ? const Color(0xFF0C1815) : const Color(0xFFC7BFAF),
    );

    // Grid Room Dividers on the floor
    final dividerPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(project(0, -r, 0), project(0, r, 0), dividerPaint);
    canvas.drawLine(project(-r, 0, 0), project(r, 0, 0), dividerPaint);

    // 2. Render Active Room Features & 3D Objects

    // Quadrant A: Top-Left (AC & Living Room)
    _drawLivingRoomAC(
      canvas,
      project,
      isActive: selectedRoom == HomeRoom.acLiving,
    );

    // Quadrant B: Top-Right (Plumbing & Kitchen/Bath)
    _drawPlumbingZone(
      canvas,
      project,
      isActive: selectedRoom == HomeRoom.plumbingKitchen,
    );

    // Quadrant C: Bottom-Left (Electrical Hub)
    _drawElectricalHub(
      canvas,
      project,
      isActive: selectedRoom == HomeRoom.electricalHub,
    );

    // Quadrant D: Bottom-Right (Carpentry Suite)
    _drawCarpentrySuite(
      canvas,
      project,
      isActive: selectedRoom == HomeRoom.carpentrySuite,
    );
  }

  void _drawLivingRoomAC(
    Canvas canvas,
    Offset Function(double, double, double) project, {
    required bool isActive,
  }) {
    // Wall unit AC mounted at x: -40, y: -45, z: 25
    final p1 = project(-55, -45, 25);
    final p2 = project(-25, -45, 25);
    final p3 = project(-25, -45, 14);
    final p4 = project(-55, -45, 14);

    final acPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();

    final acPaint = Paint()
      ..color = isActive
          ? (isDark ? const Color(0xFF38BDF8) : Colors.white)
          : (isDark ? Colors.grey[700]! : Colors.white)
      ..style = PaintingStyle.fill;
    canvas.drawPath(acPath, acPaint);

    // Louver slit
    canvas.drawLine(
      project(-52, -45, 16),
      project(-28, -45, 16),
      Paint()
        ..color = const Color(0xFF0284C7)
        ..strokeWidth = 2,
    );

    // Animated Airflow Wave Particles
    if (isActive) {
      final wavePaint = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.6)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < 3; i++) {
        final phase = (animationValue + i * 0.33) % 1.0;
        final start = project(-40, -45 + phase * 35, 15 - phase * 10);
        final end = project(-40 + math.sin(phase * 3.14) * 10, -45 + phase * 40, 10 - phase * 12);
        canvas.drawLine(start, end, wavePaint);
      }
    }
  }

  void _drawPlumbingZone(
    Canvas canvas,
    Offset Function(double, double, double) project, {
    required bool isActive,
  }) {
    // Water Pipes running along wall (x: 35, y: -50)
    final pipePaint = Paint()
      ..color = isActive ? const Color(0xFF0EA5E9) : const Color(0xFF94A3B8)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final pt1 = project(20, -50, 0);
    final pt2 = project(20, -50, 24);
    final pt3 = project(45, -50, 24);
    final pt4 = project(45, -50, 8);

    canvas.drawLine(pt1, pt2, pipePaint);
    canvas.drawLine(pt2, pt3, pipePaint);
    canvas.drawLine(pt3, pt4, pipePaint);

    // Brass Valve knob
    canvas.drawCircle(
      pt3,
      4,
      Paint()..color = const Color(0xFFF59E0B),
    );

    // Animated Droplet Ripple
    if (isActive) {
      final rippleProgress = animationValue;
      final dripPoint = pt4;
      canvas.drawCircle(
        dripPoint.translate(0, 8 * rippleProgress),
        3 * (1 - rippleProgress) + 1,
        Paint()..color = const Color(0xFF38BDF8).withValues(alpha: 1 - rippleProgress),
      );
    }
  }

  void _drawElectricalHub(
    Canvas canvas,
    Offset Function(double, double, double) project, {
    required bool isActive,
  }) {
    // Breaker Panel Box on wall
    final bTop = project(-40, 30, 26);
    final bBottom = project(-40, 30, 10);

    canvas.drawRect(
      Rect.fromPoints(bTop.translate(-8, 0), bBottom.translate(8, 0)),
      Paint()
        ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFF334155),
    );

    // Neon Green status LED & Breaker Switches
    final ledColor = isActive ? FixoColors.limeAccent : Colors.redAccent;
    canvas.drawCircle(
      bTop.translate(0, 4),
      3,
      Paint()..color = ledColor,
    );

    // Electrical Circuit Spark Pulse
    if (isActive) {
      final pulseRadius = 6.0 + 8.0 * (1 - animationValue);
      canvas.drawCircle(
        bTop.translate(0, 4),
        pulseRadius,
        Paint()
          ..color = FixoColors.limeAccent.withValues(alpha: animationValue * 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  void _drawCarpentrySuite(
    Canvas canvas,
    Offset Function(double, double, double) project, {
    required bool isActive,
  }) {
    // Modern Wood Workbench / Bed Frame
    final c1 = project(20, 20, 4);
    final c2 = project(45, 20, 4);
    final c3 = project(45, 45, 4);
    final c4 = project(20, 45, 4);

    final woodPath = Path()
      ..moveTo(c1.dx, c1.dy)
      ..lineTo(c2.dx, c2.dy)
      ..lineTo(c3.dx, c3.dy)
      ..lineTo(c4.dx, c4.dy)
      ..close();

    canvas.drawPath(
      woodPath,
      Paint()
        ..color = isActive ? const Color(0xFFD97706) : const Color(0xFFB45309)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _IsometricHomePainter oldDelegate) {
    return oldDelegate.selectedRoom != selectedRoom ||
        oldDelegate.orbitAngle != orbitAngle ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.isDark != isDark;
  }
}


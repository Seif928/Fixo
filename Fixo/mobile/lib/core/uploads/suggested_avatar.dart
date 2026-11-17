import 'dart:convert';
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import 'device_media_picker.dart';

/// Original local illustrations: no stock portraits, remote services or fees.
const suggestedAvatarCount = 24;

class SuggestedAvatar extends StatelessWidget {
  const SuggestedAvatar({super.key, required this.index, this.size = 64});
  final int index;
  final double size;
  @override
  Widget build(BuildContext context) => ClipOval(
    child: CustomPaint(size: Size.square(size), painter: _AvatarPainter(index)),
  );
}

Future<PickedPrivateMedia> renderSuggestedAvatar(int index) async {
  if (index < 0 || index >= suggestedAvatarCount) {
    throw RangeError.range(index, 0, suggestedAvatarCount - 1);
  }
  final recorder = ui.PictureRecorder();
  _AvatarPainter(index).paint(Canvas(recorder), const Size.square(256));
  final picture = recorder.endRecording();
  final image = await picture.toImage(256, 256);
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) throw StateError('Avatar rendering failed.');
    return PickedPrivateMedia(
      fileName: 'fixo-avatar-${index + 1}.png',
      mimeType: 'image/png',
      contentBase64: base64Encode(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      ),
      sourceLabelEn: 'FIXO illustration',
      sourceLabelAr: 'أفاتار FIXO',
    );
  } finally {
    image.dispose();
    picture.dispose();
  }
}

class _AvatarPainter extends CustomPainter {
  const _AvatarPainter(this.index);
  final int index;
  static const backgrounds = [
    Color(0xFFE2EEE6),
    Color(0xFFECE8DD),
    Color(0xFFDFEAF0),
    Color(0xFFEDE1E6),
    Color(0xFFE3E0F2),
    Color(0xFFEDF1D9),
  ];
  static const skins = [
    Color(0xFFE6B58D),
    Color(0xFFB87850),
    Color(0xFF835439),
    Color(0xFFF2C8A2),
  ];
  static const shirts = [
    Color(0xFF24262B),
    Color(0xFF425A7A),
    Color(0xFF936952),
    Color(0xFF705D83),
    Color(0xFF927836),
    Color(0xFF476E6A),
  ];
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final paint = Paint()..isAntiAlias = true;
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      paint..color = backgrounds[index % 6],
    );
    final skin = skins[(index ~/ 6) % skins.length];
    final shirt = shirts[(index + index ~/ 6) % shirts.length];
    final style = index % 4;
    final hair = [
      const Color(0xFF282724),
      const Color(0xFF624537),
      const Color(0xFF372F36),
    ][index % 3];
    if (style == 1 || style == 3) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(24, 16, 52, 71),
          const Radius.circular(26),
        ),
        paint..color = style == 3 ? shirt : hair,
      );
    }
    canvas.drawOval(const Rect.fromLTWH(11, 72, 78, 70), paint..color = shirt);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(42, 59, 16, 22),
        const Radius.circular(7),
      ),
      paint..color = skin,
    );
    canvas.drawOval(const Rect.fromLTWH(29, 21, 42, 47), paint..color = skin);
    if (style == 0 || style == 2) {
      final hairline = Path()
        ..moveTo(28, 42)
        ..lineTo(28, 29)
        ..quadraticBezierTo(32, 12, 51, 17)
        ..quadraticBezierTo(74, 15, 73, 39)
        ..lineTo(65, 34)
        ..lineTo(63, 25)
        ..quadraticBezierTo(48, 36, 35, 29)
        ..lineTo(35, 40)
        ..close();
      canvas.drawPath(hairline, paint..color = hair);
    }
    if (style == 3) {
      final scarf = Path()
        ..moveTo(27, 34)
        ..quadraticBezierTo(50, 3, 73, 34)
        ..lineTo(69, 17)
        ..quadraticBezierTo(50, 0, 31, 17)
        ..close();
      canvas.drawPath(scarf, paint..color = shirt);
    }
    for (final x in [42.0, 58.0]) {
      canvas.drawCircle(
        Offset(x, 43),
        1.65,
        paint..color = const Color(0xFF302E2C),
      );
    }
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF714334);
    canvas.drawArc(const Rect.fromLTWH(43, 49, 14, 10), .2, 2.7, false, paint);
    if (index >= 12) {
      paint
        ..color = const Color(0xFF343F3D)
        ..strokeWidth = 1.4;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(34, 38, 14, 11),
          const Radius.circular(4),
        ),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(52, 38, 14, 11),
          const Radius.circular(4),
        ),
        paint,
      );
      canvas.drawLine(const Offset(48, 42), const Offset(52, 42), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) =>
      index != oldDelegate.index;
}

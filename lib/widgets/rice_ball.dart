import 'package:material_ui/material_ui.dart';

import '../theme.dart';

class RiceBall extends StatelessWidget {
  const RiceBall({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '饭咔咔小饭团',
    image: true,
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _RiceBallPainter()),
    ),
  );
}

class _RiceBallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 80, size.height / 80);
    final body = Path()
      ..moveTo(32, 13)
      ..quadraticBezierTo(40, 2, 48, 13)
      ..lineTo(72, 54)
      ..quadraticBezierTo(80, 70, 62, 72)
      ..lineTo(18, 72)
      ..quadraticBezierTo(0, 70, 8, 54)
      ..close();
    canvas.drawPath(body, Paint()..color = Colors.white);
    canvas.drawPath(
      body,
      Paint()
        ..color = const Color(0xFFE1D8C9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(29, 55, 22, 18),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF567362),
    );
    final facePaint = Paint()..color = ink;
    canvas.drawCircle(const Offset(29, 39), 2.2, facePaint);
    canvas.drawCircle(const Offset(51, 39), 2.2, facePaint);
    canvas.drawOval(const Rect.fromLTWH(18, 44, 11, 6), Paint()..color = peach);
    canvas.drawOval(const Rect.fromLTWH(51, 44, 11, 6), Paint()..color = peach);
    canvas.drawArc(
      const Rect.fromLTWH(35, 39, 10, 9),
      0.2,
      2.7,
      false,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(_RiceBallPainter oldDelegate) => false;
}

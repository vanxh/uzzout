import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uzzout/app/controllers/rewards_controller.dart';

class SpinWheel extends StatelessWidget {
  final List<RewardItem> items;
  final double rotationAngle;
  final double size;

  const SpinWheel({
    super.key,
    required this.items,
    required this.rotationAngle,
    this.size = 320,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: rotationAngle,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CustomPaint(
              painter: WheelPainter(items),
              size: Size(size, size),
            ),
          ),
        ),

        Container(
          width: size + 12,
          height: size + 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.8), width: 5),
          ),
        ),

        Container(
          width: size * 0.20,
          height: size * 0.20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Center(
            child: Container(
              width: size * 0.15,
              height: size * 0.15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.pink.shade300, Colors.pink.shade600],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.diamond,
                  color: Colors.white,
                  size: size * 0.08,
                ),
              ),
            ),
          ),
        ),

        Positioned(
          top: -2,
          child: Container(
            width: size * 0.1,
            height: size * 0.1,
            decoration: BoxDecoration(
              color: Colors.pink.shade600,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(size * 0.05),
                topRight: Radius.circular(size * 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: size * 0.03,
                height: size * 0.06,
                margin: EdgeInsets.only(bottom: size * 0.02),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<RewardItem> items;

  WheelPainter(this.items);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final segmentAngle = 2 * pi / items.length;

    final sheenPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
              Colors.black.withOpacity(0.05),
            ],
            stops: const [0.0, 0.6, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: radius));

    for (int i = 0; i < items.length; i++) {
      final startAngle = i * segmentAngle;
      final endAngle = (i + 1) * segmentAngle;

      final path =
          Path()
            ..moveTo(center.dx, center.dy)
            ..arcTo(
              Rect.fromCircle(center: center, radius: radius),
              startAngle,
              segmentAngle,
              false,
            )
            ..close();

      final darkColor = items[i].color.withOpacity(0.8);
      final brightColor =
          HSLColor.fromColor(
            items[i].color,
          ).withLightness(0.7).withSaturation(0.9).toColor();

      final segmentGradient = RadialGradient(
        center: const Alignment(0.0, 0.0),
        radius: 1.0,
        colors: [brightColor, darkColor],
        stops: const [0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

      final paint =
          Paint()
            ..shader = segmentGradient
            ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);

      final borderPaint =
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5;

      canvas.drawPath(path, borderPaint);

      canvas.drawPath(path, sheenPaint);

      _drawLabel(canvas, center, radius, (startAngle + endAngle) / 2, items[i]);
    }
  }

  void _drawLabel(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    RewardItem item,
  ) {
    final midRadius = radius * 0.6;
    final labelCenter = Offset(
      center.dx + midRadius * cos(angle),
      center.dy + midRadius * sin(angle),
    );

    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(item.icon.codePoint),
        style: TextStyle(
          fontFamily: item.icon.fontFamily,
          package: item.icon.fontPackage,
          fontSize: 52,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.7),
              blurRadius: 6,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    iconPainter.layout();

    final iconPosition = Offset(
      labelCenter.dx - iconPainter.width / 2,
      labelCenter.dy - iconPainter.height / 2,
    );

    iconPainter.paint(canvas, iconPosition);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

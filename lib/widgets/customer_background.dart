import 'package:flutter/material.dart';

class CustomerBackground extends StatefulWidget {
  final Widget child;
  const CustomerBackground({super.key, required this.child});

  @override
  State<CustomerBackground> createState() => _CustomerBackgroundState();
}

class _CustomerBackgroundState extends State<CustomerBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated background
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: BackgroundPainter(
                  animation: _controller.value,
                ),
              );
            },
          ),
        ),
        // Content
        widget.child,
      ],
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final double animation;

  BackgroundPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E3D59).withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Draw furniture-themed patterns
    drawFurniturePatterns(canvas, size, paint, animation);
  }

  void drawFurniturePatterns(
      Canvas canvas, Size size, Paint paint, double progress) {
    final patterns = [
      drawChair,
      drawTable,
      drawSofa,
      drawLamp,
    ];

    for (var i = 0; i < 10; i++) {
      final x = (size.width * i / 10) + (progress * 50);
      final y = (size.height * i / 10) + (progress * 50);

      patterns[i % patterns.length](canvas, Offset(x, y), paint, 30);
    }
  }

  void drawChair(Canvas canvas, Offset center, Paint paint, double size) {
    final path = Path()
      ..moveTo(center.dx - size / 2, center.dy + size / 2)
      ..lineTo(center.dx + size / 2, center.dy + size / 2)
      ..lineTo(center.dx + size / 3, center.dy - size / 2)
      ..lineTo(center.dx - size / 3, center.dy - size / 2)
      ..close();
    canvas.drawPath(path, paint);
  }

  void drawTable(Canvas canvas, Offset center, Paint paint, double size) {
    canvas.drawRect(
      Rect.fromCenter(center: center, width: size, height: size / 2),
      paint,
    );
  }

  void drawSofa(Canvas canvas, Offset center, Paint paint, double size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: size, height: size / 2),
        const Radius.circular(10),
      ));
    canvas.drawPath(path, paint);
  }

  void drawLamp(Canvas canvas, Offset center, Paint paint, double size) {
    canvas.drawCircle(center, size / 4, paint);
    final path = Path()
      ..moveTo(center.dx, center.dy - size / 2)
      ..lineTo(center.dx + size / 4, center.dy)
      ..lineTo(center.dx - size / 4, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

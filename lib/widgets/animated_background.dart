import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Color> gradientColors;
  final List<Alignment> alignments = [
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.bottomLeft,
    Alignment.bottomRight,
  ];

  @override
  void initState() {
    super.initState();
    gradientColors = [
      const Color(0xFF1E3D59),
      const Color(0xFF2E5077),
      const Color(0xFF3A6495),
      const Color(0xFF457AB3),
    ];
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: alignments[0],
              end: alignments[2],
              colors: [
                gradientColors[0],
                gradientColors[1],
                gradientColors[2],
                gradientColors[3],
              ],
              stops: [
                0.0 + _controller.value * 0.25,
                0.25 + _controller.value * 0.25,
                0.5 + _controller.value * 0.25,
                0.75 + _controller.value * 0.25,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Animated patterns
              Positioned.fill(
                child: CustomPaint(
                  painter: PatternPainter(
                    progress: _controller.value,
                  ),
                ),
              ),
              // Content
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

class PatternPainter extends CustomPainter {
  final double progress;

  PatternPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    const numberOfShapes = 20;
    final shapeSize = size.width / 10;

    for (var i = 0; i < numberOfShapes; i++) {
      final x = (size.width * i / numberOfShapes) + (progress * shapeSize);
      final y = (size.height * i / numberOfShapes) + (progress * shapeSize);

      // Draw different shapes
      if (i % 3 == 0) {
        // Draw circle
        canvas.drawCircle(
          Offset(x, y),
          shapeSize * 0.5,
          paint,
        );
      } else if (i % 3 == 1) {
        // Draw square
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, y),
            width: shapeSize,
            height: shapeSize,
          ),
          paint,
        );
      } else {
        // Draw diamond
        final path = Path()
          ..moveTo(x, y - shapeSize / 2)
          ..lineTo(x + shapeSize / 2, y)
          ..lineTo(x, y + shapeSize / 2)
          ..lineTo(x - shapeSize / 2, y)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(PatternPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

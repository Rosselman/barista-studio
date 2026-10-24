import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class WhiskVisualizer extends StatefulWidget {
  final int rpm;
  final int targetTemp;
  final bool isRunning;
  final double height;

  const WhiskVisualizer({
    super.key,
    required this.rpm,
    required this.targetTemp,
    this.isRunning = true,
    this.height = 180,
  });

  @override
  State<WhiskVisualizer> createState() => _WhiskVisualizerState();
}

class _WhiskVisualizerState extends State<WhiskVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_BubbleParticle> _particles = [];
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.isRunning && widget.rpm > 0) {
      _controller.repeat();
    }

    for (int i = 0; i < 35; i++) {
      _particles.add(_BubbleParticle(
        radius: 10 + _rnd.nextDouble() * 55,
        angle: _rnd.nextDouble() * 2 * pi,
        speed: 0.02 + _rnd.nextDouble() * 0.05,
        size: 1.5 + _rnd.nextDouble() * 2.5,
      ));
    }
  }

  @override
  void didUpdateWidget(WhiskVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldAnimate = widget.isRunning && widget.rpm > 0;
    if (shouldAnimate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldAnimate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCold = widget.targetTemp == 0;
    final glowColor = isCold
        ? AppTheme.cyanCold
        : AppTheme.amberHeat.withOpacity((widget.targetTemp / 70.0).clamp(0.2, 1.0));

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceInput,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background thermal glow
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.85,
                colors: [
                  glowColor.withOpacity(0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Animated Carafe & Whisk Painter
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: Size(double.infinity, widget.height),
                painter: _CarafePainter(
                  rotation: _controller.value * 2 * pi * (widget.rpm / 600.0),
                  targetTemp: widget.targetTemp,
                  rpm: widget.rpm,
                  particles: _particles,
                ),
              );
            },
          ),

          // Top Info Badges
          Positioned(
            top: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Text(
                '${widget.rpm} RPM',
                style: const TextStyle(
                  color: AppTheme.goldLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCold ? AppTheme.cyanCold : AppTheme.amberHeat,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCold ? Icons.ac_unit : Icons.local_fire_department,
                    size: 12,
                    color: isCold ? AppTheme.cyanCold : AppTheme.amberHeat,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isCold ? '0°C (Cold Foam)' : '${widget.targetTemp}°C',
                    style: TextStyle(
                      color: isCold ? AppTheme.cyanCold : AppTheme.amberHeat,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
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

class _BubbleParticle {
  double radius;
  double angle;
  double speed;
  double size;

  _BubbleParticle({
    required this.radius,
    required this.angle,
    required this.speed,
    required this.size,
  });
}

class _CarafePainter extends CustomPainter {
  final double rotation;
  final int targetTemp;
  final int rpm;
  final List<_BubbleParticle> particles;

  _CarafePainter({
    required this.rotation,
    required this.targetTemp,
    required this.rpm,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final isCold = targetTemp == 0;
    final themeColor = isCold
        ? AppTheme.cyanCold
        : AppTheme.amberHeat.withOpacity((targetTemp / 70.0).clamp(0.3, 1.0));

    // 1. Draw outer carafe thermal ring
    final ringPaint = Paint()
      ..color = themeColor.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, 65, ringPaint);

    final innerRingPaint = Paint()
      ..color = themeColor.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, 60, innerRingPaint);

    // 2. Draw swirling milk vortex particles
    final particlePaint = Paint()
      ..color = AppTheme.crema.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    for (final p in particles) {
      p.angle += p.speed * (rpm / 1500.0);
      final px = center.dx + cos(p.angle) * p.radius;
      final py = center.dy + sin(p.angle) * p.radius;
      canvas.drawCircle(Offset(px, py), p.size, particlePaint);
    }

    // 3. Draw Barista Spiral Whisk
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final whiskPaint = Paint()
      ..color = AppTheme.goldLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    // Center hub
    final hubPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 8, hubPaint);

    // 4 Spring Whisk Arms
    for (int i = 0; i < 4; i++) {
      final angle = (i * pi) / 2;
      canvas.save();
      canvas.rotate(angle);

      final path = Path();
      path.moveTo(8, 0);
      path.quadraticBezierTo(22, 12, 38, 0);
      path.quadraticBezierTo(48, -12, 54, 0);
      canvas.drawPath(path, whiskPaint);

      canvas.drawCircle(const Offset(54, 0), 2.5, hubPaint);
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CarafePainter oldDelegate) => true;
}

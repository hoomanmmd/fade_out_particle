import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../fade_out_particle.dart';

const _inParticleMaxRadius = 2.0;
const _inParticleMinRadius = 1.0;
const _inSpaceBetweenParticles = 2;

/// Fade-in particle effect — particles converge into the widget.
///
/// The visual reverse of [FadeOutParticle]: colored dots start scattered
/// and fly together to form the widget shape.
///
/// ```dart
/// FadeInParticle(
///   appear: true,
///   color: Colors.amber,
///   direction: ParticleDirection.bottomToTop,
///   child: MyWidget(),
/// )
/// ```
@immutable
class FadeInParticle extends StatefulWidget {
  /// The widget to materialize.
  final Widget child;

  /// Whether to start the materialize animation.
  final bool appear;

  /// The color of converging particles.
  final Color color;

  /// Duration of animation.
  final Duration duration;

  /// Curve of animation.
  final Curve curve;

  /// Direction particles converge FROM.
  /// e.g. [ParticleDirection.bottomToTop] = particles rise from below.
  final ParticleDirection direction;

  /// Called when the animation completes.
  final VoidCallback? onAnimationEnd;

  const FadeInParticle({
    required this.appear,
    required this.child,
    this.color = const Color(0xFFFFFFFF),
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOut,
    this.direction = ParticleDirection.bottomToTop,
    this.onAnimationEnd,
    super.key,
  });

  @override
  State<FadeInParticle> createState() => _FadeInParticleState();
}

class _FadeInParticleState extends State<FadeInParticle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationEnd?.call();
      }
    });
  late final CurvedAnimation _animation = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
  );

  List<_InParticle>? _particles;
  final _sizeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.appear) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAppear());
    }
  }

  @override
  void didUpdateWidget(FadeInParticle oldWidget) {
    if (oldWidget.duration != widget.duration ||
        oldWidget.curve != widget.curve) {
      _controller.duration = widget.duration;
      _animation.curve = widget.curve;
    }
    if (oldWidget.appear != widget.appear && widget.appear) {
      _startAppear();
    }
    super.didUpdateWidget(oldWidget);
  }

  void _startAppear() {
    final ctx = _sizeKey.currentContext;
    if (ctx == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAppear());
      return;
    }
    final box = ctx.findRenderObject() as RenderBox;
    final w = box.size.width.toInt();
    final h = box.size.height.toInt();
    if (w < 2 || h < 2) return;

    final rng = math.Random();
    final particles = <_InParticle>[];
    final vertCount = math.max(1, h ~/ _inSpaceBetweenParticles);
    final horzCount = math.max(1, w ~/ _inSpaceBetweenParticles);

    for (int i = 0; i < vertCount; i++) {
      for (int j = 0; j < horzCount; j++) {
        final tx = (j * _inSpaceBetweenParticles + 1).toDouble();
        final ty = (i * _inSpaceBetweenParticles + 1).toDouble();
        particles.add(_InParticle(
          targetX: tx,
          targetY: ty,
          radius: _inParticleMinRadius +
              rng.nextDouble() * (_inParticleMaxRadius - _inParticleMinRadius),
          // Scatter offset based on direction
          scatterX: _scatterX(rng, w.toDouble()),
          scatterY: _scatterY(rng, h.toDouble()),
          delay: rng.nextDouble() * 0.3,
          pathType: rng.nextInt(6),
        ));
      }
    }

    if (mounted) {
      setState(() {
        _particles = particles;
        _controller.forward(from: 0);
      });
    }
  }

  double _scatterX(math.Random rng, double w) {
    switch (widget.direction) {
      case ParticleDirection.leftToRight:
        return -(20 + rng.nextDouble() * 30);
      case ParticleDirection.rightToLeft:
        return 20 + rng.nextDouble() * 30;
      case ParticleDirection.bottomToTop:
      case ParticleDirection.topToBottom:
        return (rng.nextDouble() - 0.5) * 20;
    }
  }

  double _scatterY(math.Random rng, double h) {
    switch (widget.direction) {
      case ParticleDirection.bottomToTop:
        return 20 + rng.nextDouble() * 30;
      case ParticleDirection.topToBottom:
        return -(20 + rng.nextDouble() * 30);
      case ParticleDirection.leftToRight:
      case ParticleDirection.rightToLeft:
        return (rng.nextDouble() - 0.5) * 20;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) {
        final progress = _animation.value;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // The actual widget — fades in as particles converge
            Opacity(
              opacity: _particles != null ? progress.clamp(0.0, 1.0) : 1.0,
              child: child,
            ),
            // Converging particles overlay
            if (_particles != null && progress < 1.0)
              Positioned.fill(
                // Allow particles to render outside bounds
                top: -40,
                bottom: -40,
                left: -20,
                right: -20,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _InParticlePainter(
                      progress: progress,
                      color: widget.color,
                      particles: _particles!,
                      offsetX: 20,
                      offsetY: 40,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: KeyedSubtree(
        key: _sizeKey,
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _InParticle {
  final double targetX;
  final double targetY;
  final double radius;
  final double scatterX;
  final double scatterY;
  final double delay;
  final int pathType;

  const _InParticle({
    required this.targetX,
    required this.targetY,
    required this.radius,
    required this.scatterX,
    required this.scatterY,
    required this.delay,
    required this.pathType,
  });
}

class _InParticlePainter extends CustomPainter {
  final double progress;
  final Color color;
  final List<_InParticle> particles;
  final double offsetX;
  final double offsetY;

  _InParticlePainter({
    required this.progress,
    required this.color,
    required this.particles,
    required this.offsetX,
    required this.offsetY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final life = ((progress - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);
      if (life <= 0) continue;

      // Ease-in: particles accelerate toward target
      final eased = life * life;

      // Particle position: from scattered → target
      final dx = offsetX + p.targetX + p.scatterX * (1.0 - eased);
      final dy = offsetY + p.targetY + p.scatterY * (1.0 - eased);

      // Opacity: starts visible, stays visible, widget takes over
      final alpha = life < 0.7 ? 0.7 : (1.0 - (life - 0.7) / 0.3) * 0.7;
      paint.color = color.withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(dx, dy),
        p.radius * (0.6 + eased * 0.4),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_InParticlePainter old) => old.progress != progress;
}

part of 'fade_out_particle.dart';

class _RenderBox extends RenderProxyBox {
  double _progress;
  List<Particle?>? _particles;

  _RenderBox(this._progress, this._particles);

  @override
  bool get alwaysNeedsCompositing => child != null;

  set progress(double newValue) {
    if (newValue == _progress) {
      return;
    }
    _progress = newValue;
    markNeedsPaint();
  }

  set particles(List<Particle?>? newValue) {
    if (newValue == _particles) {
      return;
    }
    _particles = newValue;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null || _progress == 0) {
      super.paint(context, offset);
      return;
    }
    final double width = child!.size.width;
    final double height = child!.size.height;
    final canvas = context.canvas;

    final bounds = Rect.fromLTRB(0, 0, width + 1, height + 1);
    final paint = Paint();
    canvas.saveLayer(bounds, paint);

    super.paint(context, offset);

    paint.blendMode = BlendMode.clear;
    final limit =
        width - width * (1 + width.limitedAnimationWidth / width) * _progress;
    canvas.drawRect(Rect.fromLTRB(limit, -1, width + 1, height + 1), paint);

    canvas.restore();

    paint.blendMode = BlendMode.srcOver;

    if (_particles != null) {
      _drawParticles(_particles!, limit, width, paint, canvas);
    }
  }

  void _drawParticles(List<Particle?> particles, double limit, double width,
      Paint paint, Canvas canvas) {
    for (final particle in particles) {
      if (particle!.cx < limit - 1) {
        continue;
      }
      final particleProgress = (particle.cx - limit).particleProgress(width);
      if (particleProgress == 1) {
        continue;
      }
      paint.color = particle.rgbaColor.withOpacity(1 - particleProgress);
      if (paint.color.opacity == 0) {
        continue;
      }
      final cx =
          (1 + _particleMaxRadius - particle.radius) / _particleMaxRadius;
      final cy = (particle.cx + particle.cy * 3) % 2 - 1;
      final dx = particle.cx + particleProgress * 10 * cx;
      final dy = particle.cy +
          particleProgress.interpolateYAxis(particle.pathType) * 6 * cy;
      canvas.drawCircle(
        Offset(dx, dy),
        particle.radius,
        paint,
      );
    }
  }
}

part of 'fade_out_particle.dart';

class _RenderBox extends RenderProxyBox {
  double _progress;
  LinkedList<Particle>? _particles;

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

  set particles(LinkedList<Particle>? newValue) {
    if (newValue == _particles) {
      return;
    }
    _particles = newValue;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null || _progress == 0) {
      super.paint(context, offset);
      return;
    }
    final double width = child.size.width;
    final double height = child.size.height;
    final canvas = context.canvas;

    final bounds = Rect.fromLTRB(0, 0, width + 1, height + 1);
    final paint = Paint();

    canvas.saveLayer(bounds, paint);

    super.paint(context, offset);

    paint.blendMode = BlendMode.dstOut;
    final limit =
        width - width * (1 + width.limitedAnimationWidth / width) * _progress;
    final fadingLimit = math.min(width / 3, 10);
    final clipRect = Rect.fromLTRB(limit, -1.0, width + 1, height + 1);

    paint.shader = ui.Gradient.linear(
      Offset(limit, height / 2),
      Offset(limit + fadingLimit, height / 2),
      [
        const Color(0),
        const Color(-1),
      ],
    );

    canvas.drawRect(clipRect, paint);

    canvas.restore();

    paint.shader = null;
    paint.blendMode = BlendMode.srcOver;

    if (_particles != null) {
      _drawParticles(_particles!, limit, width, paint, canvas);
    }
  }

  void _drawParticles(LinkedList<Particle> particles, double limit,
      double width, Paint paint, Canvas canvas) {
    for (final particle in particles) {
      if (particle.cx < limit - 1) {
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

part of 'fade_out_particle.dart';

class _RenderBox extends RenderProxyBox {
  double _progress;
  LinkedList<Particle>? _particles;
  ParticleDirection _direction;

  _RenderBox(this._progress, this._particles, this._direction);

  @override
  bool get alwaysNeedsCompositing => child != null;

  set progress(double newValue) {
    if (newValue == _progress) return;
    _progress = newValue;
    markNeedsPaint();
  }

  set particles(LinkedList<Particle>? newValue) {
    if (newValue == _particles) return;
    _particles = newValue;
    markNeedsPaint();
  }

  set direction(ParticleDirection newValue) {
    if (newValue == _direction) return;
    _direction = newValue;
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

    switch (_direction) {
      case ParticleDirection.rightToLeft:
        _paintHorizontal(canvas, paint, width, height, reverse: false);
        break;
      case ParticleDirection.leftToRight:
        _paintHorizontal(canvas, paint, width, height, reverse: true);
        break;
      case ParticleDirection.bottomToTop:
        _paintVertical(canvas, paint, width, height, reverse: false);
        break;
      case ParticleDirection.topToBottom:
        _paintVertical(canvas, paint, width, height, reverse: true);
        break;
    }

    canvas.restore();

    paint.shader = null;
    paint.blendMode = BlendMode.srcOver;

    if (_particles != null) {
      switch (_direction) {
        case ParticleDirection.rightToLeft:
        case ParticleDirection.leftToRight:
          _drawParticlesH(_particles!, width, height, paint, canvas);
          break;
        case ParticleDirection.bottomToTop:
        case ParticleDirection.topToBottom:
          _drawParticlesV(_particles!, width, height, paint, canvas);
          break;
      }
    }
  }

  // ── Horizontal wipe (original right-to-left + mirrored left-to-right) ───

  void _paintHorizontal(Canvas canvas, Paint paint, double width, double height,
      {required bool reverse}) {
    final animW = width.limitedAnimationWidth;
    final limit = reverse
        ? width * (1 + animW / width) * _progress
        : width - width * (1 + animW / width) * _progress;
    final fadingLimit = math.min(width / 3, 10);

    final Rect clipRect;
    final Offset gradStart;
    final Offset gradEnd;

    if (reverse) {
      clipRect = Rect.fromLTRB(-1.0, -1.0, limit, height + 1);
      gradStart = Offset(limit, height / 2);
      gradEnd = Offset(limit - fadingLimit, height / 2);
    } else {
      clipRect = Rect.fromLTRB(limit, -1.0, width + 1, height + 1);
      gradStart = Offset(limit, height / 2);
      gradEnd = Offset(limit + fadingLimit, height / 2);
    }

    paint.shader = ui.Gradient.linear(
      gradStart,
      gradEnd,
      [const Color(0x00000000), const Color(-1)],
    );
    canvas.drawRect(clipRect, paint);
  }

  // ── Vertical wipe (bottom-to-top + mirrored top-to-bottom) ──────────────

  void _paintVertical(Canvas canvas, Paint paint, double width, double height,
      {required bool reverse}) {
    final animH = height.limitedAnimationWidth;
    final limit = reverse
        ? height * (1 + animH / height) * _progress
        : height - height * (1 + animH / height) * _progress;
    final fadingLimit = math.min(height / 3, 10);

    final Rect clipRect;
    final Offset gradStart;
    final Offset gradEnd;

    if (reverse) {
      // top-to-bottom: clip from top, gradient fades downward
      clipRect = Rect.fromLTRB(-1.0, -1.0, width + 1, limit);
      gradStart = Offset(width / 2, limit);
      gradEnd = Offset(width / 2, limit - fadingLimit);
    } else {
      // bottom-to-top: clip from bottom, gradient fades upward
      clipRect = Rect.fromLTRB(-1.0, limit, width + 1, height + 1);
      gradStart = Offset(width / 2, limit);
      gradEnd = Offset(width / 2, limit + fadingLimit);
    }

    paint.shader = ui.Gradient.linear(
      gradStart,
      gradEnd,
      [const Color(0x00000000), const Color(-1)],
    );
    canvas.drawRect(clipRect, paint);
  }

  // ── Draw particles for horizontal directions ────────────────────────────

  void _drawParticlesH(LinkedList<Particle> particles, double width,
      double height, Paint paint, Canvas canvas) {
    final isReverse = _direction == ParticleDirection.leftToRight;
    final animW = width.limitedAnimationWidth;
    final limit = isReverse
        ? width * (1 + animW / width) * _progress
        : width - width * (1 + animW / width) * _progress;

    for (final particle in particles) {
      final double px = particle.cx.toDouble();
      if (!isReverse && px < limit - 1) continue;
      if (isReverse && px > limit + 1) continue;

      final dist = isReverse ? (limit - px) : (px - limit);
      final particleProgress = dist.particleProgress(width);
      if (particleProgress >= 1) continue;

      paint.color = particle.rgbaColor.withOpacity(1 - particleProgress);
      if (paint.color.a == 0) continue;

      final cx =
          (1 + _particleMaxRadius - particle.radius) / _particleMaxRadius;
      final cy = (particle.cx + particle.cy * 3) % 2 - 1;
      final dxSign = isReverse ? -1.0 : 1.0;
      final dx = px + dxSign * particleProgress * 10 * cx;
      final dy = particle.cy +
          particleProgress.interpolateYAxis(particle.pathType) * 8 * cy;
      canvas.drawCircle(Offset(dx, dy), particle.radius, paint);
    }
  }

  // ── Draw particles for vertical directions ──────────────────────────────

  void _drawParticlesV(LinkedList<Particle> particles, double width,
      double height, Paint paint, Canvas canvas) {
    final isReverse = _direction == ParticleDirection.topToBottom;
    final animH = height.limitedAnimationWidth;
    final limit = isReverse
        ? height * (1 + animH / height) * _progress
        : height - height * (1 + animH / height) * _progress;

    for (final particle in particles) {
      final double py = particle.cy.toDouble();
      if (!isReverse && py < limit - 1) continue;
      if (isReverse && py > limit + 1) continue;

      final dist = isReverse ? (limit - py) : (py - limit);
      final particleProgress = dist.particleProgress(height);
      if (particleProgress >= 1) continue;

      paint.color = particle.rgbaColor.withOpacity(1 - particleProgress);
      if (paint.color.a == 0) continue;

      final cy =
          (1 + _particleMaxRadius - particle.radius) / _particleMaxRadius;
      final cx = (particle.cx + particle.cy * 3) % 2 - 1;
      final dySign = isReverse ? 1.0 : -1.0;
      final dx = particle.cx +
          particleProgress.interpolateYAxis(particle.pathType) * 8 * cx;
      final dy = py + dySign * particleProgress * 10 * cy;
      canvas.drawCircle(Offset(dx, dy), particle.radius, paint);
    }
  }
}

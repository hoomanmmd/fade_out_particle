part of 'fade_out_particle.dart';

class _RenderBox extends RenderProxyBox {
  double _progress;
  Iterable<Particle>? _particles;
  ParticleDirection _direction;

  _RenderBox(this._progress, this._particles, this._direction);

  @override
  bool get alwaysNeedsCompositing => child != null;

  set progress(double newValue) {
    if (newValue == _progress) return;
    _progress = newValue;
    markNeedsPaint();
  }

  set particles(Iterable<Particle>? newValue) {
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
      layer = null;
      super.paint(context, offset);
      return;
    }
    final double width = child.size.width;
    final double height = child.size.height;

    // The wipe is a dstOut mask layer around the child. It must not be drawn
    // on a canvas held across `super.paint`: a child that pushes its own layer
    // (an Opacity, a ColorFiltered, a RepaintBoundary) ends that canvas's
    // recording and any later draw on it throws "native peer collected".
    final Shader shader;
    switch (_direction) {
      case ParticleDirection.rightToLeft:
        shader = _horizontalMask(width, height, reverse: false);
        break;
      case ParticleDirection.leftToRight:
        shader = _horizontalMask(width, height, reverse: true);
        break;
      case ParticleDirection.bottomToTop:
        shader = _verticalMask(width, height, reverse: false);
        break;
      case ParticleDirection.topToBottom:
        shader = _verticalMask(width, height, reverse: true);
        break;
    }
    final mask = (layer as ShaderMaskLayer?) ?? ShaderMaskLayer();
    mask
      ..shader = shader
      ..maskRect = (offset & child.size).inflate(_maskOverflowMargin)
      ..blendMode = BlendMode.dstOut;
    layer = mask;
    context.pushLayer(mask, super.paint, offset);

    if (_particles == null) return;
    // Read after the child painted: pushing the mask layer replaced it.
    final canvas = context.canvas;
    final paint = Paint();
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    switch (_direction) {
      case ParticleDirection.rightToLeft:
        _drawParticlesHorizontal(width, height, paint, canvas);
        break;
      case ParticleDirection.leftToRight:
        _drawParticlesHorizontalReversed(width, height, paint, canvas);
        break;
      case ParticleDirection.bottomToTop:
        _drawParticlesVertical(width, height, paint, canvas);
        break;
      case ParticleDirection.topToBottom:
        _drawParticlesVerticalReversed(width, height, paint, canvas);
        break;
    }
    canvas.restore();
  }

  // The mask shader's origin is the top left of the mask rect, which sits
  // [_maskOverflowMargin] above and left of the child's box; the gradients
  // below are written in box coordinates and shifted by that margin. Past the
  // gradient the shader clamps: transparent (child kept) on the side the wipe
  // has not reached, opaque (child erased) on the side it has.

  // ── Horizontal wipe (original right-to-left + mirrored left-to-right) ───

  Shader _horizontalMask(double width, double height, {required bool reverse}) {
    final animW = width.limitedAnimationWidth;
    final limit = reverse
        ? width * (1 + animW / width) * _progress
        : width - width * (1 + animW / width) * _progress;
    final fadingLimit = math.min(width / 3, 10);
    final x = limit + _maskOverflowMargin;
    final y = height / 2 + _maskOverflowMargin;
    return ui.Gradient.linear(
      Offset(x, y),
      Offset(reverse ? x - fadingLimit : x + fadingLimit, y),
      [const Color(0x00000000), const Color(-1)],
    );
  }

  // ── Vertical wipe (bottom-to-top + mirrored top-to-bottom) ──────────────

  Shader _verticalMask(double width, double height, {required bool reverse}) {
    final animH = height.limitedAnimationWidth;
    final limit = reverse
        ? height * (1 + animH / height) * _progress
        : height - height * (1 + animH / height) * _progress;
    final fadingLimit = math.min(height / 3, 10);
    final x = width / 2 + _maskOverflowMargin;
    final y = limit + _maskOverflowMargin;
    return ui.Gradient.linear(
      Offset(x, y),
      Offset(x, reverse ? y - fadingLimit : y + fadingLimit),
      [const Color(0x00000000), const Color(-1)],
    );
  }

  // ── Draw particles for horizontal directions ────────────────────────────

  void _drawParticlesHorizontal(
    double width,
    double height,
    Paint paint,
    Canvas canvas,
  ) {
    final animW = width.limitedAnimationWidth;
    final limit = width - width * (1 + animW / width) * _progress;

    for (final particle in _particles!) {
      if (particle.cx < limit - 1) continue;

      final dist = (particle.cx - limit);
      final particleProgress = dist.particleProgress(width);
      if (particleProgress >= 1) continue;

      paint.color = particle.rgbaColor.withOpacity(1 - particleProgress);
      if (paint.color.a == 0) continue;

      final dx = particle.cx + particleProgress * particle.yFactor;
      final dy = particle.cy +
          particleProgress.interpolateYAxis(particle.pathType) *
              particle.xFactor;
      canvas.drawCircle(Offset(dx, dy), particle.radius, paint);
    }
  }

  void _drawParticlesHorizontalReversed(
    double width,
    double height,
    Paint paint,
    Canvas canvas,
  ) {
    final animW = width.limitedAnimationWidth;
    final limit = width * (1 + animW / width) * _progress;

    for (final particle in _particles!) {
      if (particle.cx > limit + 1) continue;

      final dist = limit - particle.cx;
      final particleProgress = dist.particleProgress(width);
      if (particleProgress >= 1) continue;

      paint.color = particle.rgbaColor.withOpacity(1 - particleProgress);
      if (paint.color.a == 0) continue;

      final dx = particle.cx - particleProgress * particle.yFactor;
      final dy = particle.cy +
          particleProgress.interpolateYAxis(particle.pathType) *
              particle.xFactor;
      canvas.drawCircle(Offset(dx, dy), particle.radius, paint);
    }
  }

  // ── Draw particles for vertical directions ──────────────────────────────

  void _drawParticlesVertical(
    double width,
    double height,
    Paint paint,
    Canvas canvas,
  ) {
    final animH = height.limitedAnimationWidth;
    final limit = height - height * (1 + animH / height) * _progress;

    for (final particle in _particles!) {
      if (particle.cy < limit - 1) continue;

      final dist = particle.cy - limit;
      final particleProgress = dist.particleProgress(height);
      if (particleProgress >= 1) continue;

      paint.color = particle.rgbaColor.withOpacity(1 - particleProgress);
      if (paint.color.a == 0) continue;

      final dx = particle.cx +
          particleProgress.interpolateYAxis(particle.pathType) *
              particle.xFactor;
      final dy = particle.cy - particleProgress * particle.yFactor;
      canvas.drawCircle(Offset(dx, dy), particle.radius, paint);
    }
  }

  void _drawParticlesVerticalReversed(
    double width,
    double height,
    Paint paint,
    Canvas canvas,
  ) {
    final animH = height.limitedAnimationWidth;
    final limit = height * (1 + animH / height) * _progress;
    for (final particle in _particles!) {
      final double py = particle.cy.toDouble();
      if (py > limit + 1) continue;

      final dist = limit - py;
      final particleProgress = dist.particleProgress(height);
      if (particleProgress >= 1) continue;

      paint.color = particle.rgbaColor.withOpacity(1 - particleProgress);
      if (paint.color.a == 0) continue;

      final dx = particle.cx +
          particleProgress.interpolateYAxis(particle.pathType) *
              particle.xFactor;
      final dy = py + particleProgress * particle.yFactor;
      canvas.drawCircle(Offset(dx, dy), particle.radius, paint);
    }
  }
}

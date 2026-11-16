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
      case ParticleDirection.leftToRight:
        _drawParticlesH(_particles!, width, height, paint, canvas);
        break;
      case ParticleDirection.bottomToTop:
      case ParticleDirection.topToBottom:
        _drawParticlesV(_particles!, width, height, paint, canvas);
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

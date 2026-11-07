part of 'fade_out_particle.dart';

@immutable
class _RenderObject extends SingleChildRenderObjectWidget {
  final double progress;
  final LinkedList<Particle>? particles;
  final ParticleDirection direction;

  const _RenderObject({
    required this.progress,
    required this.particles,
    required this.direction,
    super.child,
  });

  @override
  _RenderBox createRenderObject(BuildContext context) =>
      _RenderBox(progress, particles, direction);

  @override
  void updateRenderObject(BuildContext context, _RenderBox renderBox) {
    renderBox.progress = progress;
    renderBox.particles = particles;
    renderBox.direction = direction;
  }
}

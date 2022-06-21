part of 'fade_out_particle.dart';

@immutable
class _RenderObject extends SingleChildRenderObjectWidget {
  final double progress;
  final LinkedList<Particle>? particles;

  const _RenderObject({
    required this.progress,
    required this.particles,
    super.child,
  });

  @override
  _RenderBox createRenderObject(BuildContext context) =>
      _RenderBox(progress, particles);

  @override
  void updateRenderObject(BuildContext context, _RenderBox renderBox) {
    renderBox.progress = progress;
    renderBox.particles = particles;
  }
}

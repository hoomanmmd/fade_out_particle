import 'dart:collection';

class Particle extends LinkedListEntry<Particle> {
  Particle({
    required this.cx,
    required this.cy,
    required this.radius,
    required this.rgbaColor,
    required this.pathType,
  });

  final int cx;
  final int cy;
  final double radius;
  final int rgbaColor;
  final int pathType;
}

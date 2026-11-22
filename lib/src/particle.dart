base class Particle {
  Particle({
    required this.cx,
    required this.cy,
    required this.radius,
    required this.rgbaColor,
    required this.pathType,
    required this.xFactor,
    required this.yFactor,
  });

  final int cx;
  final int cy;
  final double radius;
  final int rgbaColor;
  final int pathType;
  final double xFactor;
  final double yFactor;
}

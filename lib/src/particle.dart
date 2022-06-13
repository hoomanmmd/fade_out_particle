import 'package:flutter/widgets.dart';

@immutable
class Particle {
  const Particle({
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

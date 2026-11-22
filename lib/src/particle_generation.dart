import 'dart:isolate';
import 'dart:math' as math;

import 'package:fade_out_particle/src/particle.dart';
import 'package:flutter/foundation.dart';

import 'constants.dart';
import 'extensions.dart';

class ParticleGeneration {
  ParticleGeneration._();

  static Future<Iterable<Particle>> generateParticlesOnIsolate(
    int width,
    int height,
    ByteData bytes,
  ) async {
    if (kIsWeb) {
      return _generateParticles(width, height, bytes);
    }

    final transferable = TransferableTypedData.fromList([
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    ]);

    final message = _ParticleGenerationMessage(
      width: width,
      height: height,
      bytes: transferable,
    );

    return compute(
      _generateParticlesFromMessage,
      message.toMap(),
    );
  }
}

Iterable<Particle> _generateParticlesFromMessage(Map<String, dynamic> arg) {
  final message = _ParticleGenerationMessage.fromMap(arg);
  final ByteData byteData = message.bytes.materialize().asByteData();

  return _generateParticles(message.width, message.height, byteData);
}

Iterable<Particle> _generateParticles(
  int width,
  int height,
  ByteData byteData,
) {
  final verticalCount = math.max(1, height ~/ Constants.spaceBetweenParticles);
  final horizontalCount = math.max(1, width ~/ Constants.spaceBetweenParticles);

  final particles = <Particle>[];
  int horizontalOffset;
  const halfSpace = Constants.spaceBetweenParticles ~/ 2;
  int verticalOffset = halfSpace;
  final random = math.Random();
  for (int i = 0; i < verticalCount; i++) {
    horizontalOffset = halfSpace;
    for (var j = 0; j < horizontalCount; j++) {
      final rgbaColor = byteData.maybeNonTransparentColor(
        horizontalOffset,
        verticalOffset,
        width,
        halfSpace,
      );
      if (!rgbaColor.isTransparent) {
        final radius = _generateRandomRadius(random);
        particles.add(
          Particle(
            cx: horizontalOffset,
            cy: verticalOffset,
            rgbaColor: rgbaColor,
            radius: radius,
            pathType: random.nextInt(6),
            xFactor: ((horizontalOffset + verticalOffset * 3) % 2 - 1) * 8,
            yFactor: 10 * (1 + Constants.particleMaxRadius - radius) /
                Constants.particleMaxRadius
          ),
        );
      }
      horizontalOffset += Constants.spaceBetweenParticles;
    }
    verticalOffset += Constants.spaceBetweenParticles;
  }

  return particles;
}

double _generateRandomRadius(math.Random random) =>
    random.nextDouble() *
        (Constants.particleMaxRadius - Constants.particleMinRadius) +
    Constants.particleMinRadius;

class _ParticleGenerationMessage {
  final int width;
  final int height;
  final TransferableTypedData bytes;

  _ParticleGenerationMessage({
    required this.width,
    required this.height,
    required this.bytes,
  });

  Map<String, dynamic> toMap() => {
        'w': width,
        'h': height,
        'b': bytes,
      };

  factory _ParticleGenerationMessage.fromMap(Map<String, dynamic> map) =>
      _ParticleGenerationMessage(
        width: map['w'],
        height: map['h'],
        bytes: map['b'],
      );
}

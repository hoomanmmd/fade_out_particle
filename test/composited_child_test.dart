import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fade_out_particle/fade_out_particle.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// A child subtree that pushes its own layer ends the paint recording the
// dissolve was started on. These tests run a whole dissolve over such
// children and require that no frame throws while painting.
//
// The particle snapshot (`RenderRepaintBoundary.toImage`) only completes on
// real async, so the wait runs inside `tester.runAsync`; without it the
// progress stays 0 and the wipe is never painted.

enum _ChildKind { opacityBadge, colorFiltered, plain }

const _cardWidth = 300.0;
const _cardHeight = 80.0;
const _padding = 40.0;
const _overflowColor = Color(0xFF00FF00);

Widget _card(_ChildKind kind) {
  const badge = SizedBox(
    width: 40,
    height: 16,
    child: ColoredBox(color: Color(0xFFFFCC00)),
  );
  return SizedBox(
    width: _cardWidth,
    height: _cardHeight,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: kind == _ChildKind.colorFiltered
              ? const ColorFiltered(
                  colorFilter:
                      ColorFilter.mode(Color(0x80FF0000), BlendMode.srcATop),
                  child: ColoredBox(color: Color(0xFF3366CC)),
                )
              : const ColoredBox(color: Color(0xFF3366CC)),
        ),
        // Paints above the box, like a badge sitting half outside a card.
        const Positioned(
          top: -10,
          left: 20,
          child: SizedBox(
            width: 40,
            height: 10,
            child: ColoredBox(color: _overflowColor),
          ),
        ),
        Positioned(
          top: 0,
          right: 12,
          // An `Opacity` above 0 pushes its own OpacityLayer.
          child: kind == _ChildKind.opacityBadge
              ? const Opacity(opacity: 1.0, child: badge)
              : badge,
        ),
      ],
    ),
  );
}

class _Host extends StatefulWidget {
  const _Host({
    super.key,
    required this.kind,
    required this.direction,
    required this.outer,
    required this.onEnd,
  });

  final _ChildKind kind;
  final ParticleDirection direction;
  final GlobalKey outer;
  final VoidCallback onEnd;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool disappear = false;

  void startDissolve() => setState(() => disappear = true);

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: widget.outer,
            child: Container(
              color: const Color(0xFF202020),
              padding: const EdgeInsets.all(_padding),
              child: FadeOutParticle(
                disappear: disappear,
                duration: const Duration(milliseconds: 500),
                direction: widget.direction,
                onAnimationEnd: widget.onEnd,
                child: _card(widget.kind),
              ),
            ),
          ),
        ),
      );
}

Future<Uint8List> _snapshot(WidgetTester tester, GlobalKey outer) async {
  final boundary =
      outer.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  late Uint8List pixels;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    pixels = bytes!.buffer.asUint8List();
    image.dispose();
  });
  return pixels;
}

/// Pixels of the overflow strip (10 px above the box) still showing its colour.
int _overflowPixels(Uint8List rgba) {
  const stride = (_cardWidth + 2 * _padding);
  var count = 0;
  for (var y = (_padding - 10).toInt(); y < _padding.toInt(); y++) {
    for (var x = (_padding + 20).toInt(); x < (_padding + 60).toInt(); x++) {
      final i = (y * stride.toInt() + x) * 4;
      if (rgba[i] < 40 && rgba[i + 1] > 200 && rgba[i + 2] < 40) count++;
    }
  }
  return count;
}

/// Whether the card's body at the edge where [direction] starts its wipe no
/// longer shows the card colour, i.e. the wipe has begun painting.
bool _wipeStarted(Uint8List rgba, ParticleDirection direction) {
  const stride = _cardWidth + 2 * _padding;
  final (double x, double y) = switch (direction) {
    ParticleDirection.bottomToTop => (_padding + 150, _padding + _cardHeight - 2),
    ParticleDirection.topToBottom => (_padding + 150, _padding + 1),
    ParticleDirection.rightToLeft => (_padding + _cardWidth - 2, _padding + 60),
    ParticleDirection.leftToRight => (_padding + 1, _padding + 60),
  };
  final i = (y.toInt() * stride.toInt() + x.toInt()) * 4;
  return (rgba[i] - 0x33).abs() > 8 ||
      (rgba[i + 1] - 0x66).abs() > 8 ||
      (rgba[i + 2] - 0xCC).abs() > 8;
}

/// Runs a dissolve until its `onAnimationEnd` fires (bounded), returning every
/// error thrown while it painted, whether it ended, and per sampled frame the
/// overflow-strip pixel count and whether the wipe had begun.
///
/// The particle snapshot completes on real time only, so every frame also
/// yields to `runAsync`; a slow host takes more frames, not a vacuous pass.
Future<
    ({
      List<Object> errors,
      bool ended,
      List<int> overflow,
      List<bool> started,
    })> _dissolve(
  WidgetTester tester, {
  required _ChildKind kind,
  required ParticleDirection direction,
  bool sample = false,
}) async {
  final errors = <Object>[];
  final overflow = <int>[];
  final started = <bool>[];
  var ended = false;
  final previous = FlutterError.onError;
  FlutterError.onError = (details) => errors.add(details.exception);
  try {
    final key = GlobalKey<_HostState>();
    final outer = GlobalKey();
    await tester.pumpWidget(_Host(
      key: key,
      kind: kind,
      direction: direction,
      outer: outer,
      onEnd: () => ended = true,
    ));
    Future<void> takeSample() async {
      final pixels = await _snapshot(tester, outer);
      overflow.add(_overflowPixels(pixels));
      started.add(_wipeStarted(pixels, direction));
    }

    if (sample) await takeSample();
    key.currentState!.startDissolve();
    await tester.pump();
    for (var frame = 0; frame < 100 && !ended; frame++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      final pending = tester.takeException();
      if (pending != null) errors.add(pending);
      if (sample) await takeSample();
    }
  } finally {
    FlutterError.onError = previous;
  }
  return (errors: errors, ended: ended, overflow: overflow, started: started);
}

void main() {
  for (final direction in ParticleDirection.values) {
    for (final kind in _ChildKind.values) {
      testWidgets('dissolve $direction over ${kind.name} child paints no error',
          (tester) async {
        final result =
            await _dissolve(tester, kind: kind, direction: direction);
        expect(result.ended, isTrue,
            reason: 'the dissolve never reached its end, so no wipe frame '
                'was proven to paint');
        expect(
          result.errors,
          isEmpty,
          reason: 'errors thrown while painting the dissolve: '
              '${result.errors.length}, first: '
              '${result.errors.isEmpty ? '-' : result.errors.first}',
        );
      });
    }
  }

  // Content the child paints outside its box goes with the wipe (A-2831
  // ruling (a), swept, not clipped): fully visible before the dissolve, gone
  // once it has finished.
  for (final direction in ParticleDirection.values) {
    testWidgets('dissolve $direction sweeps the overflow above the box',
        (tester) async {
      final result = await _dissolve(
        tester,
        kind: _ChildKind.plain,
        direction: direction,
        sample: true,
      );
      final frames = 'overflow per frame: ${result.overflow}, '
          'wipe begun: ${result.started}';
      expect(result.errors, isEmpty);
      expect(result.ended, isTrue, reason: frames);
      expect(result.overflow.first, 400, reason: frames);
      expect(result.overflow.last, 0, reason: frames);
      // Bottom-to-top and right-to-left reach the strip late: while the wipe
      // is already eating the card, the strip is still on screen. A clip to
      // the box (the look before A-2831) hides it from the first wipe frame.
      if (direction == ParticleDirection.bottomToTop ||
          direction == ParticleDirection.rightToLeft) {
        var stillShown = false;
        for (var i = 0; i < result.overflow.length; i++) {
          if (result.started[i] && result.overflow[i] > 0) stillShown = true;
        }
        expect(stillShown, isTrue,
            reason: 'no frame shows the overflow once the wipe has begun '
                '(clipped, not swept): $frames');
      }
    });
  }
}

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fade_out_particle/src/particle_generation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'extensions.dart';
import 'particle.dart';

part 'render_box.dart';
part 'render_object.dart';

/// How far past the child's box the dissolve mask reaches. What the child
/// paints outside its box (a badge half over the edge, a shadow) goes with the
/// wipe only where the mask and the wipe both reach it:
/// - on the two sides parallel to the wipe's travel, up to this margin, erased
///   as the wipe line passes;
/// - on the side the wipe starts from, up to this margin, erased from the
///   first frame;
/// - on the side the wipe ends at, only up to the wipe's overshoot past that
///   edge, min(extent, 128) less the fade (up to 10 px), because the wipe
///   stops there at progress 1.
/// Anything further out is left as painted until the widget is removed.
const _maskOverflowMargin = 1024.0;

/// Direction in which particles dissolve away from the widget.
enum ParticleDirection {
  /// Original behavior — wipe goes right to left.
  rightToLeft,

  /// Wipe goes left to right.
  leftToRight,

  /// Wipe goes bottom to top (particles rise upward).
  bottomToTop,

  /// Wipe goes top to bottom (particles fall downward).
  topToBottom,
}

/// Fade out Particle effect
@immutable
class FadeOutParticle extends StatefulWidget {
  /// widget which is going to be disappeared
  final Widget child;

  /// duration of animation
  final Duration duration;

  /// whether to start disappearing [child] or not
  final bool disappear;

  /// curve of animation
  final Curve curve;

  /// direction of particle dissolve
  final ParticleDirection direction;

  /// callback to get notified when animation is ended
  final VoidCallback? onAnimationEnd;

  /// Fade out Particle effect
  const FadeOutParticle({
    required this.disappear,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.curve = Curves.easeOut,
    this.direction = ParticleDirection.rightToLeft,
    this.onAnimationEnd,
    super.key,
  });

  @override
  State createState() => _FadeOutParticleState();
}

class _FadeOutParticleState extends State<FadeOutParticle>
    with SingleTickerProviderStateMixin {
  final GlobalKey _repaintKey = GlobalKey();
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationEnd?.call();
      }
    });
  late final CurvedAnimation _animation = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
  );
  Iterable<Particle>? _particles;

  @override
  void initState() {
    super.initState();
    if (widget.disappear) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _prepareParticles());
    }
  }

  @override
  void didUpdateWidget(FadeOutParticle oldWidget) {
    if (oldWidget.duration != widget.duration ||
        oldWidget.curve != widget.curve) {
      _controller.duration = widget.duration;
      _animation.curve = widget.curve;
    }
    if (oldWidget.disappear != widget.disappear) {
      if (widget.disappear) {
        _prepareParticles();
      } else {
        _controller.reset();
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _repaintKey,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (BuildContext _, Widget? child) => _RenderObject(
          progress: _animation.value,
          particles: _particles,
          direction: widget.direction,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }

  Future<void> _prepareParticles() async {
    final repaintContext = _repaintKey.currentContext;
    if (repaintContext == null) {
      return;
    }
    RenderRepaintBoundary boundary =
        repaintContext.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image;
    try {
      image = await boundary.toImage();
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _prepareParticles());
      return;
    }

    final bytes = await image.toByteData();

    if (bytes != null && image.width >= 2 && image.height >= 2) {
      final particles = await ParticleGeneration.generateParticlesOnIsolate(
        image.width,
        image.height,
        bytes,
      );
      setState(() {
        _particles = particles;
        _controller.forward();
      });
    }

    image.dispose();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

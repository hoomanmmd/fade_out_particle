import 'dart:async';

import 'package:fade_out_particle/fade_out_particle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fade_out_particle_wrapper.dart';

void main() {
  testWidgets('Disappear widget', (WidgetTester tester) async {
    final widgetBuilder = (Widget child, bool disappear) => FadeOutParticle(
          duration: const Duration(microseconds: 10),
          disappear: disappear,
          child: child,
        );

    await tester.pumpWidget(
      MaterialApp(
        home: FadeOutParticleWrapper(widgetBuilder: widgetBuilder),
      ),
    );

    expect(find.byKey(const ValueKey('1')), findsOneWidget);

    await tester.tap(find.text('Animate'));
    await tester.pump();

    expect(find.byKey(const ValueKey('1')), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('1')), findsNothing);
  });

  testWidgets('onAnimationEnd callback is called after animation ends',
      (tester) async {
    final completer = Completer<void>();

    final widgetBuilder = (Widget child, bool disappear) => FadeOutParticle(
          duration: const Duration(microseconds: 10),
          disappear: disappear,
          onAnimationEnd: () => completer.complete(),
          child: child,
        );

    await tester.pumpWidget(
      MaterialApp(
        home: FadeOutParticleWrapper(widgetBuilder: widgetBuilder),
      ),
    );

    expect(completer.isCompleted, isFalse);

    await tester.pumpAndSettle();

    expect(completer.isCompleted, isTrue);
  });
}

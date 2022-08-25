import 'package:fade_out_particle/fade_out_particle.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FadeOutParticle Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _disappear = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeOutParticle(
              disappear: _disappear,
              duration: const Duration(milliseconds: 3000),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.flutter_dash,
                    size: 52,
                    color: Theme.of(context).primaryColorDark,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Fade out Particle',
                    style: Theme.of(context).textTheme.headline6?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
              onAnimationEnd: () => print('animation ended'),
            ),
            const SizedBox(height: 150),
            OutlinedButton(
              onPressed: () => setState(() => _disappear = !_disappear),
              child: Text(_disappear ? 'Reset' : 'Start'),
            ),
          ],
        ),
      ),
    );
  }
}

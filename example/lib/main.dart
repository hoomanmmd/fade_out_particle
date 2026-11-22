import 'package:fade_out_particle/fade_out_particle.dart';
import 'package:material_ui/material_ui.dart';

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
  bool _disappear = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _fadeOutParticle(),
            _fadeOutParticleRtl(),
            _fadeOutParticleBtt(),
            _fadeOutParticleTtb(),
            _fadeInParticleBtt(),
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

  Widget _fadeOutParticle() {
    return FadeOutParticle(
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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
      onAnimationEnd: () => print('animation ended'),
    );
  }

  Widget _fadeOutParticleRtl() {
    return FadeOutParticle(
      disappear: _disappear,
      direction: ParticleDirection.leftToRight,
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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
      onAnimationEnd: () => print('animation ended'),
    );
  }

  Widget _fadeOutParticleTtb() {
    return FadeOutParticle(
      disappear: _disappear,
      direction: ParticleDirection.topToBottom,
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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
      onAnimationEnd: () => print('animation ended'),
    );
  }

  Widget _fadeOutParticleBtt() {
    return FadeOutParticle(
      disappear: _disappear,
      direction: ParticleDirection.bottomToTop,
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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
      onAnimationEnd: () => print('animation ended'),
    );
  }
  Widget _fadeInParticleBtt() {
    return FadeInParticle(
      appear: _disappear,
      direction: ParticleDirection.bottomToTop,
      duration: const Duration(milliseconds: 2000),
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
            'Fade in Particle',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
      onAnimationEnd: () => print('animation ended'),
    );
  }
}

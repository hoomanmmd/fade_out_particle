import 'package:flutter/material.dart';

class FadeOutParticleWrapper extends StatefulWidget {
  const FadeOutParticleWrapper({
    required this.widgetBuilder,
    super.key,
  });

  final Widget Function(Widget, bool) widgetBuilder;

  @override
  State<FadeOutParticleWrapper> createState() => _FadeOutParticleWrapperState();
}

class _FadeOutParticleWrapperState extends State<FadeOutParticleWrapper> {
  bool _showFirst = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        widget.widgetBuilder(
          Container(
            key: const ValueKey('1'),
            color: Colors.black,
            width: 100,
            height: 100,
          ),
          _showFirst,
        ),
        ElevatedButton(
          onPressed: _toggle,
          child: const Text('Animate'),
        ),
      ],
    );
  }

  void _toggle() {
    setState(() => _showFirst = !_showFirst);
  }
}

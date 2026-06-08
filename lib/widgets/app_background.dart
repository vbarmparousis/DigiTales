import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0E0F3A),
            Color(0xFF1B1B55),
            Color(0xFF2D2A73),
            Color(0xFF4B3B9A),
          ],
        ),
      ),
      child: child,
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/colors.dart';

/// The startup splash: a plain white background with the Dartillect logo
/// centred. Shown briefly on launch, then it navigates to the games overview.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// How long the splash stays on screen before moving to the home screen.
  static const Duration duration = Duration(milliseconds: 3200);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(SplashScreen.duration, () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface, // white
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Image.asset(
            'assets/images/dartillect_logo.png',
            width: 240,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

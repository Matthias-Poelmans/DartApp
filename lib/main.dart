import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'app/router.dart';
import 'app/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Keep the screen on while the app is open — scoring a darts game shouldn't
  // let the phone lock or dim.
  WakelockPlus.enable();
  runApp(const DartsGamesApp());
}

class DartsGamesApp extends StatelessWidget {
  const DartsGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Dartillect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}

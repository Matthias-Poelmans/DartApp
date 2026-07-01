import 'package:flutter/material.dart';

import 'app/router.dart';
import 'app/theme.dart';

void main() {
  runApp(const DartsGamesApp());
}

class DartsGamesApp extends StatelessWidget {
  const DartsGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Darts Games',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:dice/features/game/presentation/screens/start_screen.dart';


void main() {
  runApp(const DiceTargetApp());
}

class DiceTargetApp extends StatelessWidget {
  const DiceTargetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dice Target',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const StartScreen(),
    );
  }
}

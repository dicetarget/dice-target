import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/audio/sfx_singleton.dart';
import 'features/game/presentation/screens/start_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-Edge für Android 15+ (empfohlen)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Optional: transparente Statusbar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // Audio darf NIE den App-Start blockieren/killen
  try {
    await sfx.init();
  } catch (_) {}

  runApp(const DiceApp());
}

class DiceApp extends StatelessWidget {
  const DiceApp({super.key});

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

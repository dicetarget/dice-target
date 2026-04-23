import 'package:dice/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/audio/sfx_singleton.dart';
import 'features/game/presentation/screens/start_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  runApp(const DiceApp());

  Future.microtask(() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (_) {}
  });

  Future.microtask(() async {
    try {
      await sfx.init();
    } catch (_) {}
  });
}

class DiceApp extends StatelessWidget {
  const DiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dice Target',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B5FE0),
          brightness: Brightness.dark,
          surface: const Color(0xFF0D0F1F),
          onSurface: const Color(0xFFEEEAF6),
        ),
        scaffoldBackgroundColor: const Color(0xFF0D0F1F),
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        filledButtonTheme: FilledButtonThemeData(style: ButtonStyle(enableFeedback: false)),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ButtonStyle(enableFeedback: false)),
        outlinedButtonTheme: OutlinedButtonThemeData(style: ButtonStyle(enableFeedback: false)),
        textButtonTheme: TextButtonThemeData(style: ButtonStyle(enableFeedback: false)),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF0D1F35),
          contentTextStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFEEEAF6),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0x403FE8FF), width: 0.5),
          ),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      home: const StartScreen(),
    );
  }
}

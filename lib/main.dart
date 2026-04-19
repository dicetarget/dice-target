import 'package:app_links/app_links.dart';
import 'package:dice/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/audio/sfx_singleton.dart';
import 'features/game/presentation/screens/start_screen.dart';
import 'features/vs/data/vs_link_encoder.dart';
import 'features/vs/domain/vs_challenge.dart';
import 'features/vs/presentation/screens/vs_start_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  try {
    await sfx.init();
  } catch (_) {}
  runApp(const DiceApp());
}

class DiceApp extends StatefulWidget {
  const DiceApp({super.key});

  @override
  State<DiceApp> createState() => _DiceAppState();
}

class _DiceAppState extends State<DiceApp> {
  final _appLinks = AppLinks();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Cold start (App war geschlossen)
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _handleLink(initialLink);
    }
    // Warm start (App war im Hintergrund)
    _appLinks.uriLinkStream.listen(_handleLink);
  }

  void _handleLink(Uri uri) {
    if (uri.scheme != 'dicetarget' || uri.host != 'vs') return;
    final VsChallenge? challenge = VsLinkEncoder.decode(uri.toString());
    if (challenge == null) return;
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => VsStartScreen(
          mode: VsStartMode.opponent,
          incomingChallenge: challenge,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dice Target',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
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
        // ── Dark Neon SnackBar ──────────────────────────────────────────────
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

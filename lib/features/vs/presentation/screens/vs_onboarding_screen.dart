import 'package:flutter/material.dart';
import 'package:dice/features/vs/data/vs_player_storage.dart';
import 'package:dice/features/vs/data/vs_firestore_service.dart';
import 'package:dice/features/vs/presentation/screens/vs_home_screen.dart';

class VsOnboardingScreen extends StatefulWidget {
  const VsOnboardingScreen({super.key});

  @override
  State<VsOnboardingScreen> createState() => _VsOnboardingScreenState();
}

class _VsOnboardingScreenState extends State<VsOnboardingScreen> {
  static const Color _violet = Color(0xFF7B35E8);

  final _controller = TextEditingController();
  final _storage = VsPlayerStorage();
  final _firestore = VsFirestoreService();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final name = _controller.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Please enter a name');
      return;
    }
    if (name.length < 2) {
      setState(() => _error = 'Name must be at least 2 characters');
      return;
    }
    if (name.length > 20) {
      setState(() => _error = 'Name must be at most 20 characters');
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9 ]+$').hasMatch(name)) {
      setState(() => _error = 'Only letters, numbers and spaces allowed');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final existing = await _firestore.findPlayer(name);
    if (existing != null) {
      setState(() {
        _error = 'Name already taken. Choose another.';
        _loading = false;
      });
      return;
    }

    final player = await _storage.loadOrCreate();
    final updated = player.copyWith(displayName: name);
    await _storage.save(updated);
    await _firestore.savePlayer(updated);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const VsHomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1628), Color(0xFF060B14), Color(0xFF020408)],
            stops: [0.0, 0.5, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _violet.withValues(alpha: 0.70),
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose your name',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This is how friends will find you.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.55),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _controller,
                  maxLength: 20,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  decoration: InputDecoration(
                    hintText: 'Your name',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.30),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    // errorText intentionally omitted — handled manually below
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _error != null
                            ? const Color(0xFFFF3B30)
                            : _violet.withValues(alpha: 0.40),
                        width: _error != null ? 1.0 : 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _error != null
                            ? const Color(0xFFFF3B30)
                            : _violet.withValues(alpha: 0.90),
                        width: 1.5,
                      ),
                    ),
                    counterStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.30),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                ),
                // Manual error row — wraps correctly on all platforms
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFFF3B30),
                        fontWeight: FontWeight.w500,
                      ),
                      softWrap: true,
                    ),
                  ),
                const SizedBox(height: 24),
                if (_loading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: _violet,
                      strokeWidth: 2.5,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _confirm,
                    child: Container(
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _violet.withValues(alpha: 0.22),
                            _violet.withValues(alpha: 0.10),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _violet.withValues(alpha: 0.70),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _violet.withValues(alpha: 0.30),
                            blurRadius: 24,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "Let's go!",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: _violet,
                          ),
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

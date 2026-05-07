import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/widgets/tactile_button.dart';
import 'package:dice/features/vs/data/vs_firestore_service.dart';
import 'package:dice/features/vs/data/vs_player_storage.dart';
import 'package:dice/features/vs/presentation/screens/vs_home_screen.dart';
import 'package:flutter/material.dart';

class VsOnboardingScreen extends StatefulWidget {
  const VsOnboardingScreen({super.key});

  @override
  State<VsOnboardingScreen> createState() => _VsOnboardingScreenState();
}

class _VsOnboardingScreenState extends State<VsOnboardingScreen> {
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
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: AppColors.inkMuted,
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
              ),
              const Spacer(),
              const Text(
                'VS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkMuted,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose your name',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                  letterSpacing: -0.8,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This is how friends will find you.',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _controller,
                maxLength: 20,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: InputDecoration(
                  hintText: 'Your name',
                  hintStyle: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceHigh,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _error != null
                          ? AppColors.failed
                          : Colors.white.withValues(alpha: 0.12),
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _error != null
                          ? AppColors.failed
                          : AppColors.gold.withValues(alpha: 0.70),
                      width: 1.5,
                    ),
                  ),
                  counterStyle: const TextStyle(color: AppColors.inkMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.failed,
                      fontWeight: FontWeight.w500,
                    ),
                    softWrap: true,
                  ),
                ),
              const SizedBox(height: 24),
              if (_loading)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2.5),
                )
              else
                TactileButton(
                  variant: TactileButtonVariant.gold,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  borderRadius: BorderRadius.circular(16),
                  onPressed: _confirm,
                  child: const Text(
                    "Let's go!",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dicePip,
                    ),
                  ),
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

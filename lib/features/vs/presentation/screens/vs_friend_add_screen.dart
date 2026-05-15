import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/widgets/tactile_button.dart';
import 'package:dice/features/vs/data/vs_firestore_service.dart';
import 'package:flutter/material.dart';

class VsFriendAddScreen extends StatefulWidget {
  final String myId;
  final String myDisplayName;

  const VsFriendAddScreen({
    super.key,
    required this.myId,
    required this.myDisplayName,
  });

  @override
  State<VsFriendAddScreen> createState() => _VsFriendAddScreenState();
}

class _VsFriendAddScreenState extends State<VsFriendAddScreen> {
  final _controller = TextEditingController();
  final _firestore = VsFirestoreService();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addFriend() async {
    final input = _controller.text.trim();

    if (input.isEmpty) {
      setState(() => _error = 'Please enter a name');
      return;
    }

    if (input.length < 2) {
      setState(() => _error = 'Name must be at least 2 characters');
      return;
    }

    if (input == widget.myDisplayName) {
      setState(() => _error = "That's your own name!");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final found = await _firestore.findPlayer(input);
    if (found == null) {
      setState(() {
        _error = 'Player not found.';
        _loading = false;
      });
      return;
    }

    await _firestore.addFriend(widget.myId, found.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.inkMuted,
          enableFeedback: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Add Friend',
          style: TextStyle(
            color: Color(0xFF9060C8),
            fontWeight: FontWeight.w800,
            fontSize: 17,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text(
                "Enter your friend's name",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ask your friend for their display name.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: "Friend's name",
                  hintStyle: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                  errorText: _error,
                  errorStyle: const TextStyle(fontSize: 13, color: AppColors.failed),
                  filled: true,
                  fillColor: AppColors.surfaceHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.gold.withValues(alpha: 0.50),
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: const Color(0xFF9060C8).withValues(alpha: 0.70),
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.failed, width: 1.0),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.failed, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFF9060C8), strokeWidth: 2.5),
                )
              else
                TactileButton(
                  variant: TactileButtonVariant.purple,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  borderRadius: BorderRadius.circular(16),
                  onPressed: _addFriend,
                  child: const Text(
                    'Add Friend',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TactileButton(
                variant: TactileButtonVariant.primary,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                borderRadius: BorderRadius.circular(16),
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text(
                  'Home',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

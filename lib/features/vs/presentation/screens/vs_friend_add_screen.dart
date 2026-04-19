import 'package:flutter/material.dart';
import 'package:dice/features/vs/data/vs_firestore_service.dart';

class VsFriendAddScreen extends StatefulWidget {
  final String myId;

  const VsFriendAddScreen({super.key, required this.myId});

  @override
  State<VsFriendAddScreen> createState() => _VsFriendAddScreenState();
}

class _VsFriendAddScreenState extends State<VsFriendAddScreen> {
  static const Color _orange = Color(0xFFFF6B00);

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
    final input = _controller.text.trim().toUpperCase();

    if (!RegExp(r'^DICE-\d{4}$').hasMatch(input)) {
      setState(() => _error = 'Invalid ID. Format: DICE-XXXX');
      return;
    }

    if (input == widget.myId) {
      setState(() => _error = "That's your own ID!");
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

    await _firestore.addFriend(widget.myId, input);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF020408),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: Colors.white.withValues(alpha: 0.70),
          enableFeedback: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Add Friend',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 17,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
      ),
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
                const SizedBox(height: 32),
                const Text(
                  "Enter your friend's ID",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ask them to share their DICE-XXXX ID with you.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.55),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'DICE-XXXX',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.20),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                    errorText: _error,
                    errorStyle: const TextStyle(fontSize: 13, color: Color(0xFFFF3B30)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: _orange.withValues(alpha: 0.70), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: _orange.withValues(alpha: 0.70), width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 1.0),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  ),
                ),
                const SizedBox(height: 24),
                if (_loading)
                  const Center(
                    child: CircularProgressIndicator(color: _orange, strokeWidth: 2.5),
                  )
                else
                  GestureDetector(
                    onTap: _addFriend,
                    child: Container(
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _orange.withValues(alpha: 0.22),
                            _orange.withValues(alpha: 0.10),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _orange.withValues(alpha: 0.70), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: _orange.withValues(alpha: 0.30),
                            blurRadius: 24,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Add Friend',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: _orange,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 0.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Home',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

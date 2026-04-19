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
    if (input.isEmpty) return;
    if (input == widget.myId) {
      setState(() => _error = "That's your own ID.");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final found = await _firestore.findPlayer(input);
      if (found == null) {
        setState(() => _error = 'Player not found.');
        return;
      }
      await _firestore.addFriend(widget.myId, found.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Text(
              'Enter their Player ID',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.50),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
              decoration: InputDecoration(
                hintText: 'DICE-XXXX',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.20)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _orange.withValues(alpha: 0.40)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _orange.withValues(alpha: 0.70), width: 1.5),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(fontSize: 13, color: Color(0xFFFF3B30)),
              ),
            ],
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _loading ? null : _addFriend,
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_orange.withValues(alpha: 0.22), _orange.withValues(alpha: 0.10)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _orange.withValues(alpha: 0.70), width: 1.5),
                ),
                child: Center(
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _orange),
                        )
                      : const Text(
                          'Add Friend',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: _orange,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

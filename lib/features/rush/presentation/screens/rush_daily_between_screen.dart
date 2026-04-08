// lib/features/rush/presentation/screens/rush_daily_between_screen.dart

import 'package:flutter/material.dart';

class RushDailyBetweenScreen extends StatelessWidget {
  final int run1Score;
  final VoidCallback onStartRun2;

  const RushDailyBetweenScreen({super.key, required this.run1Score, required this.onStartRun2});

  static const Color _green = Color(0xFF00E5A0);
  static const Color _bg = Color(0xFF0A0F1F);
  static const Color _card = Color(0xFF141A2E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Speed Run',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Run 1 complete label
              Center(
                child: Text(
                  'Run 1 Complete',
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 0.5,
                    color: Colors.white.withValues(alpha: 0.40),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Score card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 36),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$run1Score',
                      style: const TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -2.5,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      run1Score == 1 ? 'puzzle solved' : 'puzzles solved',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Can you beat it in Run 2?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.30),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              // Start Run 2 button
              GestureDetector(
                onTap: onStartRun2,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_green.withValues(alpha: 0.28), _green.withValues(alpha: 0.13)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _green.withValues(alpha: 0.65), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.22),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      const Text(
                        'Start Run 2',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

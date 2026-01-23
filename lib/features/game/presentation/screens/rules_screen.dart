import 'package:flutter/material.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rules'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('Goal'),
              SizedBox(height: 6),
              Text(
                'Reach the target number using the values of the dice.',
                style: _bodyStyle,
              ),

              SizedBox(height: 20),
              _SectionTitle('How to Play'),
              SizedBox(height: 6),
              Text(
                '• A target number is generated at the start of each round.\n'
                '• Five dice are rolled, each showing a value from 1 to 6.\n'
                '• Tap two dice to select them (the order matters).\n'
                '• Choose an operation: +, −, ×, or ÷.\n'
                '• The selected dice are replaced by the result of the operation.\n'
                '• Continue until only one number remains.',
                style: _bodyStyle,
              ),

              SizedBox(height: 20),
              _SectionTitle('Operations'),
              SizedBox(height: 6),
              Text(
                '• Addition (+): Adds the two selected dice.\n'
                '• Subtraction (−): Subtracts the second die from the first.\n'
                '• Multiplication (×): Multiplies the two dice.\n'
                '• Division (÷): Only allowed if the result is a whole number.',
                style: _bodyStyle,
              ),

              SizedBox(height: 20),
              _SectionTitle('Winning the Game'),
              SizedBox(height: 6),
              Text(
                '• You win if the final remaining number is exactly equal to the target.\n'
                '• Try to reach the target in as few moves as possible.',
                style: _bodyStyle,
              ),

              SizedBox(height: 20),
              _SectionTitle('Buttons'),
              SizedBox(height: 6),
              Text(
                '• Solve: Shows a possible solution (if available).\n'
                '• Impossible: Mark the current round as unsolvable.\n'
                '• Reset Dice: Resets the dice to their initial values.\n'
                '• New Game: Starts a completely new round.',
                style: _bodyStyle,
              ),

              SizedBox(height: 20),
              _SectionTitle('Difficulty Levels'),
              SizedBox(height: 6),
              Text(
                '• Easy: Target range from 1 to 50.\n'
                '• Medium: Target range from 1 to 100.\n'
                '• Hard: Target range from 1 to 150.',
                style: _bodyStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

const TextStyle _bodyStyle = TextStyle(
  fontSize: 16,
  height: 1.4,
);

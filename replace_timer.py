with open('lib/features/game/presentation/screens/practice_screen.dart', 'r') as f:
    content = f.read()

# Replace the timer body
old_timer_body = '''        if (!mounted) return;
        final maskedDice = <DiceState>[];
        final usedLabels = <String>{};
        for (final d in _gameState.dice) {
          if (d.maskLabel != null) {
            maskedDice.add(DiceState(value: d.value, maskLabel: d.maskLabel));
            usedLabels.add(d.maskLabel!);
          } else {
            String nextLabel = '?';
            if (usedLabels.contains(nextLabel)) {
              var n = 2;
              while (usedLabels.contains('?$n')) {
                n++;
              }
              nextLabel = '?$n';
            }
            usedLabels.add(nextLabel);
            maskedDice.add(DiceState(value: d.value, maskLabel: nextLabel));
          }
        }
        setState(() {
          _gameState = _gameState.copyWith(dice: maskedDice);
        });'''

new_timer_body = '''        if (!mounted) return;
        if (_gameState.dice.isEmpty) return;
        final updatedDice = List<DiceState>.from(_gameState.dice);
        final lastIndex = updatedDice.length - 1;
        final lastDie = updatedDice[lastIndex];
        if (lastDie.maskLabel == null) {
          updatedDice[lastIndex] = DiceState(
            value: lastDie.value,
            maskLabel: _nextQuestionMarkLabel(),
          );
          setState(() {
            _gameState = _gameState.copyWith(dice: updatedDice);
          });
        }'''

content = content.replace(old_timer_body, new_timer_body)

with open('lib/features/game/presentation/screens/practice_screen.dart', 'w') as f:
    f.write(content)

print('Replaced')
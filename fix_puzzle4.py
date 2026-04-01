with open('lib/features/game/presentation/screens/practice_screen.dart', 'r') as f:
    content = f.read()

# Find the start of the block
start = content.find('    if (_isPuzzle4Memory && !_isPuzzle5Hidden) {')
if start == -1:
    print('Block not found')
    exit(1)

# Find the end of the block
end = content.find('    if (!move.willEndAfterMove && _soundEnabled) {', start)
if end == -1:
    print('End not found')
    exit(1)

# The block to replace is from start to end
old_block = content[start:end]

new_block = '''    if (_isPuzzle4Memory && !_isPuzzle5Hidden) {
      _memoryFadeTimer?.cancel();
      _memoryFadeTimer = Timer(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
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
        }
      });
    }
'''

content = content.replace(old_block, new_block)

with open('lib/features/game/presentation/screens/practice_screen.dart', 'w') as f:
    f.write(content)

print('Replaced')
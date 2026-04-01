with open('lib/features/game/presentation/screens/practice_screen.dart', 'r') as f:
    lines = f.readlines()

start_line = None
for i, line in enumerate(lines):
    if 'if (_isPuzzle4Memory && !_isPuzzle5Hidden) {' in line:
        start_line = i
        break

if start_line is None:
    print('Start not found')
    exit(1)

# Find the end
end_line = None
for i in range(start_line, len(lines)):
    if 'if (!move.willEndAfterMove && _soundEnabled) {' in lines[i]:
        end_line = i
        break

if end_line is None:
    print('End not found')
    exit(1)

# Replace from start_line to end_line - 1
new_lines = [
    '    if (_isPuzzle4Memory && !_isPuzzle5Hidden) {\n',
    '      _memoryFadeTimer?.cancel();\n',
    '      _memoryFadeTimer = Timer(const Duration(milliseconds: 1400), () {\n',
    '        if (!mounted) return;\n',
    '        if (_gameState.dice.isEmpty) return;\n',
    '        final updatedDice = List<DiceState>.from(_gameState.dice);\n',
    '        final lastIndex = updatedDice.length - 1;\n',
    '        final lastDie = updatedDice[lastIndex];\n',
    '        if (lastDie.maskLabel == null) {\n',
    '          updatedDice[lastIndex] = DiceState(\n',
    '            value: lastDie.value,\n',
    '            maskLabel: _nextQuestionMarkLabel(),\n',
    '          );\n',
    '          setState(() {\n',
    '            _gameState = _gameState.copyWith(dice: updatedDice);\n',
    '          });\n',
    '        }\n',
    '      });\n',
    '    }\n',
]

lines[start_line:end_line] = new_lines

with open('lib/features/game/presentation/screens/practice_screen.dart', 'w') as f:
    f.writelines(lines)

print('Replaced')
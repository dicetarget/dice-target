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

# Find the closing } of the if block
brace_count = 0
end_line = None
for i in range(start_line, len(lines)):
    line = lines[i]
    brace_count += line.count('{') - line.count('}')
    if brace_count == 0 and line.strip() == '}':
        end_line = i
        break

if end_line is None:
    print('End not found')
    exit(1)

print('Start line:', start_line + 1)
print('End line:', end_line + 1)

# Replace from start_line to end_line inclusive
new_lines = [
    '    if (_isPuzzle4Memory && !_isPuzzle5Hidden) {',
    '      _memoryFadeTimer?.cancel();',
    '      _memoryFadeTimer = Timer(const Duration(milliseconds: 1400), () {',
    '        if (!mounted) return;',
    '        if (_gameState.dice.isEmpty) return;',
    '        final updatedDice = List<DiceState>.from(_gameState.dice);',
    '        final lastIndex = updatedDice.length - 1;',
    '        final lastDie = updatedDice[lastIndex];',
    '        if (lastDie.maskLabel == null) {',
    '          updatedDice[lastIndex] = DiceState(',
    '            value: lastDie.value,',
    '            maskLabel: _nextQuestionMarkLabel(),',
    '          );',
    '          setState(() {',
    '            _gameState = _gameState.copyWith(dice: updatedDice);',
    '          });',
    '        }',
    '      });',
    '    }',
]

lines[start_line:end_line+1] = [line + '\n' for line in new_lines]

with open('lib/features/game/presentation/screens/practice_screen.dart', 'w') as f:
    f.writelines(lines)

print('Replaced')
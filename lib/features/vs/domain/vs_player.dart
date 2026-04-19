import 'dart:math';

class VsPlayer {
  final String id;
  final DateTime createdAt;

  const VsPlayer({required this.id, required this.createdAt});

  static VsPlayer generate() {
    final number = Random().nextInt(10000).toString().padLeft(4, '0');
    return VsPlayer(
      id: 'DICE-$number',
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
      };

  factory VsPlayer.fromMap(Map<String, dynamic> map) => VsPlayer(
        id: map['id'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}

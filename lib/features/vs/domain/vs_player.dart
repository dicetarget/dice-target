import 'package:uuid/uuid.dart';

class VsPlayer {
  final String id;
  final String displayName;
  final DateTime createdAt;

  const VsPlayer({
    required this.id,
    required this.displayName,
    required this.createdAt,
  });

  static VsPlayer generate() => VsPlayer(
        id: const Uuid().v4(),
        displayName: '',
        createdAt: DateTime.now(),
      );

  VsPlayer copyWith({String? displayName}) => VsPlayer(
        id: id,
        displayName: displayName ?? this.displayName,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'displayName': displayName,
        'createdAt': createdAt.toIso8601String(),
      };

  factory VsPlayer.fromMap(Map<String, dynamic> map) => VsPlayer(
        id: map['id'] as String,
        displayName: map['displayName'] as String? ?? '',
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}

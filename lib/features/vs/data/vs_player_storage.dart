import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/vs_player.dart';

class VsPlayerStorage {
  static const String _key = 'vs_player';

  Future<VsPlayer> loadOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      final player = VsPlayer.generate();
      await save(player);
      return player;
    }
    return VsPlayer.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(VsPlayer player) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(player.toMap()));
  }
}

import '../domain/vs_challenge.dart';

class VsLinkEncoder {
  static String encode(VsChallenge challenge) {
    return 'dicetarget://vs?data=${challenge.toBase64()}';
  }

  static VsChallenge? decode(String link) {
    try {
      final uri = Uri.parse(link);
      final data = uri.queryParameters['data'];
      if (data == null || data.isEmpty) return null;
      final challenge = VsChallenge.fromBase64(data);
      if (challenge.isExpired()) return null;
      return challenge;
    } catch (_) {
      return null;
    }
  }
}

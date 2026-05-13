import 'package:shared_preferences/shared_preferences.dart';

/// Gerenciador de tokens JWT armazenados localmente.
class TokenStorage {
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';

  final SharedPreferences _prefs;

  TokenStorage(this._prefs);

  // ─── Access Token ───────────────────────────

  String? get accessToken => _prefs.getString(_keyAccessToken);

  Future<void> saveAccessToken(String token) =>
      _prefs.setString(_keyAccessToken, token);

  // ─── Refresh Token ──────────────────────────

  String? get refreshToken => _prefs.getString(_keyRefreshToken);

  Future<void> saveRefreshToken(String token) =>
      _prefs.setString(_keyRefreshToken, token);

  // ─── Helpers ────────────────────────────────

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _prefs.remove(_keyAccessToken),
      _prefs.remove(_keyRefreshToken),
    ]);
  }

  bool get hasTokens => accessToken != null && refreshToken != null;
}

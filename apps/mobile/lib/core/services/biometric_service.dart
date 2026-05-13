import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Gerencia autenticação biométrica e armazenamento seguro de credenciais.
class BiometricService {
  static const _keyBiometricEnabled = 'biometric_enabled';
  static const _keySecureRefreshToken = 'secure_refresh_token';
  static const _keySecureLogin = 'secure_login';

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Verifica se o dispositivo suporta biometria.
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  /// Lista os tipos de biometria disponíveis (face, impressão digital etc).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Retorna true se o usuário ativou login biométrico.
  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  /// Ativa ou desativa o login biométrico, salvando as credenciais com segurança.
  Future<void> setBiometricEnabled({
    required bool enabled,
    String? login,
    String? refreshToken,
  }) async {
    if (enabled && login != null && refreshToken != null) {
      await Future.wait([
        _secureStorage.write(key: _keyBiometricEnabled, value: 'true'),
        _secureStorage.write(key: _keySecureLogin, value: login),
        _secureStorage.write(key: _keySecureRefreshToken, value: refreshToken),
      ]);
    } else {
      await Future.wait([
        _secureStorage.write(key: _keyBiometricEnabled, value: 'false'),
        _secureStorage.delete(key: _keySecureLogin),
        _secureStorage.delete(key: _keySecureRefreshToken),
      ]);
    }
  }

  /// Recupera o refresh token armazenado com segurança.
  Future<String?> getSecureRefreshToken() =>
      _secureStorage.read(key: _keySecureRefreshToken);

  /// Recupera o login armazenado.
  Future<String?> getSecureLogin() =>
      _secureStorage.read(key: _keySecureLogin);

  /// Solicita autenticação biométrica ao usuário.
  /// Retorna true se autenticado com sucesso.
  Future<bool> authenticate() async {
    try {
      final available = await isAvailable();
      if (!available) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Use sua biometria para acessar o Fyna',
        options: const AuthenticationOptions(
          biometricOnly: false, // permite PIN como fallback
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  /// Limpa todos os dados biométricos (usado no logout).
  Future<void> clearAll() async {
    await Future.wait([
      _secureStorage.delete(key: _keyBiometricEnabled),
      _secureStorage.delete(key: _keySecureLogin),
      _secureStorage.delete(key: _keySecureRefreshToken),
    ]);
  }
}

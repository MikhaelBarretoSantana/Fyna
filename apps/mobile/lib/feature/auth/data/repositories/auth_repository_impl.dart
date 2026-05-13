import 'package:fyna/core/network/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fyna/feature/auth/data/datasource/auth_remote_datasource.dart';
import 'package:fyna/feature/auth/domain/entities/auth_entity.dart';
import 'package:fyna/feature/auth/domain/repositories/auth_repository.dart';

/// Implementação concreta do [AuthRepository].
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _datasource;
  final TokenStorage _tokenStorage;
  final SharedPreferences _prefs;

  AuthRepositoryImpl({
    required AuthRemoteDatasource datasource,
    required TokenStorage tokenStorage,
    required SharedPreferences prefs,
  })  : _datasource = datasource,
        _tokenStorage = tokenStorage,
        _prefs = prefs;

  @override
  Future<AuthEntity> register({
    required String login,
    required String email,
    required String password,
    required String fullName,
    String? phone,
    DateTime? birthDate,
  }) async {
    final body = <String, dynamic>{
      'login': login,
      'email': email,
      'password': password,
      'fullName': fullName,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (birthDate != null)
        'birthDate':
            '${birthDate.year.toString().padLeft(4, '0')}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}',
    };

    final auth = await _datasource.register(body);

    // Persiste os tokens localmente
    await _tokenStorage.saveTokens(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
    );

    // Persiste dados do usuário para a tela de perfil
    await _saveUserData(auth);

    return auth;
  }

  @override
  Future<AuthEntity> login({
    required String login,
    required String password,
  }) async {
    final body = <String, dynamic>{
      'login': login,
      'password': password,
    };

    final auth = await _datasource.login(body);

    await _tokenStorage.saveTokens(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
    );

    // Persiste dados do usuário para a tela de perfil
    await _saveUserData(auth);

    return auth;
  }

  @override
  Future<AuthEntity> refresh({required String refreshToken}) async {
    final auth = await _datasource.refresh(refreshToken);
    await _tokenStorage.saveTokens(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
    );
    await _saveUserData(auth);
    return auth;
  }

  @override
  Future<void> logout() async {
    try {
      await _datasource.logout();
    } catch (_) {
      // Ignora erros de rede — limpa tokens locais de qualquer forma
    } finally {
      await _tokenStorage.clearTokens();
      await _clearUserData();
    }
  }

  /// Salva dados do usuário no SharedPreferences.
  Future<void> _saveUserData(AuthEntity auth) async {
    await _prefs.setString('user_full_name', auth.user.fullName);
    await _prefs.setString('user_email', auth.user.email);
    await _prefs.setString('user_login', auth.user.login);
    await _prefs.setString('user_id', auth.user.id);
  }

  /// Limpa dados do usuário no logout.
  Future<void> _clearUserData() async {
    await _prefs.remove('user_full_name');
    await _prefs.remove('user_email');
    await _prefs.remove('user_login');
    await _prefs.remove('user_id');
  }
}

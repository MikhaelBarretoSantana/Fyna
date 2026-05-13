import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fyna/core/network/token_storage.dart';
import 'package:fyna/feature/auth/data/datasource/auth_remote_datasource.dart';
import 'package:fyna/feature/auth/data/repositories/auth_repository_impl.dart';
import 'package:fyna/feature/auth/domain/entities/auth_entity.dart';
import 'package:fyna/feature/auth/domain/entities/user_entity.dart';

@GenerateMocks([AuthRemoteDatasource, TokenStorage, SharedPreferences])
import 'auth_repository_impl_test.mocks.dart';

void main() {
  late MockAuthRemoteDatasource datasource;
  late MockTokenStorage tokenStorage;
  late MockSharedPreferences prefs;
  late AuthRepositoryImpl repository;

  final fakeAuth = AuthEntity(
    accessToken: 'access-123',
    refreshToken: 'refresh-456',
    tokenType: 'Bearer',
    user: UserEntity(
      id: 'user-1',
      login: 'joao',
      email: 'joao@email.com',
      fullName: 'João Silva',
    ),
  );

  setUp(() {
    datasource = MockAuthRemoteDatasource();
    tokenStorage = MockTokenStorage();
    prefs = MockSharedPreferences();
    repository = AuthRepositoryImpl(
      datasource: datasource,
      tokenStorage: tokenStorage,
      prefs: prefs,
    );
  });

  group('login', () {
    test('salva tokens e dados do usuário após login bem-sucedido', () async {
      when(datasource.login(any)).thenAnswer((_) async => fakeAuth);
      when(tokenStorage.saveTokens(
        accessToken: anyNamed('accessToken'),
        refreshToken: anyNamed('refreshToken'),
      )).thenAnswer((_) async {});
      when(prefs.setString(any, any)).thenAnswer((_) async => true);

      final result = await repository.login(login: 'joao', password: '123456');

      expect(result.accessToken, equals('access-123'));
      expect(result.user.fullName, equals('João Silva'));

      verify(tokenStorage.saveTokens(
        accessToken: 'access-123',
        refreshToken: 'refresh-456',
      )).called(1);

      verify(prefs.setString('user_id', 'user-1')).called(1);
      verify(prefs.setString('user_login', 'joao')).called(1);
    });

    test('propaga exceção do datasource', () async {
      when(datasource.login(any)).thenThrow(Exception('Credenciais inválidas'));

      expect(
        () => repository.login(login: 'joao', password: 'errada'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('logout', () {
    test('limpa tokens mesmo quando chamada ao servidor falha', () async {
      when(datasource.logout()).thenThrow(Exception('network error'));
      when(tokenStorage.clearTokens()).thenAnswer((_) async {});
      when(prefs.remove(any)).thenAnswer((_) async => true);

      await repository.logout();

      verify(tokenStorage.clearTokens()).called(1);
      verify(prefs.remove('user_id')).called(1);
    });

    test('limpa dados do usuário no logout bem-sucedido', () async {
      when(datasource.logout()).thenAnswer((_) async {});
      when(tokenStorage.clearTokens()).thenAnswer((_) async {});
      when(prefs.remove(any)).thenAnswer((_) async => true);

      await repository.logout();

      verify(prefs.remove('user_full_name')).called(1);
      verify(prefs.remove('user_email')).called(1);
      verify(prefs.remove('user_login')).called(1);
      verify(prefs.remove('user_id')).called(1);
    });
  });

  group('register', () {
    test('salva tokens após registro bem-sucedido', () async {
      when(datasource.register(any)).thenAnswer((_) async => fakeAuth);
      when(tokenStorage.saveTokens(
        accessToken: anyNamed('accessToken'),
        refreshToken: anyNamed('refreshToken'),
      )).thenAnswer((_) async {});
      when(prefs.setString(any, any)).thenAnswer((_) async => true);

      final result = await repository.register(
        login: 'joao',
        email: 'joao@email.com',
        password: '123456',
        fullName: 'João Silva',
      );

      expect(result.refreshToken, equals('refresh-456'));
      verify(tokenStorage.saveTokens(
        accessToken: 'access-123',
        refreshToken: 'refresh-456',
      )).called(1);
    });
  });
}

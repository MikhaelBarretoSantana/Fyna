import 'package:fyna/core/services/biometric_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fyna/core/network/dio_client.dart';
import 'package:fyna/core/network/token_storage.dart';
import 'package:fyna/feature/auth/data/datasource/auth_remote_datasource.dart';
import 'package:fyna/feature/auth/data/repositories/auth_repository_impl.dart';
import 'package:fyna/feature/auth/domain/repositories/auth_repository.dart';
import 'package:fyna/feature/account/data/datasource/account_remote_datasource.dart';
import 'package:fyna/feature/account/data/repositories/account_repository_impl.dart';
import 'package:fyna/feature/account/domain/repositories/account_repository.dart';
import 'package:fyna/feature/transaction/data/datasource/transaction_remote_datasource.dart';
import 'package:fyna/feature/transaction/data/repositories/transaction_repository_impl.dart';
import 'package:fyna/feature/transaction/domain/repositories/transaction_repository.dart';
import 'package:fyna/feature/category/data/datasource/category_remote_datasource.dart';
import 'package:fyna/feature/category/data/repositories/category_repository_impl.dart';
import 'package:fyna/feature/category/domain/repositories/category_repository.dart';
import 'package:fyna/feature/ai_classification/data/datasource/ai_insights_remote_datasource.dart';
import 'package:fyna/feature/ai_classification/data/repositories/ai_insights_repository_impl.dart';
import 'package:fyna/feature/ai_classification/domain/repositories/ai_insights_repository.dart';
import 'package:fyna/feature/recurring/data/datasource/recurring_remote_datasource.dart';
import 'package:fyna/feature/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:fyna/feature/recurring/domain/repositories/recurring_repository.dart';

/// Service locator simples — instanciado uma vez em main().
class Injection {
  static late final Injection instance;

  final SharedPreferences prefs;
  late final TokenStorage tokenStorage;
  late final DioClient dioClient;

  // Auth
  late final AuthRemoteDatasource authRemoteDatasource;
  late final AuthRepository authRepository;

  // Account
  late final AccountRemoteDatasource accountRemoteDatasource;
  late final AccountRepository accountRepository;

  // Transaction
  late final TransactionRemoteDatasource transactionRemoteDatasource;
  late final TransactionRepository transactionRepository;

  // Category
  late final CategoryRemoteDatasource categoryRemoteDatasource;
  late final CategoryRepository categoryRepository;

  // AI Insights
  late final AIInsightsRemoteDatasource aiInsightsRemoteDatasource;
  late final AIInsightsRepository aiInsightsRepository;

  // Recurring
  late final RecurringRemoteDatasource recurringRemoteDatasource;
  late final RecurringRepository recurringRepository;

  // Biometric
  late final BiometricService biometricService;

  Injection._(this.prefs) {
    tokenStorage = TokenStorage(prefs);
    dioClient = DioClient(tokenStorage: tokenStorage);

    // Auth
    authRemoteDatasource = AuthRemoteDatasource(dioClient.dio);
    authRepository = AuthRepositoryImpl(
      datasource: authRemoteDatasource,
      tokenStorage: tokenStorage,
      prefs: prefs,
    );

    // Account
    accountRemoteDatasource = AccountRemoteDatasource(dioClient.dio);
    accountRepository = AccountRepositoryImpl(
      datasource: accountRemoteDatasource,
    );

    // Transaction
    transactionRemoteDatasource = TransactionRemoteDatasource(dioClient.dio);
    transactionRepository = TransactionRepositoryImpl(
      datasource: transactionRemoteDatasource,
    );

    // Category
    categoryRemoteDatasource = CategoryRemoteDatasource(dioClient.dio);
    categoryRepository = CategoryRepositoryImpl(
      datasource: categoryRemoteDatasource,
    );

    // AI Insights
    aiInsightsRemoteDatasource = AIInsightsRemoteDatasource(dioClient.dio);
    aiInsightsRepository = AIInsightsRepositoryImpl(
      datasource: aiInsightsRemoteDatasource,
    );

    // Recurring
    recurringRemoteDatasource = RecurringRemoteDatasource(dioClient.dio);
    recurringRepository = RecurringRepositoryImpl(
      datasource: recurringRemoteDatasource,
    );

    // Biometric
    biometricService = BiometricService();
  }

  /// Deve ser chamado uma vez em main() antes de runApp().
  static void init(SharedPreferences prefs) {
    instance = Injection._(prefs);
  }
}
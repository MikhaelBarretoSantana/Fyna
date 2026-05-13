import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fyna/feature/auth/presentation/pages/login.page.dart';
import 'package:fyna/feature/auth/presentation/pages/quick_login.page.dart';
import 'package:fyna/feature/auth/presentation/pages/register.page.dart';
import 'package:fyna/feature/home/presentation/pages/home.page.dart';
import 'package:fyna/feature/account/presentation/pages/create_account.page.dart';
import 'package:fyna/core/enums/transaction_type.dart';
import 'package:fyna/feature/transaction/presentation/pages/create_transaction.page.dart';
import 'package:fyna/feature/budget/presentation/pages/budgets.page.dart';
import 'package:fyna/feature/budget/presentation/pages/create_budget.page.dart';
import 'package:fyna/feature/goals/presentation/pages/goals.page.dart';
import 'package:fyna/feature/goals/presentation/pages/create_goal.page.dart';
import 'package:fyna/feature/ai_classification/presentation/pages/ai_insights.page.dart';
import 'package:fyna/feature/notifications/presentation/pages/notifications.page.dart';
import 'package:fyna/feature/recurring/presentation/pages/recurring_transactions.page.dart';
import 'package:fyna/feature/recurring/presentation/pages/create_recurring.page.dart';
import 'package:fyna/feature/category/presentation/pages/categories.page.dart';
import 'package:fyna/feature/bank_notifications/presentation/pages/bank_notification_setup.page.dart';

class AppRoutes {
  AppRoutes._();

  static const String welcome = '/';
  static const String login = '/login';
  static const String quickLogin = '/quick-login';
  static const String register = '/register';
  static const String home = '/home';
  static const String createAccount = '/create-account';
  static const String createTransaction = '/create-transaction';
  static const String budgets = '/budgets';
  static const String createBudget = '/create-budget';
  static const String goals = '/goals';
  static const String createGoal = '/create-goal';
  static const String aiInsights = '/ai-insights';
  static const String notifications = '/notifications';
  static const String recurring = '/recurring';
  static const String createRecurring = '/create-recurring';
  static const String categories = '/categories';
  static const String bankNotificationSetup = '/bank-notification-setup';

  static Map<String, WidgetBuilder> getRoutes(SharedPreferences prefs) {
    return {
      login: (context) => const LoginPage(),
      quickLogin: (context) => const QuickLoginPage(),
      register: (context) => const RegisterPage(),
      home: (context) => const HomePage(),
      createAccount: (context) => const CreateAccountPage(),
      createTransaction: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        TransactionType? initialType;
        if (args is String) {
          initialType = TransactionType.fromJson(args);
        } else if (args is TransactionType) {
          initialType = args;
        }
        return CreateTransactionPage(initialType: initialType);
      },
      budgets: (context) => const BudgetsPage(),
      createBudget: (context) => const CreateBudgetPage(),
      goals: (context) => const GoalsPage(),
      createGoal: (context) => const CreateGoalPage(),
      aiInsights: (context) => const AIInsightsPage(),
      notifications: (context) => const NotificationsPage(),
      recurring: (context) => const RecurringTransactionsPage(),
      createRecurring: (context) => const CreateRecurringPage(),
      categories: (context) => const CategoriesPage(),
      bankNotificationSetup: (context) => const BankNotificationSetupPage(),
    };
  }
}

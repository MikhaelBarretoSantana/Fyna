import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/config/routes/app_routes.dart';
import 'package:fyna/core/themes/app_theme.dart';
import 'package:fyna/core/themes/theme_notifier.dart';
import 'package:fyna/feature/auth/presentation/pages/login.page.dart';
import 'package:fyna/feature/auth/presentation/pages/quick_login.page.dart';
import 'package:fyna/feature/onboarding/presentation/pages/welcome.page.dart';
import 'package:fyna/feature/onboarding/data/repositories/onboarding_repository.dart';

/// Notifier global acessível por qualquer tela.
final ThemeNotifier themeNotifier = ThemeNotifier();

void main() async {
  // Mantém a splash visível enquanto o app inicializa
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  final prefs = await SharedPreferences.getInstance();
  Injection.init(prefs);

  // Inicializa Firebase / FCM (no-op se credenciais não estiverem configuradas)
  await Injection.instance.fcmService.initialize();

  // Remove a splash após inicialização completa
  FlutterNativeSplash.remove();

  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, _) {
        return MaterialApp(
          title: 'Fyna',
          debugShowCheckedModeBanner: false,
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [
            Locale('pt', 'BR'),
            Locale('en', 'US'),
            Locale('es', 'ES'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeNotifier.themeMode,
          routes: AppRoutes.getRoutes(prefs),
          home: FutureBuilder<bool>(
            future: OnboardingRepository(prefs).isOnboardingCompleted(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final onboardingCompleted = snapshot.data ?? false;
              if (!onboardingCompleted) {
                return WelcomePage(
                    onboardingRepository: OnboardingRepository(prefs));
              }

              // Se já existe um usuário salvo, vai direto para o Quick Login
              final hasSavedUser =
                  (prefs.getString('user_login') ?? '').isNotEmpty;
              return hasSavedUser
                  ? const QuickLoginPage()
                  : const LoginPage();
            },
          ),
        );
      },
    );
  }
}

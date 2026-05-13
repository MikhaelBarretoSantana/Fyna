import 'package:shared_preferences/shared_preferences.dart';

class OnboardingRepository {
  static const String _onboardingKey = 'onboarding_completed';

  final SharedPreferences _prefs;

  OnboardingRepository(this._prefs);

  /// Verifica se o onboarding já foi completado
  Future<bool> isOnboardingCompleted() async {
    return _prefs.getBool(_onboardingKey) ?? false;
  }

  /// Marca o onboarding como completado
  Future<void> completeOnboarding() async {
    await _prefs.setBool(_onboardingKey, true);
  }

  /// Reseta o status do onboarding (útil para testes)
  Future<void> resetOnboarding() async {
    await _prefs.remove(_onboardingKey);
  }
}

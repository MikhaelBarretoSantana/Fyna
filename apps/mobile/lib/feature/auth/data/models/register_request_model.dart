class RegisterRequestModel {
  // Step 1 - Dados da Conta
  final String fullName;
  final String login;
  final String email;
  final String password;

  // Step 2 - Dados Pessoais
  final String? phone;
  final DateTime? birthDate;

  // Step 3 - Preferências
  final String currency;
  final String locale;
  final String timeZone;
  final String theme;
  final bool pushNotifications;
  final bool emailNotifications;
  final bool budgetAlerts;
  final bool weeklySummary;
  final bool aiSuggestions;

  const RegisterRequestModel({
    required this.fullName,
    required this.login,
    required this.email,
    required this.password,
    this.phone,
    this.birthDate,
    this.currency = 'BRL',
    this.locale = 'pt-BR',
    this.timeZone = 'America/Sao_Paulo',
    this.theme = 'SYSTEM',
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.budgetAlerts = true,
    this.weeklySummary = true,
    this.aiSuggestions = true,
  });

  RegisterRequestModel copyWith({
    String? fullName,
    String? login,
    String? email,
    String? password,
    String? phone,
    DateTime? birthDate,
    String? currency,
    String? locale,
    String? timeZone,
    String? theme,
    bool? pushNotifications,
    bool? emailNotifications,
    bool? budgetAlerts,
    bool? weeklySummary,
    bool? aiSuggestions,
  }) {
    return RegisterRequestModel(
      fullName: fullName ?? this.fullName,
      login: login ?? this.login,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      currency: currency ?? this.currency,
      locale: locale ?? this.locale,
      timeZone: timeZone ?? this.timeZone,
      theme: theme ?? this.theme,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      budgetAlerts: budgetAlerts ?? this.budgetAlerts,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      aiSuggestions: aiSuggestions ?? this.aiSuggestions,
    );
  }

  /// JSON enviado ao backend (apenas campos do RegisterRequest.java).
  /// Os campos de preferências são mantidos no modelo mas NÃO são
  /// enviados para /auth/register — serão salvos em outra rota futura.
  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'login': login,
      'email': email,
      'password': password,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (birthDate != null)
        'birthDate':
            '${birthDate!.year.toString().padLeft(4, '0')}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.day.toString().padLeft(2, '0')}',
    };
  }

  /// Retorna o mapa de preferências (para uso futuro em outra rota).
  Map<String, dynamic> preferencesToJson() {
    return {
      'currency': currency,
      'locale': locale,
      'timeZone': timeZone,
      'theme': theme,
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'budgetAlerts': budgetAlerts,
      'weeklySummary': weeklySummary,
      'aiSuggestions': aiSuggestions,
    };
  }
}

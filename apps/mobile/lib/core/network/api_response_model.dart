/// Espelho do `ApiResponse<T>` do backend Java.
///
/// ```json
/// {
///   "success": true,
///   "message": "Recurso criado com sucesso",
///   "data": { ... },
///   "timestamp": "2026-02-28T12:00:00Z"
/// }
/// ```
class ApiResponseModel<T> {
  final bool success;
  final String? message;
  final T? data;
  final String? timestamp;

  const ApiResponseModel({
    required this.success,
    this.message,
    this.data,
    this.timestamp,
  });

  /// Factory genérica — `fromDataJson` converte o campo `data` em `T`.
  factory ApiResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json)? fromDataJson,
  ) {
    return ApiResponseModel<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] != null && fromDataJson != null
          ? fromDataJson(json['data'] as Map<String, dynamic>)
          : null,
      timestamp: json['timestamp'] as String?,
    );
  }
}

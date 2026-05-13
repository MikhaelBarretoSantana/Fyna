/// Espelha o `PageResponse<T>` do backend Java.
///
/// ```json
/// {
///   "content": [ ... ],
///   "page": 0,
///   "size": 20,
///   "totalElements": 42,
///   "totalPages": 3,
///   "first": true,
///   "last": false
/// }
/// ```
class PageResponseModel<T> {
  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;

  const PageResponseModel({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
  });

  /// Factory genérica — `fromItemJson` converte cada item da lista em `T`.
  factory PageResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItemJson,
  ) {
    return PageResponseModel<T>(
      content: (json['content'] as List<dynamic>?)
              ?.map((e) => fromItemJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      page: json['page'] as int? ?? 0,
      size: json['size'] as int? ?? 20,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      first: json['first'] as bool? ?? true,
      last: json['last'] as bool? ?? true,
    );
  }

  /// Verifica se há mais páginas.
  bool get hasMore => !last;
}

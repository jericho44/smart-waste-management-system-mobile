/// Standardized API Response envelope matching Laravel backend.
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final ApiMeta? meta;
  final dynamic errors;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.meta,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      meta: json['meta'] != null && json['meta'] is Map<String, dynamic>
          ? ApiMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
      errors: json['errors'],
    );
  }
}

/// Metadata included in all API responses.
class ApiMeta {
  final String? requestId;
  final String? timestamp;
  final PaginationMeta? pagination;

  const ApiMeta({this.requestId, this.timestamp, this.pagination});

  factory ApiMeta.fromJson(Map<String, dynamic> json) {
    PaginationMeta? pagination;

    // Supports meta.pagination nesting or direct flat pagination properties
    if (json['pagination'] != null &&
        json['pagination'] is Map<String, dynamic>) {
      pagination = PaginationMeta.fromJson(
        json['pagination'] as Map<String, dynamic>,
      );
    } else if (json.containsKey('current_page') && json.containsKey('total')) {
      pagination = PaginationMeta.fromJson(json);
    }

    return ApiMeta(
      requestId: json['request_id'] as String?,
      timestamp: json['timestamp'] as String?,
      pagination: pagination,
    );
  }
}

/// Standardized pagination metadata matching Laravel ResourceCollection.
class PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int from;
  final int to;
  final bool hasNext;
  final bool hasPrevious;

  const PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.from,
    required this.to,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['current_page'] as int? ?? 1,
      lastPage: json['last_page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 10,
      total: json['total'] as int? ?? 0,
      from: json['from'] as int? ?? 0,
      to: json['to'] as int? ?? 0,
      hasNext: json['has_next'] as bool? ?? false,
      hasPrevious: json['has_previous'] as bool? ?? false,
    );
  }
}

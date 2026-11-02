import 'package:flutter_test/flutter_test.dart';
import 'package:smart_waste_mobile/app/config/app_config.dart';
import 'package:smart_waste_mobile/core/errors/app_exception.dart';
import 'package:smart_waste_mobile/core/network/api_endpoints.dart';
import 'package:smart_waste_mobile/shared/models/api_response.dart';

void main() {
  group('AppConfig Tests', () {
    test('Default configurations are properly loaded', () async {
      await AppConfig.initialize();
      expect(AppConfig.apiBaseUrl, isNotEmpty);
      expect(AppConfig.appName, equals('Smart Waste Mobile'));
      expect(AppConfig.connectTimeoutMs, equals(15000));
    });
  });

  group('ApiResponse Model Tests', () {
    test('Parses single success envelope correctly', () {
      final json = {
        'success': true,
        'message': 'Waste report retrieved successfully',
        'data': {
          'uuid': '0f81d1ef-19bb-4c22-b25f-f06b12d5d852',
          'title': 'Tumpukan Sampah Plastik',
          'status': 'PENDING',
        },
        'meta': {
          'request_id': '7b0d1822-0487-4aa7-b50a-b153e7f91ff3',
          'timestamp': '2026-11-02T19:40:00+07:00',
        },
        'errors': null,
      };

      final response = ApiResponse<Map<String, dynamic>>.fromJson(
        json,
        (data) => data as Map<String, dynamic>,
      );

      expect(response.success, isTrue);
      expect(response.message, equals('Waste report retrieved successfully'));
      expect(response.data?['title'], equals('Tumpukan Sampah Plastik'));
      expect(
        response.meta?.requestId,
        equals('7b0d1822-0487-4aa7-b50a-b153e7f91ff3'),
      );
    });

    test('Parses paginated envelope correctly', () {
      final json = {
        'success': true,
        'message': 'Data retrieved successfully',
        'data': [
          {'uuid': 'report-1'},
          {'uuid': 'report-2'},
        ],
        'meta': {
          'pagination': {
            'current_page': 1,
            'last_page': 5,
            'per_page': 10,
            'total': 48,
            'from': 1,
            'to': 10,
            'has_next': true,
            'has_previous': false,
          },
          'request_id': 'test-request-id',
          'timestamp': '2026-11-02T19:40:00+07:00',
        },
        'errors': null,
      };

      final response = ApiResponse<List<dynamic>>.fromJson(
        json,
        (data) => data as List<dynamic>,
      );

      expect(response.success, isTrue);
      expect(response.meta?.pagination?.currentPage, equals(1));
      expect(response.meta?.pagination?.lastPage, equals(5));
      expect(response.meta?.pagination?.total, equals(48));
      expect(response.meta?.pagination?.hasNext, isTrue);
      expect(response.meta?.pagination?.hasPrevious, isFalse);
    });
  });

  group('AppException Tests', () {
    test('ValidationException formats and extracts errors correctly', () {
      const exception = ValidationException(
        message: 'The given data was invalid.',
        errors: {
          'title': ['The title field is required.'],
          'category_uuid': ['The selected category uuid is invalid.'],
        },
        statusCode: 422,
      );

      expect(exception.statusCode, equals(422));
      expect(
        exception.firstErrorFor('title'),
        equals('The title field is required.'),
      );
      expect(
        exception.primaryErrorMessage,
        equals('The title field is required.'),
      );
    });

    test('UnauthorizedException has 401 status code', () {
      const exception = UnauthorizedException();
      expect(exception.statusCode, equals(401));
    });
  });

  group('ApiEndpoints Tests', () {
    test('Report endpoints generate valid routes', () {
      expect(ApiEndpoints.reports, equals('/reports'));
      expect(ApiEndpoints.reportDetails('abc-123'), equals('/reports/abc-123'));
      expect(
        ApiEndpoints.reportHistory('abc-123'),
        equals('/reports/abc-123/history'),
      );
      expect(
        ApiEndpoints.reportDeleteImage('abc-123', 'img-456'),
        equals('/reports/abc-123/images/img-456'),
      );
    });
  });
}

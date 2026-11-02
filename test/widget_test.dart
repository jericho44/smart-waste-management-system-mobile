import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_waste_mobile/app/app.dart';
import 'package:smart_waste_mobile/app/config/app_config.dart';
import 'package:smart_waste_mobile/core/storage/secure_storage_service.dart';

class MockSecureStorageService extends SecureStorageService {
  final bool mockHasToken;

  MockSecureStorageService({this.mockHasToken = false});

  @override
  Future<bool> hasToken() async => mockHasToken;

  @override
  Future<String?> getToken() async => mockHasToken ? 'mock_token' : null;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppConfig.initialize();
  });

  testWidgets('Smart Waste Mobile startup, splash and login route test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStorageServiceProvider.overrideWithValue(
            MockSecureStorageService(mockHasToken: false),
          ),
        ],
        child: const SmartWasteApp(),
      ),
    );

    // Verify that the splash screen shows the recycling icon and community message
    expect(find.byIcon(Icons.recycling_rounded), findsOneWidget);
    expect(find.text('Community Waste Monitoring Platform'), findsOneWidget);

    // Complete splash timer and transition
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify navigation landed on LoginScreen
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}

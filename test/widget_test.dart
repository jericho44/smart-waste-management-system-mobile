import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_waste_mobile/app/app.dart';
import 'package:smart_waste_mobile/app/config/app_config.dart';
import 'package:smart_waste_mobile/features/authentication/domain/models/authenticated_user.dart';
import 'package:smart_waste_mobile/features/authentication/presentation/state/auth_notifier.dart';
import 'package:smart_waste_mobile/features/authentication/presentation/state/auth_state.dart';

class FakeAuthNotifier extends AuthNotifier {
  final AuthState _targetState;

  FakeAuthNotifier(this._targetState);

  @override
  AuthState build() => AuthState.initial();

  @override
  Future<void> checkAuthStatus() async {
    await Future<void>.delayed(Duration.zero);
    state = _targetState;
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppConfig.initialize();
  });

  testWidgets('Unauthenticated startup: Splash navigates to LoginScreen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(AuthState.unauthenticated()),
          ),
        ],
        child: const SmartWasteApp(),
      ),
    );

    // Initial Splash Screen display
    expect(find.byIcon(Icons.recycling_rounded), findsOneWidget);
    expect(find.text('Community Waste Monitoring Platform'), findsOneWidget);

    // Complete splash delay
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Arrived at Login Screen
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Citizen User'), findsOneWidget);
  });

  testWidgets('Authenticated startup: Splash navigates to DashboardScreen', (
    WidgetTester tester,
  ) async {
    const citizen = AuthenticatedUser(
      uuid: 'citizen-uuid-1',
      name: 'Alex Johnson',
      email: 'alex@waste.local',
      roles: ['user'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(AuthState.authenticated(citizen)),
          ),
        ],
        child: const SmartWasteApp(),
      ),
    );

    // Advance splash
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Arrived at Dashboard Screen showing user greeting
    expect(find.textContaining('Hello, Alex Johnson'), findsOneWidget);
    expect(find.text('Found an illegal dump?'), findsOneWidget);
  });
}

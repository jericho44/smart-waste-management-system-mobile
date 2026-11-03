import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/authentication/presentation/screens/splash_screen.dart';
import '../../features/authentication/presentation/state/auth_notifier.dart';
import '../../features/authentication/presentation/state/auth_state.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/report_creation/presentation/screens/create_report_screen.dart';
import '../../features/reports/presentation/screens/report_details_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Listenable that triggers GoRouter route refresh whenever AuthState changes
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (previous?.status != next.status) {
        notifyListeners();
      }
    });
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

/// Central GoRouter configuration with protected route guards and bottom navigation
final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: routerNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authNotifierProvider);
      final location = state.matchedLocation;

      final isAuthRoute = location == '/login' || location == '/register';
      final isSplashRoute = location == '/splash';

      // 1. Initial boot: stay on splash
      if (authState.status == AuthStatus.initial) {
        return isSplashRoute ? null : '/splash';
      }

      // 2. Currently authenticating: allow in-flight process without redirecting
      if (authState.status == AuthStatus.authenticating) {
        return null;
      }

      // 3. Authenticated: if user is on splash, login, or register, redirect to dashboard
      if (authState.isAuthenticated) {
        if (isSplashRoute || isAuthRoute) {
          return '/dashboard';
        }
        return null;
      }

      // 4. Unauthenticated or Error:
      // Allow remaining on auth screens (login or register); redirect others to login
      if (isAuthRoute) {
        return null;
      }

      return '/login';
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Branch 1: Reports
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const ReportsScreen(),
                routes: [
                  GoRoute(
                    path: ':uuid',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final uuid = state.pathParameters['uuid']!;
                      return ReportDetailsScreen(uuid: uuid);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 2: Create Report
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports/create',
                builder: (context, state) => const CreateReportScreen(),
              ),
            ],
          ),
          // Branch 3: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

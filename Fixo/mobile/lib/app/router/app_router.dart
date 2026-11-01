import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/phone_auth_page.dart';
import '../../features/booking/presentation/pages/create_booking_page.dart';
import '../../features/customer_home/domain/marketplace_models.dart';
import '../../features/customer_home/presentation/pages/customer_home_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import 'app_routes.dart';

/// Listenable bridge that notifies `GoRouter` whenever `authControllerProvider`
/// authentication state changes.
class _AuthRouterRefreshNotifier extends ChangeNotifier {
  _AuthRouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(
      authControllerProvider,
      (previous, next) {
        if (previous?.isAuthenticated != next.isAuthenticated) {
          notifyListeners();
        }
      },
    );
  }
}

/// Provides the central `GoRouter` instance for the FIXO mobile app with
/// authentication redirects between `/onboarding`, `/auth/phone`, and `/customer/home`.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return createAppRouter(
    refreshListenable: refreshNotifier,
    isAuthenticated: () => ref.read(authControllerProvider).isAuthenticated,
  );
});

GoRouter createAppRouter({
  String initialLocation = AppRoutes.onboarding,
  Listenable? refreshListenable,
  bool Function()? isAuthenticated,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      if (isAuthenticated == null) {
        return null;
      }
      final authed = isAuthenticated();
      final path = state.uri.path;

      // Protect customer routes when unauthenticated
      if (!authed && path.startsWith('/customer')) {
        return AppRoutes.phoneAuth;
      }

      // Redirect authenticated users away from the login screen to Customer Home
      if (authed && path == AppRoutes.phoneAuth) {
        return AppRoutes.customerHome;
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.phoneAuth,
        name: 'phoneAuth',
        builder: (context, state) {
          final entryIntent = state.uri.queryParameters['intent'] ?? 'signup';
          return PhoneAuthPage(entryIntent: entryIntent);
        },
      ),
      GoRoute(
        path: AppRoutes.customerHome,
        name: 'customerHome',
        builder: (context, state) => const CustomerHomePage(),
      ),
      GoRoute(
        path: AppRoutes.createBooking,
        name: 'createBooking',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final offering = extra?['offering'] as ServiceOfferModel?;
          final preferredPro =
              extra?['preferredPro'] as ProfessionalCardModel?;
          return CreateBookingPage(
            initialOffering: offering,
            initialPreferredPro: preferredPro,
          );
        },
      ),
    ],
  );
}

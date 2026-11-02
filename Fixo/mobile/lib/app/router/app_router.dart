import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/phone_auth_page.dart';
import '../../features/auth/presentation/pages/email_auth_page.dart';
import '../../features/auth/presentation/pages/phone_password_page.dart';
import '../../features/chat/presentation/chat_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/booking/presentation/pages/create_booking_page.dart';
import '../../features/booking/presentation/pages/order_tracking_page.dart';
import '../../features/booking/presentation/pages/orders_page.dart';
import '../../features/booking/presentation/pages/review_page.dart';
import '../../features/customer_home/domain/marketplace_models.dart';
import '../../features/customer_home/presentation/pages/customer_home_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/payment/presentation/pages/checkout_page.dart';
import 'app_routes.dart';

/// Listenable bridge that notifies `GoRouter` whenever `authControllerProvider`
/// authentication state changes.
class _AuthRouterRefreshNotifier extends ChangeNotifier {
  _AuthRouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated ||
          previous?.session?.user.requiresProfileSetup !=
              next.session?.user.requiresProfileSetup) {
        notifyListeners();
      }
    });
  }
}

/// Provides the central `GoRouter` instance for the FIXO mobile app with
/// authentication redirects between `/onboarding`, `/auth/phone`, and `/customer/home`.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return createAppRouter(
    initialLocation: ref.read(authControllerProvider).isAuthenticated
        ? AppRoutes.customerHome
        : AppRoutes.onboarding,
    refreshListenable: refreshNotifier,
    isAuthenticated: () => ref.read(authControllerProvider).isAuthenticated,
    requiresProfileSetup: () =>
        ref.read(authControllerProvider).session?.user.requiresProfileSetup ==
        true,
  );
});

GoRouter createAppRouter({
  String initialLocation = AppRoutes.onboarding,
  Listenable? refreshListenable,
  bool Function()? isAuthenticated,
  bool Function()? requiresProfileSetup,
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
      final setupRequired = authed && requiresProfileSetup?.call() == true;
      if (setupRequired && path != AppRoutes.phoneAuth) {
        return AppRoutes.phoneAuth;
      }

      // Protect customer routes when unauthenticated
      if (!authed && path.startsWith('/customer')) {
        return AppRoutes.phoneAuth;
      }

      // Redirect authenticated users away from the login screen to Customer Home
      if (authed && !setupRequired && path == AppRoutes.phoneAuth) {
        return AppRoutes.customerHome;
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.myOrders,
        name: 'myOrders',
        builder: (_, state) {
          final chats = state.uri.queryParameters['view'] == 'chat';
          return OrdersPage(key: ValueKey(chats), showChats: chats);
        },
      ),
      GoRoute(
        path: AppRoutes.customerProfile,
        name: 'customerProfile',
        builder: (_, _) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.customerChat,
        name: 'customerChat',
        builder: (context, state) => ChatPage(
          key: ValueKey(state.pathParameters['orderId']),
          bookingId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.phoneAuth,
        name: 'phoneAuth',
        builder: (context, state) {
          if (state.uri.queryParameters['method'] == 'email' && !kReleaseMode) {
            return const EmailAuthPage();
          }
          if (!kReleaseMode &&
              state.uri.queryParameters['method'] == 'dev-otp') {
            return const PhoneAuthPage();
          }
          return const PhonePasswordPage();
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
          final preferredPro = extra?['preferredPro'] as ProfessionalCardModel?;
          return CreateBookingPage(
            initialOffering: offering,
            initialPreferredPro: preferredPro,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.checkout,
        name: 'checkout',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId'] ?? '';
          return CheckoutPage(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: AppRoutes.orderTracking,
        name: 'orderTracking',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return OrderTrackingPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: AppRoutes.rateReview,
        name: 'rateReview',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return ReviewPage(orderId: orderId);
        },
      ),
    ],
  );
}

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../../core/motion/fixo_motion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/controllers/account_entry_controller.dart';
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
import '../../features/pro/presentation/pages/incoming_job_page.dart';
import '../../features/pro/presentation/pages/pro_account_entry_page.dart';
import '../../features/pro/presentation/pages/pro_dashboard_page.dart';
import '../../features/pro/presentation/pages/pro_signup_page.dart';
import '../../features/pro/presentation/pages/pro_skills_page.dart';
import '../../features/pro/presentation/pages/pro_verification_docs_page.dart';
import '../../features/pro/presentation/pages/pro_verification_status_page.dart';
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
        ? (ref.read(professionalEntryProvider)
              ? AppRoutes.proEntry
              : AppRoutes.customerHome)
        : AppRoutes.onboarding,
    refreshListenable: refreshNotifier,
    professionalIntent: () => ref.read(professionalEntryProvider),
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
  bool Function()? professionalIntent,
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
      final account = state.uri.queryParameters['account'];
      final wantsPro = account == 'pro' || (account != 'customer' && (professionalIntent?.call() == true || path.startsWith('/pro')));
      final authPath =
          '${AppRoutes.phoneAuth}${wantsPro ? '?account=pro' : ''}';
      final setupRequired = authed && requiresProfileSetup?.call() == true;
      if (setupRequired && path != AppRoutes.phoneAuth) {
        return authPath;
      }

      // Protect customer and pro routes when unauthenticated
      if (!authed &&
          (path.startsWith('/customer') || path.startsWith('/pro'))) {
        return authPath;
      }

      // Redirect authenticated users away from the login screen to Customer Home
      if (authed && !setupRequired && path == AppRoutes.phoneAuth) {
        return wantsPro ? AppRoutes.proEntry : AppRoutes.customerHome;
      }

      return null;
    },
    routes: <RouteBase>[
      _motionRoute(
        path: AppRoutes.proEntry,
        name: 'proEntry',
        builder: (_, _) => const ProAccountEntryPage(),
      ),
      _motionRoute(
        path: AppRoutes.myOrders,
        name: 'myOrders',
        builder: (_, state) {
          final chats = state.uri.queryParameters['view'] == 'chat';
          return OrdersPage(key: ValueKey(chats), showChats: chats);
        },
      ),
      _motionRoute(
        path: AppRoutes.customerProfile,
        name: 'customerProfile',
        builder: (_, _) => const ProfilePage(),
      ),
      _motionRoute(
        path: AppRoutes.customerChat,
        name: 'customerChat',
        builder: (context, state) => ChatPage(
          key: ValueKey(state.pathParameters['orderId']),
          bookingId: state.pathParameters['orderId']!,
        ),
      ),
      _motionRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      _motionRoute(
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
          return PhonePasswordPage(
            professional: switch (state.uri.queryParameters['account']) {
              'pro' => true,
              'customer' => false,
              _ => null,
            },
          );
        },
      ),
      _motionRoute(
        path: AppRoutes.customerHome,
        name: 'customerHome',
        builder: (context, state) => const CustomerHomePage(),
      ),
      _motionRoute(
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
      _motionRoute(
        path: AppRoutes.checkout,
        name: 'checkout',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId'] ?? '';
          return CheckoutPage(bookingId: bookingId);
        },
      ),
      _motionRoute(
        path: AppRoutes.orderTracking,
        name: 'orderTracking',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return OrderTrackingPage(orderId: orderId);
        },
      ),
      _motionRoute(
        path: AppRoutes.rateReview,
        name: 'rateReview',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return ReviewPage(orderId: orderId);
        },
      ),
      _motionRoute(
        path: AppRoutes.proSignUp,
        name: 'proSignUp',
        builder: (context, state) => const ProSignUpPage(),
      ),
      _motionRoute(
        path: AppRoutes.proSkills,
        name: 'proSkills',
        builder: (context, state) => const ProSkillsPage(),
      ),
      _motionRoute(
        path: AppRoutes.proVerificationDocs,
        name: 'proVerificationDocs',
        builder: (context, state) => const ProVerificationDocsPage(),
      ),
      _motionRoute(
        path: AppRoutes.proVerificationStatus,
        name: 'proVerificationStatus',
        builder: (context, state) => const ProVerificationStatusPage(),
      ),
      _motionRoute(
        path: AppRoutes.proDashboard,
        name: 'proDashboard',
        builder: (context, state) => const ProDashboardPage(),
      ),
      _motionRoute(
        path: AppRoutes.incomingJobRequest,
        name: 'incomingJobRequest',
        builder: (context, state) {
          final jobId = state.pathParameters['jobId'] ?? '';
          return IncomingJobPage(jobOfferId: jobId);
        },
      ),
    ],
  );
}

GoRoute _motionRoute({
  required String path,
  required String name,
  required Widget Function(BuildContext, GoRouterState) builder,
}) => GoRoute(
  path: path,
  name: name,
  pageBuilder: (context, state) => CustomTransitionPage<void>(
    key: state.pageKey,
    name: state.name,
    restorationId: state.pageKey.value,
    transitionDuration: FixoMotion.reduced(context)
        ? Duration.zero
        : FixoMotion.page,
    reverseTransitionDuration: FixoMotion.reduced(context)
        ? Duration.zero
        : FixoMotion.page,
    child: builder(context, state),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FixoPageMotion(
          animation: animation,
          slide: !const [
            AppRoutes.customerHome,
            AppRoutes.myOrders,
            AppRoutes.customerProfile,
            AppRoutes.proDashboard,
          ].contains(path),
          child: child,
        ),
  ),
);

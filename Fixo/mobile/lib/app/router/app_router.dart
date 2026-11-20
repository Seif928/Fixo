import '../../core/theme/fixo_workspace_theme.dart';
import '../../features/support/support_page.dart' deferred as support_page;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../../core/motion/fixo_motion.dart';
import '../../core/widgets/deferred_route_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/controllers/account_entry_controller.dart';
import '../../features/auth/presentation/pages/phone_auth_page.dart';
import '../../features/auth/presentation/pages/email_auth_page.dart';
import '../../features/auth/presentation/pages/phone_password_page.dart';
import '../../features/auth/presentation/pages/logout_page.dart'
    deferred as logout_page;
import '../../features/chat/presentation/chat_page.dart' deferred as chat_page;
import '../../features/profile/presentation/profile_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart'
    deferred as favorites_page;
import '../../features/complaints/presentation/pages/my_complaints_page.dart'
    deferred as my_complaints_page;
import '../../features/admin/presentation/admin_page.dart'
    deferred as admin_page;
import '../../features/booking/presentation/pages/create_booking_page.dart'
    deferred as create_booking_page;
import '../../features/booking/presentation/pages/order_tracking_page.dart'
    deferred as order_tracking_page;
import '../../features/booking/presentation/pages/orders_page.dart';
import '../../features/booking/presentation/pages/review_page.dart'
    deferred as review_page;
import '../../features/customer_home/domain/marketplace_models.dart';
import '../../features/customer_home/presentation/pages/customer_home_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/payment/presentation/pages/checkout_page.dart'
    deferred as checkout_page;
import '../../features/pro/presentation/pages/incoming_job_page.dart'
    deferred as incoming_job_page;
import '../../features/pro/presentation/pages/pro_account_entry_page.dart'
    deferred as pro_account_entry_page;
import '../../features/pro/presentation/pages/pro_dashboard_page.dart'
    deferred as pro_dashboard_page;
import '../../features/pro/presentation/pages/pro_signup_page.dart'
    deferred as pro_signup_page;
import '../../features/pro/presentation/pages/pro_skills_page.dart'
    deferred as pro_skills_page;
import '../../features/pro/presentation/pages/pro_verification_docs_page.dart'
    deferred as pro_verification_docs_page;
import '../../features/pro/presentation/pages/pro_verification_status_page.dart'
    deferred as pro_verification_status_page;
import '../../features/pro/presentation/pages/pro_schedule_page.dart'
    deferred as pro_schedule_page;
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
      final wantsPro =
          account == 'pro' ||
          (account != 'customer' &&
              (professionalIntent?.call() == true || path.startsWith('/pro')));
      final authPath =
          '${AppRoutes.phoneAuth}${wantsPro ? '?account=pro' : ''}';
      if (path == '/' || path.isEmpty) {
        if (!authed) return AppRoutes.onboarding;
        return wantsPro ? AppRoutes.proEntry : AppRoutes.customerHome;
      }
      final setupRequired = authed && requiresProfileSetup?.call() == true;
      if (setupRequired && path != AppRoutes.phoneAuth) {
        return authPath;
      }

      // Protect customer and pro routes when unauthenticated
      if (!authed &&
          (path.startsWith('/customer') ||
              path.startsWith('/pro') ||
              path.startsWith('/admin') ||
              path.startsWith('/support'))) {
        return authPath;
      }

      // Redirect authenticated users away from the login and onboarding screens to Customer Home
      if (authed &&
          !setupRequired &&
          (path == AppRoutes.phoneAuth || path == AppRoutes.onboarding)) {
        return wantsPro ? AppRoutes.proEntry : AppRoutes.customerHome;
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(path: '/login', redirect: (_, _) => AppRoutes.phoneAuth),
      GoRoute(path: '/register', redirect: (_, _) => AppRoutes.phoneAuth),
      GoRoute(path: '/dashboard', redirect: (_, _) => AppRoutes.customerHome),
      GoRoute(path: '/bookings', redirect: (_, _) => AppRoutes.myOrders),
      GoRoute(path: '/profile', redirect: (_, _) => AppRoutes.customerProfile),
      GoRoute(path: '/', redirect: (_, _) => initialLocation),
      _motionRoute(
        path: AppRoutes.admin,
        name: 'admin',
        builder: (_, _) => DeferredRouteView(
          loadLibrary: admin_page.loadLibrary,
          builder: (_) => admin_page.AdminPage(),
        ),
      ),
      _motionRoute(
        path: AppRoutes.proEntry,
        name: 'proEntry',
        builder: (_, _) => DeferredRouteView(
          loadLibrary: pro_account_entry_page.loadLibrary,
          builder: (_) => pro_account_entry_page.ProAccountEntryPage(),
        ),
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
        path: '/support',
        name: 'support',
        builder: (_, _) => DeferredRouteView(
          loadLibrary: support_page.loadLibrary,
          builder: (_) => support_page.SupportPage(),
        ),
      ),
      _motionRoute(
        path: '/admin/support',
        name: 'adminSupport',
        builder: (_, _) => DeferredRouteView(
          loadLibrary: support_page.loadLibrary,
          builder: (_) => support_page.SupportPage(admin: true),
        ),
      ),
      _motionRoute(
        path: AppRoutes.logout,
        name: 'logout',
        builder: (_, _) => DeferredRouteView(
          loadLibrary: logout_page.loadLibrary,
          builder: (_) => logout_page.LogoutPage(),
        ),
      ),
      _motionRoute(
        path: AppRoutes.favorites,
        name: 'favorites',
        builder: (_, _) => DeferredRouteView(
          loadLibrary: favorites_page.loadLibrary,
          builder: (_) => favorites_page.FavoritesPage(),
        ),
      ),
      _motionRoute(
        path: AppRoutes.myComplaints,
        name: 'myComplaints',
        builder: (_, _) => DeferredRouteView(
          loadLibrary: my_complaints_page.loadLibrary,
          builder: (_) => my_complaints_page.MyComplaintsPage(),
        ),
      ),
      _motionRoute(
        path: AppRoutes.customerChat,
        name: 'customerChat',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return DeferredRouteView(
            key: ValueKey(orderId),
            loadLibrary: chat_page.loadLibrary,
            builder: (_) => chat_page.ChatPage(bookingId: orderId),
          );
        },
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
          final isPro = switch (state.uri.queryParameters['account']) {
            'pro' => true,
            'customer' => false,
            _ => null,
          };
          if (state.uri.queryParameters['method'] == 'email') {
            return EmailAuthPage(professional: isPro);
          }
          if (!kReleaseMode &&
              state.uri.queryParameters['method'] == 'dev-otp') {
            return const PhoneAuthPage();
          }
          return PhonePasswordPage(professional: isPro);
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
          return DeferredRouteView(
            loadLibrary: create_booking_page.loadLibrary,
            builder: (_) => create_booking_page.CreateBookingPage(
              initialOffering: offering,
              initialPreferredPro: preferredPro,
            ),
          );
        },
      ),
      _motionRoute(
        path: AppRoutes.checkout,
        name: 'checkout',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId'] ?? '';
          return DeferredRouteView(
            loadLibrary: checkout_page.loadLibrary,
            builder: (_) => checkout_page.CheckoutPage(bookingId: bookingId),
          );
        },
      ),
      _motionRoute(
        path: AppRoutes.orderTracking,
        name: 'orderTracking',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return DeferredRouteView(
            loadLibrary: order_tracking_page.loadLibrary,
            builder: (_) => order_tracking_page.OrderTrackingPage(orderId: orderId),
          );
        },
      ),
      _motionRoute(
        path: AppRoutes.rateReview,
        name: 'rateReview',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return DeferredRouteView(
            loadLibrary: review_page.loadLibrary,
            builder: (_) => review_page.ReviewPage(orderId: orderId),
          );
        },
      ),
      _motionRoute(
        path: AppRoutes.proSignUp,
        name: 'proSignUp',
        builder: (context, state) => DeferredRouteView(
          loadLibrary: pro_signup_page.loadLibrary,
          builder: (_) => pro_signup_page.ProSignUpPage(),
        ),
      ),
      _motionRoute(
        path: AppRoutes.proSkills,
        name: 'proSkills',
        builder: (context, state) => DeferredRouteView(
          loadLibrary: pro_skills_page.loadLibrary,
          builder: (_) => pro_skills_page.ProSkillsPage(),
        ),
      ),
      _motionRoute(
        path: AppRoutes.proVerificationDocs,
        name: 'proVerificationDocs',
        builder: (context, state) => DeferredRouteView(
          loadLibrary: pro_verification_docs_page.loadLibrary,
          builder: (_) => pro_verification_docs_page.ProVerificationDocsPage(),
        ),
      ),
      _motionRoute(
        path: AppRoutes.proVerificationStatus,
        name: 'proVerificationStatus',
        builder: (context, state) => DeferredRouteView(
          loadLibrary: pro_verification_status_page.loadLibrary,
          builder: (_) =>
              pro_verification_status_page.ProVerificationStatusPage(),
        ),
      ),
      _motionRoute(
        path: AppRoutes.proDashboard,
        name: 'proDashboard',
        builder: (context, state) => DeferredRouteView(
          loadLibrary: pro_dashboard_page.loadLibrary,
          builder: (_) => pro_dashboard_page.ProDashboardPage(),
        ),
      ),
      _motionRoute(
        path: AppRoutes.proSchedule,
        name: 'proSchedule',
        builder: (context, state) => DeferredRouteView(
          loadLibrary: pro_schedule_page.loadLibrary,
          builder: (_) => pro_schedule_page.ProSchedulePage(),
        ),
      ),
      _motionRoute(
        path: AppRoutes.incomingJobRequest,
        name: 'incomingJobRequest',
        builder: (context, state) {
          final jobId = state.pathParameters['jobId'] ?? '';
          return DeferredRouteView(
            loadLibrary: incoming_job_page.loadLibrary,
            builder: (_) =>
                incoming_job_page.IncomingJobPage(jobOfferId: jobId),
          );
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
    child: FixoWorkspaceTheme(
      workspace: FixoWorkspace.forPath(state.uri.path),
      child: builder(context, state),
    ),
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

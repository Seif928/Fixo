import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fixo_mobile/app/router/customer_tab_navigation.dart';
import 'package:fixo_mobile/core/network/dio_client.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/booking/data/booking_repository.dart';
import 'package:fixo_mobile/features/booking/domain/booking_models.dart';
import 'package:fixo_mobile/features/booking/presentation/pages/orders_page.dart';
import 'package:fixo_mobile/features/customer_home/presentation/widgets/customer_home_widgets.dart';
import 'package:fixo_mobile/features/profile/presentation/profile_page.dart';

class _Bookings extends BookingRepository {
  _Bookings() : super(Dio());
  final queries = <String?>[];
  @override Future<List<BookingDetailModel>> getBookings({String? tab, String? status, int limit = 20, int offset = 0}) async {
    queries.add(tab);
    return [];
  }
}
class _Home extends StatefulWidget {
  const _Home();
  @override State<_Home> createState() => _HomeState();
}
class _HomeState extends State<_Home> {
  int counter = 0;
  @override Widget build(BuildContext context) => Scaffold(
    body: TextButton(onPressed: () => setState(() => counter++), child: Text('Home state $counter')),
    bottomNavigationBar: FixoCustomerBottomNav(currentIndex: 0, isArabic: false, onTabSelected: (index) => navigateCustomerTab(context, index)),
  );
}

void main() {
  testWidgets('peer tabs select the correct route and back preserves Home state', (tester) async {
    final bookings = _Bookings();
    final dio = Dio()..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) => handler.resolve(
      Response(requestOptions: options, statusCode: 200, data: {'id': 'TEST_ONLY', 'fullName': 'Local Test', 'role': 'CUSTOMER', 'addresses': [], 'arrivalAlertsEnabled': true}))));
    final router = GoRouter(initialLocation: '/customer/home', routes: [
      GoRoute(path: '/customer/home', builder: (_, _) => const _Home()),
      GoRoute(path: '/customer/orders', builder: (_, state) {
        final chats = state.uri.queryParameters['view'] == 'chat';
        return OrdersPage(key: ValueKey(chats), showChats: chats);
      }),
      GoRoute(path: '/customer/profile', builder: (_, _) => const ProfilePage()),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(overrides: [bookingRepositoryProvider.overrideWithValue(bookings), dioClientProvider.overrideWithValue(dio)],
      child: MaterialApp.router(theme: FixoTheme.light(), routerConfig: router)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home state 0')); await tester.pump();
    await tester.tap(find.byKey(const Key('nav-tab-orders'))); await tester.pumpAndSettle();
    expect(GoRouterState.of(tester.element(find.byType(OrdersPage))).uri.path, '/customer/orders');
    expect(find.text('No bookings in this list.'), findsOneWidget);
    expect(tester.widget<FixoCustomerBottomNav>(find.byType(FixoCustomerBottomNav)).currentIndex, 1);
    await tester.tap(find.byKey(const Key('nav-tab-chat'))); await tester.pumpAndSettle();
    expect(GoRouterState.of(tester.element(find.byType(OrdersPage))).uri.queryParameters['view'], 'chat');
    expect(find.text('No conversations available yet.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('nav-tab-profile'))); await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-tab-orders'))); await tester.pumpAndSettle();
    expect(GoRouterState.of(tester.element(find.byType(OrdersPage))).uri.path, '/customer/orders');
    expect(GoRouterState.of(tester.element(find.byType(OrdersPage))).uri.queryParameters.containsKey('view'), false);
    await tester.tap(find.byKey(const Key('nav-tab-home'))); await tester.pumpAndSettle();
    expect(find.text('Home state 1'), findsOneWidget);
    expect(router.canPop(), false);
    expect(bookings.queries, containsAll(['active', null]));
    expect(tester.takeException(), isNull);
  });
}

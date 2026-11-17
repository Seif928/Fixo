import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';

/// Replace peer tabs while keeping the Home page underneath for back/scroll state.
void navigateCustomerTab(BuildContext context, int index) {
  final router = GoRouter.of(context);
  final current = GoRouterState.of(context).uri;
  final target = switch (index) {
    0 => AppRoutes.customerHome,
    1 => AppRoutes.myOrders,
    2 => '${AppRoutes.myOrders}?view=chat',
    3 => AppRoutes.customerProfile,
    _ => throw ArgumentError.value(index, 'index'),
  };
  if (current.toString() == target) return;
  if (index == 0) {
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(target);
    }
  } else if (current.path == AppRoutes.customerHome) {
    router.push(target);
  } else {
    router.pushReplacement(target);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/features/payment/presentation/controllers/checkout_controller.dart';
import 'package:fixo_mobile/features/payment/presentation/widgets/checkout_widgets.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'phase4_checkout_flow_test.dart' show FakeCheckoutBookingRepository;

void main() {
  test('checkout cannot submit an unsupported payment override', () async {
    final repository = FakeCheckoutBookingRepository();
    final controller = CheckoutController(
      bookingId: 'fixture',
      repository: repository,
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);
    final result = await controller.submitCheckout(
      overrideMethod: 'CARD_MEEZA_SANDBOX',
    );
    expect(result, isFalse);
    expect(repository.checkoutCallCount, 0);
  });
  testWidgets(
    'checkout never collects card data or claims biometric authorization',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FixoTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(child: CheckoutPaymentMethodsSection()),
          ),
        ),
      );
      expect(find.byType(TextField), findsNothing);
      expect(find.textContaining('3D Secure'), findsNothing);
      expect(find.textContaining('Face ID'), findsNothing);
      expect(find.textContaining('بيومتري'), findsNothing);
    },
  );
}

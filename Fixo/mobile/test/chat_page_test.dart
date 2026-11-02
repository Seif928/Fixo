import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/booking/data/booking_repository.dart';
import 'package:fixo_mobile/features/booking/domain/booking_models.dart';
import 'package:fixo_mobile/features/chat/data/communications_repository.dart';
import 'package:fixo_mobile/features/chat/presentation/chat_page.dart';

class LocalBookingRepository extends BookingRepository {
  LocalBookingRepository() : super(Dio());
  @override
  Future<BookingDetailModel> getBookingById(String id) async =>
      BookingDetailModel(
        id: id,
        orderCode: 'LOCAL-TEST',
        customerId: 'customer',
        offeringId: 'offering',
        addressId: 'address',
        status: 'PENDING_DISPATCH',
        scheduledDate: '2026-11-02',
        timeWindow: 'AFTERNOON_13_16',
        pricing: const BookingPricingModel(
          baseInspectionEgp: 150,
          serviceFeeEgp: 200,
          transportFeeEgp: 0,
          totalEgp: 350,
        ),
        createdAt: '2026-11-01T10:00:00Z',
        offering: const {
          'titleEn': 'Local test service',
          'titleAr': 'خدمة اختبار',
        },
      );
}

class LocalCommunications extends CommunicationsRepository {
  LocalCommunications() : super(Dio());
  @override
  Future<MessagePage> messages(String bookingId, {String? before}) async =>
      const MessagePage([], null);
}

void main() {
  for (final width in [360.0, 390.0, 412.0]) {
    testWidgets(
      'unassigned booking stays honest and read-only at $width with large text',
      (tester) async {
        tester.view.resetPhysicalSize();
        tester.view.physicalSize = Size(width, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              bookingRepositoryProvider.overrideWithValue(
                LocalBookingRepository(),
              ),
              communicationsRepositoryProvider.overrideWithValue(
                LocalCommunications(),
              ),
            ],
            child: MaterialApp(
              theme: FixoTheme.light(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.35)),
                child: child!,
              ),
              home: const ChatPage(bookingId: 'booking'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('No professional assigned yet'), findsOneWidget);
        expect(find.text('Hassan'), findsNothing);
        expect(
          tester
              .widget<IconButton>(find.byKey(const Key('send-chat-message')))
              .onPressed,
          isNull,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 11));
        expect(tester.takeException(), isNull);
      },
    );
  }
}

import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:fixo_mobile/core/uploads/device_media_picker.dart';
import 'package:fixo_mobile/features/auth/domain/auth_models.dart';
import 'package:fixo_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/booking/data/booking_repository.dart';
import 'package:fixo_mobile/features/booking/domain/booking_models.dart';
import 'package:fixo_mobile/features/chat/data/communications_repository.dart';
import 'package:fixo_mobile/features/chat/presentation/chat_page.dart';

class LocalBookingRepository extends BookingRepository {
  LocalBookingRepository({this.active = false}) : super(Dio());
  final bool active;
  @override
  Future<BookingDetailModel> getBookingById(String id) async =>
      BookingDetailModel(
        id: id,
        orderCode: 'LOCAL-TEST',
        customerId: 'customer',
        offeringId: 'offering',
        addressId: 'address',
        status: active ? 'CONFIRMED' : 'PENDING_DISPATCH',
        proProfileId: active ? 'pro' : null,
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

class PhotoAuth extends AuthController {
  @override
  AuthState build() => const AuthState(
    session: AuthSession(
      accessToken: 'fixture',
      refreshToken: 'fixture',
      user: AuthUser(
        id: 'customer',
        phone: '',
        fullName: 'Fixture',
        role: 'CUSTOMER',
      ),
    ),
  );
}

final photoBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+sDj8AAAAASUVORK5CYII=',
);

class PhotoPicker extends DeviceMediaPicker {
  @override
  Future<PickedPrivateMedia?> pickFor(
    ImageSource source, {
    required String scope,
  }) async => PickedPrivateMedia(
    fileName: 'photo.png',
    mimeType: 'image/png',
    contentBase64: base64Encode(photoBytes),
    sourceLabelEn: 'Gallery',
    sourceLabelAr: 'الصور',
  );
}

class PhotoCommunications extends LocalCommunications {
  int sends = 0, reads = 0;
  @override
  Future<ChatMessageModel> sendPhoto(
    String bookingId,
    PickedPrivateMedia photo,
  ) async {
    sends++;
    return ChatMessageModel(
      id: 'photo1',
      senderUserId: 'customer',
      body: '',
      hasAttachment: true,
      createdAt: DateTime(2026, 11, 10),
    );
  }

  @override
  Future<Uint8List> photo(String bookingId, String messageId) async {
    reads++;
    return photoBytes;
  }
}

class LocalCommunications extends CommunicationsRepository {
  LocalCommunications() : super(Dio());
  @override
  Future<MessagePage> messages(String bookingId, {String? before}) async =>
      const MessagePage([], null);
}

void main() {
  testWidgets(
    'photo selection requires confirmation and then displays authenticated bytes',
    (tester) async {
      final communications = PhotoCommunications();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(PhotoAuth.new),
            bookingRepositoryProvider.overrideWithValue(
              LocalBookingRepository(active: true),
            ),
            communicationsRepositoryProvider.overrideWithValue(communications),
            deviceMediaPickerProvider.overrideWithValue(PhotoPicker()),
          ],
          child: MaterialApp(
            theme: FixoTheme.light(),
            home: const ChatPage(bookingId: 'booking'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('attach-chat-photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Photo library'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Send photo?'), findsOneWidget);
      expect(communications.sends, 0);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(communications.sends, 0);
      await tester.tap(find.byKey(const Key('attach-chat-photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Photo library'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.widgetWithText(FilledButton, 'Send'));
      await tester.pumpAndSettle();
      expect(communications.sends, 1);
      expect(communications.reads, 1);
      expect(
        find.bySemanticsLabel('Private conversation photo'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 11));
    },
  );
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
        expect(
          tester
              .widget<IconButton>(find.byKey(const Key('attach-chat-photo')))
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

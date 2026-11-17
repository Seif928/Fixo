import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../customer_home/domain/marketplace_models.dart';
import '../domain/booking_models.dart';

/// Central repository for Customer Bookings and Address management.
class BookingRepository {
  const BookingRepository(this._dio);

  final Dio _dio;

  /// Creates a customer booking in DRAFT status via `POST /api/v1/bookings`.
  Future<BookingDetailModel> createBooking(CreateBookingRequest request) async {
    final response = await _dio.post(
      '/bookings',
      data: request.toJson(),
    );

    final data = response.data as Map<String, dynamic>;
    return BookingDetailModel.fromJson(data);
  }

  /// Lists customer bookings filtered by tab or status via `GET /api/v1/bookings`.
  Future<List<BookingDetailModel>> getBookings({
    String? tab,
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParameters = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (tab != null && tab.isNotEmpty) {
      queryParameters['tab'] = tab;
    }
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }

    final response = await _dio.get(
      '/bookings',
      queryParameters: queryParameters,
    );

    final data = response.data as Map<String, dynamic>;
    final list = data['bookings'] as List<dynamic>? ?? const [];
    return list
        .map((item) => BookingDetailModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves a specific booking detail via `GET /api/v1/bookings/:id`.
  Future<BookingDetailModel> getBookingById(String bookingId) async {
    final response = await _dio.get('/bookings/$bookingId');
    final data = response.data as Map<String, dynamic>;
    return BookingDetailModel.fromJson(data);
  }

  /// Confirms checkout for a booking via `POST /api/v1/bookings/:bookingId/checkout`.
  /// Submits `{"paymentMethod": "CASH_ON_SERVICE"}` for Cash on Service payment.
  Future<BookingDetailModel> checkoutBooking(
    String bookingId, {
    String paymentMethod = 'CASH_ON_SERVICE',
  }) async {
    final response = await _dio.post(
      '/bookings/$bookingId/checkout',
      data: {'paymentMethod': paymentMethod},
    );
    final data = response.data as Map<String, dynamic>;
    return BookingDetailModel.fromJson(data);
  }

  /// Persists a new customer delivery address via `POST /api/v1/users/me/addresses`.
  Future<CustomerAddressModel> createAddress(CreateAddressRequest request) async {
    final response = await _dio.post(
      '/users/me/addresses',
      data: request.toJson(),
    );
    final data = response.data as Map<String, dynamic>;
    final addressData = data['address'] as Map<String, dynamic>? ?? data;
    return CustomerAddressModel.fromJson(addressData);
  }

  /// Retrieves the authenticated customer's saved addresses via `GET /api/v1/users/me/addresses`.
  /// Only falls back to legacy `GET /users/me` if `/users/me/addresses` is not found (HTTP 404)
  /// on older backend revisions. Preserves and propagates authentication failures (401/403),
  /// server errors (500), and network connection errors without masking.
  Future<List<CustomerAddressModel>> getCustomerAddresses() async {
    try {
      final response = await _dio.get('/users/me/addresses');
      final data = response.data as Map<String, dynamic>;
      final rawList = data['addresses'] as List<dynamic>? ?? const [];
      return rawList
          .map((item) =>
              CustomerAddressModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final response = await _dio.get('/users/me');
        final data = response.data as Map<String, dynamic>;
        final user = data['user'] as Map<String, dynamic>? ?? const {};
        final rawAddresses = user['addresses'] as List<dynamic>? ?? const [];

        return rawAddresses
            .map((item) =>
                CustomerAddressModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      rethrow;
    }
  }

  /// Retrieves active coverage zones from `GET /api/v1/services/categories`.
  Future<List<CoverageZoneModel>> getCoverageZones() async {
    final response = await _dio.get('/services/categories');
    final data = response.data as Map<String, dynamic>;
    final rawZones = data['zones'] as List<dynamic>? ?? const [];
    return rawZones
        .map((item) =>
            CoverageZoneModel.fromJson(item as Map<String, dynamic>))
        .where((z) => z.isActive)
        .toList();
  }

  /// Retrieves live tracking state & milestones for Screen 06 via `GET /api/v1/bookings/:bookingId/tracking`.
  Future<BookingTrackingModel> getBookingTracking(String bookingId) async {
    final response = await _dio.get('/bookings/$bookingId/tracking');
    final data = response.data as Map<String, dynamic>;
    return BookingTrackingModel.fromJson(data);
  }

  /// Cancels a pre-service booking via `POST /api/v1/bookings/:bookingId/cancel`.
  Future<BookingDetailModel> cancelBooking(
    String bookingId, {
    String? reason,
  }) async {
    final response = await _dio.post(
      '/bookings/$bookingId/cancel',
      data: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    final data = response.data as Map<String, dynamic>;
    return BookingDetailModel.fromJson(data);
  }

  /// Retrieves the structured booking receipt via `GET /api/v1/bookings/:bookingId/receipt`.
  Future<BookingReceiptModel> getBookingReceipt(String bookingId) async {
    final response = await _dio.get('/bookings/$bookingId/receipt');
    final data = response.data as Map<String, dynamic>;
    return BookingReceiptModel.fromJson(data);
  }

  /// Retrieves the customer review for a booking via `GET /api/v1/bookings/:bookingId/review`.
  Future<BookingReviewModel?> getBookingReview(String bookingId) async {
    final response = await _dio.get('/bookings/$bookingId/review');
    final data = response.data as Map<String, dynamic>;
    final reviewMap = data['review'] as Map<String, dynamic>?;
    if (reviewMap == null) return null;
    return BookingReviewModel.fromJson(reviewMap);
  }

  /// Submits a customer review for a COMPLETED booking via `POST /api/v1/bookings/:bookingId/review`.
  Future<BookingReviewModel> submitBookingReview(
    String bookingId, {
    required int rating,
    List<String> tags = const [],
    String? comment,
    List<String> photoUrls = const [],
    int tipAmountEgp = 0,
  }) async {
    final response = await _dio.post(
      '/bookings/$bookingId/review',
      data: {
        'rating': rating,
        'tags': tags,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
        if (photoUrls.isNotEmpty) 'photoUrls': photoUrls,
        'tipAmountEgp': tipAmountEgp,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return BookingReviewModel.fromJson(data);
  }

  /// Uploads and validates private media via `POST /api/v1/uploads/private`.
  Future<PrivateUploadResultModel> uploadPrivateMedia({
    required String purpose,
    required String fileName,
    required String mimeType,
    required String contentBase64,
    String? bookingId,
  }) async {
    final response = await _dio.post(
      '/uploads/private',
      data: {
        'purpose': purpose,
        'fileName': fileName,
        'mimeType': mimeType,
        'contentBase64': contentBase64,
        if (bookingId != null && bookingId.isNotEmpty) 'bookingId': bookingId,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return PrivateUploadResultModel.fromJson(data);
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return BookingRepository(dio);
});


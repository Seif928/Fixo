import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/booking_models.dart';

/// Central repository for Customer Bookings and Address retrieval.
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

  /// Retrieves the authenticated customer's saved addresses via `GET /api/v1/users/me`.
  Future<List<CustomerAddressModel>> getCustomerAddresses() async {
    final response = await _dio.get('/users/me');
    final data = response.data as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>? ?? const {};
    final rawAddresses = user['addresses'] as List<dynamic>? ?? const [];

    return rawAddresses
        .map((item) =>
            CustomerAddressModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return BookingRepository(dio);
});


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
  /// Falls back to `/users/me` for backwards compatibility.
  Future<List<CustomerAddressModel>> getCustomerAddresses() async {
    try {
      final response = await _dio.get('/users/me/addresses');
      final data = response.data as Map<String, dynamic>;
      final rawList = data['addresses'] as List<dynamic>? ?? const [];
      return rawList
          .map((item) =>
              CustomerAddressModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Fallback to GET /users/me
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
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return BookingRepository(dio);
});


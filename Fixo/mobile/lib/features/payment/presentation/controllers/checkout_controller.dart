import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../booking/data/booking_repository.dart';
import '../../../booking/domain/booking_models.dart';

/// Immutable state for Screen 05 (CheckoutPage).
class CheckoutState {
  const CheckoutState({
    this.isLoading = true,
    this.isSubmitting = false,
    this.errorMessage,
    this.booking,
    this.selectedPaymentMethod = 'CASH_ON_SERVICE',
    this.checkoutSuccess = false,
  });

  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final BookingDetailModel? booking;
  final String selectedPaymentMethod;
  final bool checkoutSuccess;

  CheckoutState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    BookingDetailModel? booking,
    String? selectedPaymentMethod,
    bool? checkoutSuccess,
  }) {
    return CheckoutState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      booking: booking ?? this.booking,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      checkoutSuccess: checkoutSuccess ?? this.checkoutSuccess,
    );
  }
}

/// StateNotifier managing checkout state machine, duplicate prevention, and API operations.
class CheckoutController extends StateNotifier<CheckoutState> {
  CheckoutController({required this.bookingId, required this.repository})
    : super(const CheckoutState()) {
    loadBooking();
  }

  final String bookingId;
  final BookingRepository repository;

  /// Loads the real booking details from `GET /api/v1/bookings/:id`.
  /// If the booking was already checked out (status PENDING_DISPATCH with cash payment),
  /// immediately renders the confirmed state.
  Future<void> loadBooking() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final booking = await repository.getBookingById(bookingId);

      // Check if this booking is already checked out (idempotent reopening)
      final isAlreadyCheckedOut =
          booking.status == 'PENDING_DISPATCH' &&
          booking.payment?.method == 'CASH_ON_SERVICE' &&
          booking.payment?.status == 'PENDING';

      state = state.copyWith(
        isLoading: false,
        booking: booking,
        selectedPaymentMethod:
            booking.payment?.method ?? state.selectedPaymentMethod,
        checkoutSuccess: isAlreadyCheckedOut,
        errorMessage: null,
      );
    } on FormatException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message.isNotEmpty
            ? e.message
            : 'Invalid booking pricing data received.',
      );
    } on DioException catch (e) {
      final errorMsg = _mapDioError(e);
      state = state.copyWith(isLoading: false, errorMessage: errorMsg);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Only verified cash-on-service checkout is available.
  void selectPaymentMethod(String method) {
    if (state.isSubmitting ||
        state.checkoutSuccess ||
        method != 'CASH_ON_SERVICE') {
      return;
    }
    state = state.copyWith(selectedPaymentMethod: method, errorMessage: null);
  }

  /// Submits checkout via `POST /api/v1/bookings/:bookingId/checkout`.
  /// Enforces duplicate submission protection and validates response.
  Future<bool> submitCheckout({String? overrideMethod}) async {
    // Duplicate tap & lifecycle protection
    if (state.isSubmitting || state.checkoutSuccess || state.booking == null) {
      return false;
    }

    final methodToSubmit = overrideMethod ?? state.selectedPaymentMethod;
    if (methodToSubmit != 'CASH_ON_SERVICE') return false;
    state = state.copyWith(
      isSubmitting: true,
      selectedPaymentMethod: methodToSubmit,
      errorMessage: null,
    );

    try {
      final updatedBooking = await repository.checkoutBooking(
        bookingId,
        paymentMethod: methodToSubmit,
      );

      // Validate confirmation invariants:
      // Status must be PENDING_DISPATCH and payment record must exist.
      final isConfirmed =
          updatedBooking.status == 'PENDING_DISPATCH' &&
          updatedBooking.payment?.method == 'CASH_ON_SERVICE' &&
          updatedBooking.payment?.status == 'PENDING';

      if (isConfirmed) {
        state = state.copyWith(
          isSubmitting: false,
          booking: updatedBooking,
          checkoutSuccess: true,
          errorMessage: null,
        );
        return true;
      } else {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage:
              'Checkout confirmation failed: invalid status or payment record.',
        );
        return false;
      }
    } on FormatException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.message.isNotEmpty
            ? e.message
            : 'Invalid booking pricing data received.',
      );
      return false;
    } on DioException catch (e) {
      final errorMsg = _mapDioError(e);
      state = state.copyWith(isSubmitting: false, errorMessage: errorMsg);
      return false;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return false;
    }
  }

  String _mapDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;
      if (data is Map && data['message'] != null) {
        final message = data['message'];
        if (message is List) {
          return message.join(', ');
        }
        return message.toString();
      }
      if (statusCode == 401) {
        return 'Session expired. Please sign in again to complete checkout.';
      }
      if (statusCode == 403) {
        return 'Access denied. You do not own this booking.';
      }
      if (statusCode == 404) {
        return 'Booking not found.';
      }
      if (statusCode == 400) {
        return 'Invalid checkout request or booking state.';
      }
      return 'Server error ($statusCode). Please retry.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please check your internet connection.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Unable to reach the server. Please check your network and retry.';
    }
    return 'Network error occurred. Please retry.';
  }
}

/// Auto-disposing family provider for Screen 05 CheckoutController.
final checkoutControllerProvider = StateNotifierProvider.autoDispose
    .family<CheckoutController, CheckoutState, String>((ref, bookingId) {
      final repository = ref.watch(bookingRepositoryProvider);
      return CheckoutController(bookingId: bookingId, repository: repository);
    });

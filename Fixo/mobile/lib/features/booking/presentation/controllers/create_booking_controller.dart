import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../customer_home/domain/marketplace_models.dart';
import '../../data/booking_repository.dart';
import '../../domain/booking_models.dart';

/// State of the Create Booking screen (Screen 04).
class CreateBookingState {
  const CreateBookingState({
    this.isLoadingAddresses = false,
    this.addresses = const [],
    this.selectedAddress,
    required this.selectedDate,
    this.selectedTimeWindow = 'AFTERNOON_13_16',
    this.issueDescription = '',
    this.issuePhotoUrls = const [],
    this.isSubmitting = false,
    this.errorMessage,
    this.successBooking,
  });

  final bool isLoadingAddresses;
  final List<CustomerAddressModel> addresses;
  final CustomerAddressModel? selectedAddress;
  final DateTime selectedDate;
  final String selectedTimeWindow;
  final String issueDescription;
  final List<String> issuePhotoUrls;
  final bool isSubmitting;
  final String? errorMessage;
  final BookingDetailModel? successBooking;

  bool get hasSavedAddresses => addresses.isNotEmpty;

  CreateBookingState copyWith({
    bool? isLoadingAddresses,
    List<CustomerAddressModel>? addresses,
    CustomerAddressModel? selectedAddress,
    DateTime? selectedDate,
    String? selectedTimeWindow,
    String? issueDescription,
    List<String>? issuePhotoUrls,
    bool? isSubmitting,
    String? errorMessage,
    BookingDetailModel? successBooking,
    bool clearError = false,
    bool clearSelectedAddress = false,
  }) {
    return CreateBookingState(
      isLoadingAddresses: isLoadingAddresses ?? this.isLoadingAddresses,
      addresses: addresses ?? this.addresses,
      selectedAddress: clearSelectedAddress
          ? null
          : (selectedAddress ?? this.selectedAddress),
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTimeWindow: selectedTimeWindow ?? this.selectedTimeWindow,
      issueDescription: issueDescription ?? this.issueDescription,
      issuePhotoUrls: issuePhotoUrls ?? this.issuePhotoUrls,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successBooking: successBooking ?? this.successBooking,
    );
  }
}

/// Controller managing booking draft creation, address loading, slot selection, and submission.
class CreateBookingController extends StateNotifier<CreateBookingState> {
  CreateBookingController(this._repository)
      : super(CreateBookingState(
          selectedDate: _computeDefaultScheduledDate(),
          isLoadingAddresses: true,
        )) {
    loadAddresses();
  }

  final BookingRepository _repository;

  static DateTime _computeDefaultScheduledDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  /// Loads the customer's saved addresses from the backend.
  Future<void> loadAddresses() async {
    state = state.copyWith(isLoadingAddresses: true, clearError: true);
    try {
      final list = await _repository.getCustomerAddresses();
      CustomerAddressModel? defaultAddr;
      if (list.isNotEmpty) {
        defaultAddr = list.firstWhere(
          (a) => a.isDefault,
          orElse: () => list.first,
        );
      }
      state = state.copyWith(
        isLoadingAddresses: false,
        addresses: list,
        selectedAddress: defaultAddr,
        clearSelectedAddress: list.isEmpty,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingAddresses: false,
        addresses: const [],
        clearSelectedAddress: true,
        errorMessage: 'Could not load saved addresses. Please retry.',
      );
    }
  }

  void selectAddress(CustomerAddressModel address) {
    state = state.copyWith(
      selectedAddress: address,
      clearError: true,
    );
  }

  void selectDate(DateTime date) {
    state = state.copyWith(
      selectedDate: date,
      clearError: true,
    );
  }

  void selectTimeWindow(String window) {
    state = state.copyWith(
      selectedTimeWindow: window,
      clearError: true,
    );
  }

  void setIssueDescription(String text) {
    state = state.copyWith(issueDescription: text);
  }

  /// Submits the booking draft via `POST /api/v1/bookings`.
  Future<bool> submitBooking({
    required ServiceOfferModel offering,
    ProfessionalCardModel? preferredPro,
  }) async {
    if (state.selectedAddress == null) {
      state = state.copyWith(
        errorMessage:
            'A saved service delivery address is required to complete this booking.',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    final scheduledDateStr =
        "${state.selectedDate.year.toString().padLeft(4, '0')}-${state.selectedDate.month.toString().padLeft(2, '0')}-${state.selectedDate.day.toString().padLeft(2, '0')}";

    final request = CreateBookingRequest(
      offeringId: offering.id,
      addressId: state.selectedAddress!.id,
      preferredProId: preferredPro?.id,
      scheduledDate: scheduledDateStr,
      timeWindow: state.selectedTimeWindow,
      issueDescription:
          state.issueDescription.isNotEmpty ? state.issueDescription : null,
      issuePhotoUrls: state.issuePhotoUrls,
    );

    try {
      final booking = await _repository.createBooking(request);
      state = state.copyWith(
        isSubmitting: false,
        successBooking: booking,
      );
      return true;
    } on DioException catch (e) {
      String message =
          'Booking creation failed. Please check connection and try again.';
      if (e.response?.data is Map) {
        final serverMsg = (e.response?.data as Map)['message'];
        if (serverMsg is String) {
          message = serverMsg;
        } else if (serverMsg is List && serverMsg.isNotEmpty) {
          message = serverMsg.join(', ');
        }
      }
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

final createBookingControllerProvider =
    StateNotifierProvider.autoDispose<CreateBookingController, CreateBookingState>(
  (ref) {
    final repo = ref.watch(bookingRepositoryProvider);
    return CreateBookingController(repo);
  },
);

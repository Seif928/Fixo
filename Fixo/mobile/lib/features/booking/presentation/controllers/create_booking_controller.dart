import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../customer_home/domain/marketplace_models.dart';
import '../../data/booking_repository.dart';
import '../../domain/booking_models.dart';
import '../../../../core/time/app_clock.dart';

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
    this.isLoadingZones = false,
    this.coverageZones = const [],
    this.isCreatingAddress = false,
    this.addressCreationError,
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
  final bool isLoadingZones;
  final List<CoverageZoneModel> coverageZones;
  final bool isCreatingAddress;
  final String? addressCreationError;

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
    bool? isLoadingZones,
    List<CoverageZoneModel>? coverageZones,
    bool? isCreatingAddress,
    String? addressCreationError,
    bool clearError = false,
    bool clearAddressCreationError = false,
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
      isLoadingZones: isLoadingZones ?? this.isLoadingZones,
      coverageZones: coverageZones ?? this.coverageZones,
      isCreatingAddress: isCreatingAddress ?? this.isCreatingAddress,
      addressCreationError: clearAddressCreationError
          ? null
          : (addressCreationError ?? this.addressCreationError),
    );
  }
}

/// Controller managing booking draft creation, address loading, slot selection, and submission.
class CreateBookingController extends StateNotifier<CreateBookingState> {
  CreateBookingController(this._repository, {DateTime? today})
    : super(
        CreateBookingState(
          selectedDate: _computeDefaultScheduledDate(today),
          isLoadingAddresses: true,
        ),
      ) {
    loadAddresses();
    loadCoverageZones();
  }

  final BookingRepository _repository;

  static DateTime _computeDefaultScheduledDate(DateTime? today) {
    final now = today ?? DateTime.now();
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

  /// Loads active coverage zones for the address creation dropdown.
  Future<void> loadCoverageZones() async {
    state = state.copyWith(isLoadingZones: true);
    try {
      final zones = await _repository.getCoverageZones();
      state = state.copyWith(isLoadingZones: false, coverageZones: zones);
    } catch (_) {
      state = state.copyWith(isLoadingZones: false, coverageZones: const []);
    }
  }

  /// Creates and selects a new delivery address via `POST /api/v1/users/me/addresses`.
  Future<CustomerAddressModel?> createAddress(
    CreateAddressRequest request,
  ) async {
    state = state.copyWith(
      isCreatingAddress: true,
      clearAddressCreationError: true,
    );

    try {
      final created = await _repository.createAddress(request);

      // Refresh address list atomically in memory
      final updatedList = state.addresses.map((a) {
        if (created.isDefault && a.isDefault) {
          return CustomerAddressModel(
            id: a.id,
            userId: a.userId,
            zoneId: a.zoneId,
            label: a.label,
            buildingLine: a.buildingLine,
            districtLine: a.districtLine,
            gateNotes: a.gateNotes,
            zone: a.zone,
            isDefault: false,
          );
        }
        return a;
      }).toList();

      if (created.isDefault) {
        updatedList.insert(0, created);
      } else {
        updatedList.add(created);
      }

      state = state.copyWith(
        isCreatingAddress: false,
        addresses: updatedList,
        selectedAddress: created,
        clearAddressCreationError: true,
        clearError: true,
      );

      return created;
    } on DioException catch (e) {
      String message =
          'Address creation failed. Please check inputs and retry.';
      if (e.response?.data is Map) {
        final serverMsg = (e.response?.data as Map)['message'];
        if (serverMsg is String) {
          message = serverMsg;
        } else if (serverMsg is List && serverMsg.isNotEmpty) {
          message = serverMsg.join(', ');
        }
      }
      state = state.copyWith(
        isCreatingAddress: false,
        addressCreationError: message,
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isCreatingAddress: false,
        addressCreationError: e.toString(),
      );
      return null;
    }
  }

  void selectAddress(CustomerAddressModel address) {
    state = state.copyWith(selectedAddress: address, clearError: true);
  }

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date, clearError: true);
  }

  void selectTimeWindow(String window) {
    state = state.copyWith(selectedTimeWindow: window, clearError: true);
  }

  void setIssueDescription(String text) {
    state = state.copyWith(issueDescription: text);
  }

  void addPhotoUrl(String url) {
    if (!state.issuePhotoUrls.contains(url)) {
      state = state.copyWith(issuePhotoUrls: [...state.issuePhotoUrls, url]);
    }
  }

  void removePhotoUrl(String url) {
    state = state.copyWith(
      issuePhotoUrls: state.issuePhotoUrls.where((u) => u != url).toList(),
    );
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
      issueDescription: state.issueDescription.isNotEmpty
          ? state.issueDescription
          : null,
      issuePhotoUrls: state.issuePhotoUrls,
    );

    try {
      final booking = await _repository.createBooking(request);
      state = state.copyWith(isSubmitting: false, successBooking: booking);
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
      state = state.copyWith(isSubmitting: false, errorMessage: message);
      return false;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return false;
    }
  }
}

final createBookingControllerProvider =
    StateNotifierProvider.autoDispose<
      CreateBookingController,
      CreateBookingState
    >((ref) {
      final repo = ref.watch(bookingRepositoryProvider);
      return CreateBookingController(repo, today: ref.read(appNowProvider)());
    });

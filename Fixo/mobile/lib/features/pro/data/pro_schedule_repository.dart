import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/pro_schedule_models.dart';

class ProScheduleException implements Exception {
  const ProScheduleException(
    this.message, {
    this.code,
    this.conflictingBookingsCount,
  });

  final String message;
  final String? code;
  final int? conflictingBookingsCount;

  @override
  String toString() => message;
}

class ProScheduleRepository {
  const ProScheduleRepository(this._dio);

  final Dio _dio;

  Future<ProScheduleData> getSchedule() async {
    final response = await _dio.get('/pro/schedule');
    return ProScheduleData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProScheduleData> updateSchedule(List<ProDaySchedule> days) async {
    final response = await _dio.put(
      '/pro/schedule',
      data: {
        'days': days.map((d) => d.toJson()).toList(),
      },
    );
    return ProScheduleData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProLeaveItem> createLeave({
    required DateTime startDate,
    required DateTime endDate,
    required ProLeaveReason reason,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/pro/leaves',
        data: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'reason': reason.wireValue,
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        },
      );
      return ProLeaveItem.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final body = e.response?.data;
        final count = (body is Map<String, dynamic>)
            ? (body['conflictingBookingsCount'] as num?)?.toInt()
            : null;
        throw ProScheduleException(
          'Cannot schedule leave: active bookings are assigned during this time.',
          code: 'BOOKING_CONFLICT',
          conflictingBookingsCount: count,
        );
      }
      rethrow;
    }
  }

  Future<void> cancelLeave(String leaveId) async {
    await _dio.delete('/pro/leaves/$leaveId');
  }
}

final proScheduleRepositoryProvider = Provider<ProScheduleRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ProScheduleRepository(dio);
});


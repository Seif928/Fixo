import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import 'complaints_models.dart';

class ComplaintsRepository {
  ComplaintsRepository(this._dio);
  final Dio _dio;

  Future<ComplaintItemModel> createComplaint({
    required String bookingId,
    required ComplaintCategory category,
    required String description,
    List<String>? photoUrls,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/complaints',
      data: {
        'bookingId': bookingId,
        'category': category.wireValue,
        'description': description.trim(),
        if (photoUrls != null && photoUrls.isNotEmpty) 'photoUrls': photoUrls,
      },
    );

    return ComplaintItemModel.fromJson(response.data!);
  }

  Future<List<ComplaintItemModel>> listMyComplaints({
    int page = 1,
    int limit = 20,
    ComplaintStatus? status,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null) 'status': status.wireValue,
    };

    final response = await _dio.get<Map<String, dynamic>>(
      '/complaints/my',
      queryParameters: queryParams,
    );

    final items = response.data?['items'] as List<dynamic>? ?? [];
    return items
        .map((i) => ComplaintItemModel.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<ComplaintItemModel> getComplaintDetails(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/complaints/${Uri.encodeComponent(id)}',
    );
    return ComplaintItemModel.fromJson(response.data!);
  }
}

final complaintsRepositoryProvider = Provider<ComplaintsRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ComplaintsRepository(dio);
});


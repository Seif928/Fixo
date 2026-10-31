import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Central Dio HTTP client configured for the FIXO NestJS backend (`/api/v1`).
final dioClientProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment(
        'FIXO_API_BASE_URL',
        defaultValue: 'http://localhost:3000/api/v1',
      ),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: const <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );
});


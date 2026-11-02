import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import 'egypt_places.dart';
import 'map_point.dart';

class LocationChoiceException implements Exception {
  const LocationChoiceException(this.code);
  final String code;
  String message(bool ar) => switch (code) {
    'disabled' =>
      ar
          ? 'فعّل خدمة الموقع أو اختار مكانك يدويًا.'
          : 'Enable location services or choose your area manually.',
    'denied' =>
      ar
          ? 'إذن الموقع مش متاح. تقدر تختار المكان بنفسك.'
          : 'Location permission is unavailable. You can choose your area manually.',
    'outside' =>
      ar
          ? 'الخدمة داخل مصر. اختار مكان الخدمة في مصر.'
          : 'Service is in Egypt. Choose your service area in Egypt.',
    _ =>
      ar
          ? 'تعذّر تحديد منطقتك. اختارها يدويًا أو جرّب تاني.'
          : 'Could not detect your area. Choose it manually or try again.',
  };
}

class DeviceLocationService {
  Future<ServiceMapPoint> currentPoint() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled().timeout(
        const Duration(seconds: 5),
      )) {
        throw const LocationChoiceException('disabled');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const LocationChoiceException('denied');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      ).timeout(const Duration(seconds: 18));
      return ServiceMapPoint(position.latitude, position.longitude);
    } on LocationChoiceException {
      rethrow;
    } on PermissionDeniedException {
      throw const LocationChoiceException('denied');
    } catch (_) {
      throw const LocationChoiceException('unavailable');
    }
  }
}

final deviceLocationProvider = Provider<DeviceLocationService>(
  (ref) => DeviceLocationService(),
);
typedef AreaLocator = Future<SelectedServiceArea> Function();
final areaLocatorProvider = Provider<AreaLocator>(
  (ref) => () async {
    final point = await ref.read(deviceLocationProvider).currentPoint();
    try {
      final result = await ref
          .read(dioClientProvider)
          .post<Map<String, dynamic>>(
            '/locations/reverse',
            data: {'latitude': point.latitude, 'longitude': point.longitude},
          );
      return SelectedServiceArea.fromJson(
        Map<String, dynamic>.from(result.data!['area']),
      );
    } catch (_) {
      throw const LocationChoiceException('unavailable');
    }
  },
);

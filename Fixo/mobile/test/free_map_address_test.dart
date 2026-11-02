import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/core/location/free_map_picker.dart';
import 'package:fixo_mobile/features/booking/domain/booking_models.dart';

void main() {
  const address = CreateAddressRequest(zoneId: 'zone', label: 'Home', buildingLine: '12', districtLine: 'Giza');
  test('manual addresses never receive fabricated coordinates', () {
    expect(address.toJson().containsKey('latitude'), false);
    expect(address.toJson().containsKey('longitude'), false);
  });
  test('a map selection persists both real coordinates without changing address ownership', () {
    final payload = address.withCoordinates(30.0131, 31.2089).toJson();
    expect(payload['latitude'], 30.0131);
    expect(payload['longitude'], 31.2089);
    expect(payload.containsKey('userId'), false);
    expect(payload['zoneId'], 'zone');
    final saved = CustomerAddressModel.fromJson({'id': 'address', ...payload});
    expect(saved.latitude, 30.0131);
    expect(saved.longitude, 31.2089);
  });
  test('out-of-range and non-finite map points are rejected', () {
    expect(() => ServiceMapPoint(double.nan, 31), throwsArgumentError);
    expect(() => ServiceMapPoint(95, 31), throwsArgumentError);
    expect(() => ServiceMapPoint(30, 185), throwsArgumentError);
  });
}

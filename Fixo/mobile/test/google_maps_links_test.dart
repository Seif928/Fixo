import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/core/location/google_maps_links.dart';

void main() {
  test('uses official HTTPS maps search and encodes Arabic address safely', () {
    final uri = GoogleMapsLinks.search('شارع النيل & 12, الجيزة');
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/search/');
    expect(uri.queryParameters, {
      'api': '1',
      'query': 'شارع النيل & 12, الجيزة',
    });
    expect(uri.scheme, 'https');
  });
  test('directions omit origin so Google Maps asks for current origin', () {
    final uri = GoogleMapsLinks.directions('Building 14, Giza, Egypt');
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters['destination'], 'Building 14, Giza, Egypt');
    expect(uri.queryParameters.containsKey('origin'), false);
    expect(uri.queryParameters.containsKey('key'), false);
  });
  test('never substitutes a demo location for an empty address', () {
    expect(() => GoogleMapsLinks.search('  '), throwsArgumentError);
    expect(() => GoogleMapsLinks.directions(''), throwsArgumentError);
  });
}

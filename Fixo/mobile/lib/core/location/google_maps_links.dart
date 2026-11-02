/// Public Maps URLs need neither an API key nor a billing account.
/// The caller supplies the saved address, never gate notes or a demo coordinate.
abstract final class GoogleMapsLinks {
  static String _address(String address) {
    final value = address.trim();
    if (value.isEmpty) throw ArgumentError.value(address, 'address');
    return value;
  }

  static Uri search(String address) => Uri.https(
    'www.google.com',
    '/maps/search/',
    {'api': '1', 'query': _address(address)},
  );

  static Uri directions(String address) => Uri.https(
    'www.google.com',
    '/maps/dir/',
    {'api': '1', 'destination': _address(address)},
  );
}

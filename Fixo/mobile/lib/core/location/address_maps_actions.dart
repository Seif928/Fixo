import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'google_maps_links.dart';

/// Opens Google Maps only after a user gesture. No background location access.
class AddressMapsActions extends StatelessWidget {
  const AddressMapsActions({
    super.key,
    required this.address,
    required this.isArabic,
  });
  final String address;
  final bool isArabic;

  Future<void> _open(BuildContext context, Uri uri) async {
    bool opened;
    try {
      // A HTTPS URL works with Google Maps or a browser on every target platform.
      opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تعذّر فتح Google Maps. حاول مرة أخرى.'
                : 'Could not open Google Maps. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    children: [
      TextButton.icon(
        key: const Key('open-address-google-maps'),
        onPressed: address.trim().isEmpty
            ? null
            : () => _open(context, GoogleMapsLinks.search(address)),
        icon: const Icon(Icons.map_outlined),
        label: Text(isArabic ? 'فتح في Google Maps' : 'Open in Google Maps'),
      ),
      TextButton.icon(
        key: const Key('address-google-directions'),
        onPressed: address.trim().isEmpty
            ? null
            : () => _open(context, GoogleMapsLinks.directions(address)),
        icon: const Icon(Icons.directions_outlined),
        label: Text(isArabic ? 'الاتجاهات' : 'Directions'),
      ),
    ],
  );
}

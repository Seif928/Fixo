import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:url_launcher/url_launcher.dart';

class ServiceMapPoint {
  ServiceMapPoint(this.latitude, this.longitude) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      throw ArgumentError('Invalid map coordinate.');
    }
  }
  final double latitude, longitude;
}

abstract final class FreeMapProvider {
  static const lightStyle = 'https://tiles.openfreemap.org/styles/liberty';
  static const darkStyle = 'https://tiles.openfreemap.org/styles/dark';
  static const attribution = '© OpenMapTiles · © OpenStreetMap contributors';
}

typedef FreeMapSurface =
    Widget Function(
      ServiceMapPoint? initial,
      ValueChanged<ServiceMapPoint> onPick,
      bool dark,
    );
final freeMapReadyProvider = FutureProvider<void>(
  (ref) => MapLibreMap.ensureWebLibraryLoaded(),
);
final freeMapSurfaceProvider = Provider<FreeMapSurface>(
  (ref) =>
      (initial, onPick, dark) =>
          _MapSurface(initial: initial, onPick: onPick, dark: dark),
);

class _MapSurface extends StatefulWidget {
  const _MapSurface({
    required this.initial,
    required this.onPick,
    required this.dark,
    this.readOnly = false,
  });
  final ServiceMapPoint? initial;
  final ValueChanged<ServiceMapPoint> onPick;
  final bool dark;
  final bool readOnly;
  @override
  State<_MapSurface> createState() => _MapSurfaceState();
}

class _MapSurfaceState extends State<_MapSurface> {
  MapLibreMapController? _controller;
  Circle? _pin;
  bool _styleReady = false;
  Future<void> _pinAt(LatLng location) async {
    if (!_styleReady || _controller == null) return;
    try {
      if (_pin != null) await _controller!.removeCircle(_pin!);
      _pin = await _controller!.addCircle(
        CircleOptions(
          geometry: location,
          circleRadius: 9,
          circleColor: '#173F35',
          circleStrokeColor: '#D5EE76',
          circleStrokeWidth: 3,
        ),
      );
    } catch (_) {
      /* The coordinate remains visible even if marker rendering fails. */
    }
  }

  @override
  Widget build(BuildContext context) => MapLibreMap(
    styleString: widget.dark
        ? FreeMapProvider.darkStyle
        : FreeMapProvider.lightStyle,
    initialCameraPosition: CameraPosition(
      target: widget.initial == null
          ? const LatLng(30.0444, 31.2357)
          : LatLng(widget.initial!.latitude, widget.initial!.longitude),
      zoom: widget.initial == null ? 10 : 15,
    ),
    onMapCreated: (controller) => _controller = controller,
    onStyleLoadedCallback: () {
      _styleReady = true;
      if (widget.initial != null) {
        _pinAt(LatLng(widget.initial!.latitude, widget.initial!.longitude));
      }
    },
    onMapClick: (_, coordinate) {
      if (!_styleReady || widget.readOnly) return;
      widget.onPick(ServiceMapPoint(coordinate.latitude, coordinate.longitude));
      _pinAt(coordinate);
    },
    myLocationEnabled: false,
    rotateGesturesEnabled: !widget.readOnly,
    scrollGesturesEnabled: !widget.readOnly,
    tiltGesturesEnabled: !widget.readOnly,
    zoomGesturesEnabled: !widget.readOnly,
  );
}

/// A preview is shown only for a real, persisted point, never inferred from text.
class SavedLocationMap extends ConsumerWidget {
  const SavedLocationMap({
    super.key,
    required this.point,
    required this.isArabic,
  });
  final ServiceMapPoint point;
  final bool isArabic;
  @override
  Widget build(BuildContext context, WidgetRef ref) => SizedBox(
    height: 160,
    child: ref
        .watch(freeMapReadyProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Text(
              isArabic
                  ? 'الخريطة غير متاحة حالياً.'
                  : 'Map unavailable right now.',
            ),
          ),
          data: (_) => _MapSurface(
            initial: point,
            onPick: (_) {},
            dark: Theme.of(context).brightness == Brightness.dark,
            readOnly: true,
          ),
        ),
  );
}

/// A city overview is not a selected address. Confirm stays disabled until a tap.
class FreeMapPicker extends ConsumerStatefulWidget {
  const FreeMapPicker({super.key, required this.isArabic, this.initial});
  final bool isArabic;
  final ServiceMapPoint? initial;
  @override
  ConsumerState<FreeMapPicker> createState() => _FreeMapPickerState();
}

class _FreeMapPickerState extends ConsumerState<FreeMapPicker> {
  ServiceMapPoint? _selected;
  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.isArabic;
    final ready = ref.watch(freeMapReadyProvider);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .85,
        child: Column(
          children: [
            ListTile(
              title: Text(
                ar
                    ? 'اختر نقطة الخدمة على الخريطة'
                    : 'Choose the service location',
              ),
              subtitle: Text(
                ar
                    ? 'اضغط على مكانك. لا يتم تحديد موقعك تلقائياً.'
                    : 'Tap your location. Your position is not detected automatically.',
              ),
              trailing: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
            Expanded(
              child: ready.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(freeMapReadyProvider),
                    child: Text(
                      ar
                          ? 'تعذّر تحميل الخريطة. أعد المحاولة.'
                          : 'Could not load the map. Retry.',
                    ),
                  ),
                ),
                data: (_) => ref.watch(freeMapSurfaceProvider)(
                  widget.initial,
                  (point) => setState(() => _selected = point),
                  Theme.of(context).brightness == Brightness.dark,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _selected == null
                        ? (ar
                              ? 'لم يتم اختيار نقطة بعد.'
                              : 'No point selected yet.')
                        : '${_selected!.latitude.toStringAsFixed(5)}, ${_selected!.longitude.toStringAsFixed(5)}',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                  ),
                  TextButton(
                    onPressed: () => launchUrl(
                      Uri.parse('https://www.openstreetmap.org/copyright'),
                    ),
                    child: const Text(
                      FreeMapProvider.attribution,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  FilledButton(
                    key: const Key('confirm-map-point'),
                    onPressed: _selected == null || !ready.hasValue
                        ? null
                        : () => Navigator.pop(context, _selected),
                    child: Text(
                      ar ? 'استخدام هذه النقطة' : 'Use this location',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keeps the address form's state while the optional map selector is opened.
class AddressMapWrapper extends StatefulWidget {
  const AddressMapWrapper({
    super.key,
    required this.isArabic,
    required this.builder,
  });
  final bool isArabic;
  final Widget Function(ServiceMapPoint? point) builder;
  @override
  State<AddressMapWrapper> createState() => _AddressMapWrapperState();
}

class _AddressMapWrapperState extends State<AddressMapWrapper> {
  ServiceMapPoint? _point;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .9,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          key: const Key('choose-free-map-point'),
          icon: const Icon(Icons.pin_drop_outlined),
          label: Text(
            widget.isArabic
                ? (_point == null
                      ? 'اختيار نقطة على الخريطة (اختياري)'
                      : 'تعديل النقطة المختارة')
                : (_point == null
                      ? 'Choose a map pin (optional)'
                      : 'Change selected map pin'),
          ),
          onPressed: () async {
            final point = await showModalBottomSheet<ServiceMapPoint>(
              context: context,
              isScrollControlled: true,
              builder: (_) =>
                  FreeMapPicker(isArabic: widget.isArabic, initial: _point),
            );
            if (mounted && point != null) setState(() => _point = point);
          },
        ),
        Flexible(child: widget.builder(_point)),
      ],
    ),
  );
}

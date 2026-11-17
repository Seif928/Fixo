import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/fixo_colors.dart';
import '../widgets/fixo_buttons.dart';
import 'egypt_places.dart';
import 'device_location_service.dart';

Future<SelectedServiceArea?> showServiceAreaPicker(
  BuildContext context, {
  required bool isArabic,
  SelectedServiceArea? initial,
  bool startWithGovernorates = false,
}) => showModalBottomSheet<SelectedServiceArea>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 600),
  builder: (_) => ServiceAreaPicker(
    isArabic: isArabic,
    initial: initial,
    startWithGovernorates: startWithGovernorates,
  ),
);

class ServiceAreaPicker extends ConsumerStatefulWidget {
  const ServiceAreaPicker({
    super.key,
    required this.isArabic,
    this.initial,
    this.startWithGovernorates = false,
  });
  final bool isArabic;
  final bool startWithGovernorates;
  final SelectedServiceArea? initial;
  @override
  ConsumerState<ServiceAreaPicker> createState() => _ServiceAreaPickerState();
}

class _ServiceAreaPickerState extends ConsumerState<ServiceAreaPicker> {
  final _query = TextEditingController(), _manual = TextEditingController();
  EgyptPlace? _governorate;
  SelectedServiceArea? _selection;
  bool _restored = false;
  bool _detecting = false;
  int _detectionEpoch = 0;
  String? _locationError;
  Future<void> _detect() async {
    final epoch = ++_detectionEpoch;
    setState(() {
      _detecting = true;
      _locationError = null;
    });
    try {
      final area = await ref.read(areaLocatorProvider)();
      final catalog = await ref.read(egyptPlacesProvider.future);
      if (!mounted || epoch != _detectionEpoch) return;
      final matches = catalog.governorates.where(
        (g) => g.slug == area.zoneSlug,
      );
      if (matches.isEmpty) throw const LocationChoiceException('unavailable');
      setState(() {
        _governorate = matches.first;
        _selection = area;
        _manual.text = widget.isArabic ? area.localityAr : area.localityEn;
        _query.clear();
      });
    } catch (error) {
      if (mounted && epoch == _detectionEpoch) {
        setState(() {
          _locationError =
              (error is LocationChoiceException
                      ? error
                      : const LocationChoiceException('unavailable'))
                  .message(widget.isArabic);
        });
      }
    } finally {
      if (mounted && epoch == _detectionEpoch) {
        setState(() => _detecting = false);
      }
    }
  }

  @override
  void dispose() {
    _query.dispose();
    _manual.dispose();
    super.dispose();
  }

  void _select(EgyptPlace gov, {EgyptPlace? place, EgyptPlaces? catalog}) {
    setState(() {
      _detectionEpoch++;
      _detecting = false;
      _locationError = null;
      _governorate = gov;
      _selection = SelectedServiceArea(
        zoneSlug: gov.slug!,
        governorateEn: gov.nameEn,
        governorateAr: gov.nameAr,
        localityEn: place == null ? '' : catalog!.localLabel(place, false),
        localityAr: place == null ? '' : catalog!.localLabel(place, true),
      );
      _manual.text = place == null
          ? ''
          : catalog!.localLabel(place, widget.isArabic);
      _query.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.isArabic, palette = context.fixoPalette;
    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .88,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            children: [
              ListTile(
                title: Text(
                  ar ? 'اختار مكان الخدمة' : 'Choose your service area',
                ),
                subtitle: Text(
                  ar
                      ? 'كل محافظات مصر • المدينة أو القرية باختيارك'
                      : 'All of Egypt • Choose your city or village',
                ),
                trailing: IconButton(
                  tooltip: ar ? 'إغلاق' : 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    key: const Key('detect-service-area'),
                    onPressed: _detecting ? null : _detect,
                    icon: _detecting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(ar ? 'حدد مكاني الحالي' : 'Detect my area'),
                  ),
                ),
              ),
              if (_locationError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _locationError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (_selection != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _selection!.label(ar),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Expanded(
                child: ref
                    .watch(egyptPlacesProvider)
                    .when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, _) => Center(
                        child: TextButton(
                          onPressed: () => ref.invalidate(egyptPlacesProvider),
                          child: Text(
                            ar
                                ? 'تعذّر تحميل الأماكن. إعادة المحاولة'
                                : 'Could not load places. Retry',
                          ),
                        ),
                      ),
                      data: (catalog) {
                        if (!_restored) {
                          _restored = true;
                          final matches = catalog.governorates.where(
                            (g) => g.slug == widget.initial?.zoneSlug,
                          );
                          if (matches.isNotEmpty) {
                            if (!widget.startWithGovernorates) {
                              _governorate = matches.first;
                            }
                            _selection = widget.initial;
                            _manual.text = ar
                                ? widget.initial!.localityAr
                                : widget.initial!.localityEn;
                          }
                        }
                        final gov = _governorate;
                        final places = gov == null
                            ? catalog.governorates
                                  .where(
                                    (g) => normalizePlaceName(
                                      '${g.nameAr} ${g.nameEn}',
                                    ).contains(normalizePlaceName(_query.text)),
                                  )
                                  .toList()
                            : catalog.search(gov.id, _query.text);
                        return ListView(
                          children: [
                            if (gov != null)
                              ListTile(
                                title: Text(
                                  gov.name(ar),
                                  style: TextStyle(
                                    color: palette.deepForest,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                leading: const Icon(Icons.location_on_outlined),
                                trailing: TextButton(
                                  onPressed: () => setState(() {
                                    _detectionEpoch++;
                                    _detecting = false;
                                    _governorate = null;
                                    _selection = null;
                                    _query.clear();
                                    _manual.clear();
                                  }),
                                  child: Text(ar ? 'تغيير المحافظة' : 'Change'),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: TextField(
                                key: const Key('place-search'),
                                controller: _query,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.search),
                                  hintText: gov == null
                                      ? (ar
                                            ? 'ابحث عن المحافظة'
                                            : 'Search governorates')
                                      : (ar
                                            ? 'ابحث عن مدينة أو قرية أو منطقة'
                                            : 'Search cities, villages or districts'),
                                ),
                              ),
                            ),
                            if (gov != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: TextField(
                                  key: const Key('place-manual'),
                                  controller: _manual,
                                  maxLength: 120,
                                  onChanged: (value) => setState(() {
                                    _detectionEpoch++;
                                    _detecting = false;
                                    _selection = SelectedServiceArea(
                                      zoneSlug: gov.slug!,
                                      governorateEn: gov.nameEn,
                                      governorateAr: gov.nameAr,
                                      localityEn: value.trim(),
                                      localityAr: value.trim(),
                                    );
                                  }),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(
                                      Icons.edit_location_alt_outlined,
                                    ),
                                    labelText: ar
                                        ? 'أو اكتب منطقتك بنفسك (اختياري)'
                                        : 'Or type your area (optional)',
                                  ),
                                ),
                              ),
                            if (places.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  ar
                                      ? 'مفيش نتيجة. تقدر تكتب المكان بنفسك فوق.'
                                      : 'No results. You can type your area above.',
                                ),
                              ),
                            for (final place in places)
                              ListTile(
                                key: ValueKey('place-${place.id}'),
                                minVerticalPadding: 12,
                                leading: Icon(
                                  gov == null
                                      ? Icons.map_outlined
                                      : Icons.location_city_outlined,
                                ),
                                title: Text(place.name(ar)),
                                subtitle: gov == null
                                    ? null
                                    : Text(
                                        catalog.byId[place.parent]?.name(ar) ??
                                            '',
                                      ),
                                onTap: () => _select(
                                  gov ?? place,
                                  place: gov == null ? null : place,
                                  catalog: catalog,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: FixoPrimaryButton(
                  key: const Key('confirm-service-area'),
                  label: _selection == null
                      ? (ar
                            ? 'اختار المحافظة أولًا'
                            : 'Choose a governorate first')
                      : (ar ? 'استخدم المكان ده' : 'Use this area'),
                  onPressed: _selection == null || _detecting
                      ? null
                      : () => Navigator.pop(context, _selection),
                ),
              ),
              const Text(
                '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 10),
              ),
              TextButton(
                onPressed: () => launchUrl(
                  Uri.parse(
                    'https://github.com/open-admin-data/egypt-administrative-divisions',
                  ),
                ),
                child: const Text(
                  'Open Admin Data · CC BY 4.0',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

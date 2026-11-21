import 'package:material_ui/material_ui.dart';
import '../theme/fixo_colors.dart';
import 'fixo_skeleton.dart';

/// Lazily loads a deferred route library on demand so non-initial screens
/// (Admin, Pro Portal, Support) do not bloat the initial Web bundle.
class DeferredRouteView extends StatefulWidget {
  const DeferredRouteView({
    super.key,
    required this.loadLibrary,
    required this.builder,
  });

  final Future<void> Function() loadLibrary;
  final WidgetBuilder builder;

  @override
  State<DeferredRouteView> createState() => _DeferredRouteViewState();
}

class _DeferredRouteViewState extends State<DeferredRouteView> {
  static final Set<Future<void> Function()> _loadedLibraries =
      <Future<void> Function()>{};

  late bool _isReady;
  Future<void>? _libraryFuture;

  @override
  void initState() {
    super.initState();
    _isReady = _loadedLibraries.contains(widget.loadLibrary);
    if (!_isReady) {
      _libraryFuture = _startLoad();
    }
  }

  Future<void> _startLoad() async {
    await widget.loadLibrary();
    _loadedLibraries.add(widget.loadLibrary);
  }

  void _retry() {
    setState(() {
      _isReady = false;
      _libraryFuture = _startLoad();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady) {
      return widget.builder(context);
    }
    final palette = context.fixoPalette;
    return FutureBuilder<void>(
      future: _libraryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          _isReady = true;
          return widget.builder(context);
        }
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: palette.canvasBackground,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 44,
                      color: palette.coralUrgent,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load page module. Please check your connection.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _retry,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return Scaffold(
          backgroundColor: palette.canvasBackground,
          body: const SafeArea(
            child: FixoListSkeleton(itemCount: 4, showHeaderBanner: true),
          ),
        );
      },
    );
  }
}


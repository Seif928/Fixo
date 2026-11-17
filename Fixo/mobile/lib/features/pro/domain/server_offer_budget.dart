/// A server-issued time budget measured with a monotonic clock. Timer callbacks
/// only redraw the UI; delayed callbacks cannot extend the offer's lifetime.
class ServerOfferBudget {
  ServerOfferBudget(this.now);
  final Duration Function() now;
  String? _revision;
  Duration? _deadline;
  bool _pending = false;

  void synchronize({
    required String revision,
    required int remainingSeconds,
    required Duration requestStarted,
    required bool pending,
  }) {
    if (remainingSeconds < 0 || remainingSeconds > 3600 || revision.isEmpty) {
      throw const FormatException('Invalid job offer time budget.');
    }
    // Count the full request duration conservatively. Re-reading the same offer
    // revision can shorten, but never replenish, an existing local budget.
    final deadline = requestStarted + Duration(seconds: remainingSeconds);
    if (_revision != revision || _deadline == null || deadline < _deadline!) {
      _deadline = deadline;
    }
    _revision = revision;
    _pending = pending;
  }

  int get remainingSeconds {
    if (!_pending || _deadline == null) return 0;
    final micros = (_deadline! - now()).inMicroseconds;
    if (micros <= 0) return 0;
    return (micros / Duration.microsecondsPerSecond).ceil();
  }
}

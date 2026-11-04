import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/features/pro/domain/server_offer_budget.dart';

void main() {
  test(
    'elapsed monotonic time expires an offer even with no timer callbacks',
    () {
      var elapsed = Duration.zero;
      final budget = ServerOfferBudget(() => elapsed);
      budget.synchronize(
        revision: 'offer:v1',
        remainingSeconds: 45,
        requestStarted: Duration.zero,
        pending: true,
      );
      elapsed = const Duration(seconds: 40);
      expect(budget.remainingSeconds, 5);
      elapsed = const Duration(seconds: 46);
      expect(budget.remainingSeconds, 0);
    },
  );
  test(
    'request latency is included and fractional seconds round up only until expiry',
    () {
      var elapsed = const Duration(milliseconds: 2200);
      final budget = ServerOfferBudget(() => elapsed);
      budget.synchronize(
        revision: 'offer:v1',
        remainingSeconds: 45,
        requestStarted: Duration.zero,
        pending: true,
      );
      expect(budget.remainingSeconds, 43);
      elapsed = const Duration(milliseconds: 44999);
      expect(budget.remainingSeconds, 1);
      elapsed = const Duration(seconds: 45);
      expect(budget.remainingSeconds, 0);
    },
  );
  test(
    'refreshing the same revision cannot replenish time; a new server revision can',
    () {
      var elapsed = Duration.zero;
      final budget = ServerOfferBudget(() => elapsed);
      budget.synchronize(
        revision: 'offer:v1',
        remainingSeconds: 45,
        requestStarted: elapsed,
        pending: true,
      );
      elapsed = const Duration(seconds: 20);
      budget.synchronize(
        revision: 'offer:v1',
        remainingSeconds: 45,
        requestStarted: elapsed,
        pending: true,
      );
      expect(budget.remainingSeconds, 25);
      budget.synchronize(
        revision: 'offer:v2',
        remainingSeconds: 45,
        requestStarted: elapsed,
        pending: true,
      );
      expect(budget.remainingSeconds, 45);
      budget.synchronize(
        revision: 'offer:v2',
        remainingSeconds: 45,
        requestStarted: elapsed,
        pending: false,
      );
      expect(budget.remainingSeconds, 0);
    },
  );
  test(
    'missing revision and invalid server durations fail without a fabricated timer',
    () {
      final budget = ServerOfferBudget(() => Duration.zero);
      for (final remaining in [-1, 3601]) {
        expect(
          () => budget.synchronize(
            revision: 'offer:v1',
            remainingSeconds: remaining,
            requestStarted: Duration.zero,
            pending: true,
          ),
          throwsFormatException,
        );
      }
      expect(
        () => budget.synchronize(
          revision: '',
          remainingSeconds: 45,
          requestStarted: Duration.zero,
          pending: true,
        ),
        throwsFormatException,
      );
      expect(budget.remainingSeconds, 0);
    },
  );
}

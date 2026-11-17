import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/customer_home/presentation/widgets/customer_home_widgets.dart';
import 'package:fixo_mobile/features/customer_home/domain/marketplace_models.dart';
import 'package:fixo_mobile/features/pro/domain/pro_models.dart';

void main() {
  test('professional profile does not invent a five-star reputation', () {
    expect(ProProfileModel.fromJson({'id': 'p', 'userId': 'u'}).ratingAvg, 0);
  });
  test(
    'professional financial models reject missing and invalid monetary data',
    () {
      for (final money in [null, -1, 1.5, double.infinity, '100']) {
        expect(
          () => JobOfferModel.fromJson({
            'grossEgp': money,
            'netArtisanEgp': 90,
            'platformFeeEgp': 10,
          }),
          throwsFormatException,
        );
        expect(
          () => ProScheduledJobModel.fromJson({
            'totalEgp': 100,
            'netArtisanEgp': money,
          }),
          throwsFormatException,
        );
        expect(
          () => ProDashboardDailyEarningsModel.fromJson({
            'netEarningsEgp': money,
          }),
          throwsFormatException,
        );
        expect(
          () => ProDashboardModel.fromJson({
            'profile': <String, dynamic>{},
            'earningsSummary': {
              'todayNetEarningsEgp': money,
              'weeklyNetEarningsEgp': 100,
            },
          }),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'null badges and absent reputation never invent credentials, reviews or coverage',
    () {
      final pro = ProfessionalCardModel.fromJson({
        'id': 'pro-1',
        'estimatedPriceEgp': 200,
        'badgeEn': null,
        'badgeAr': null,
        'badgeVariant': null,
      });
      expect(pro.badgeEn, isEmpty);
      expect(pro.badgeAr, isEmpty);
      expect(pro.badgeVariant, isEmpty);
      expect(pro.reviewsCount, 0);
      expect(pro.ratingAvg, 0);
      expect(pro.isOnline, isFalse);
      expect(pro.primaryZoneSlug, isEmpty);
    },
  );
  test(
    'missing or invalid professional pricing fails instead of inventing 250 EGP',
    () {
      for (final value in [null, -1, 1.5, double.infinity, '250']) {
        expect(
          () => ProfessionalCardModel.fromJson({
            'id': 'pro-1',
            'estimatedPriceEgp': value,
          }),
          throwsFormatException,
        );
      }
    },
  );
  testWidgets(
    'an unreviewed professional has neutral copy and no verification icon',
    (tester) async {
      final pro = ProfessionalCardModel.fromJson({
        'id': 'pro-1',
        'estimatedPriceEgp': 200,
        'fullNameEn': 'New technician',
        'reviewsCount': 0,
        'ratingAvg': 5,
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: FixoTheme.light(),
          home: Scaffold(
            body: RecommendedProCard(
              professional: pro,
              isArabic: false,
              onBookSlot: () {},
            ),
          ),
        ),
      );
      expect(find.text('No reviews yet'), findsOneWidget);
      expect(find.byIcon(Icons.verified_user_rounded), findsNothing);
      expect(find.text('5.0'), findsNothing);
    },
  );
}

import 'package:dio/dio.dart';
import 'package:fixo_mobile/features/pro/data/pro_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'reads the real /pro/me profile envelope and preserves approval',
    () async {
      Map<String, dynamic> payload = {
        'profile': {
          'id': 'pro-test',
          'userId': 'user-test',
          'fullName': 'Local fixture',
          'verificationStatus': 'APPROVED',
        },
      };
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.resolve(
                Response(
                  requestOptions: options,
                  data: payload,
                  statusCode: 200,
                ),
              );
            },
          ),
        );
      final repository = ProRepository(dio);
      final profile = await repository.getMyProfile();
      expect(profile?.id, 'pro-test');
      expect(profile?.verificationStatus, 'APPROVED');
      payload = {'profile': null};
      expect(await repository.getMyProfile(), isNull);
      payload = {};
      await expectLater(repository.getMyProfile(), throwsFormatException);
    },
  );
}

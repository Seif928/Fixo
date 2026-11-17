import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_locale_controller.dart';

/// Navigation preference only. Professional permissions always come from the API.
class AccountEntryController extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(appPreferencesProvider)?.getBool('fixo.entry.pro') == true;

  Future<void> selectProfessional(bool value) async {
    state = value;
    final preferences = ref.read(appPreferencesProvider);
    if (preferences != null &&
        !await preferences.setBool('fixo.entry.pro', value)) {
      throw StateError('Account preference could not be saved.');
    }
  }
}

final professionalEntryProvider =
    NotifierProvider<AccountEntryController, bool>(AccountEntryController.new);

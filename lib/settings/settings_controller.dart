import 'package:flutter/foundation.dart';

import 'app_settings.dart';

abstract interface class SettingsPersistence {
  Future<void> save(AppSettings value);
}

class SettingsController extends ChangeNotifier {
  SettingsController(this._store, this.value);
  final SettingsPersistence _store;
  AppSettings value;

  Future<void> update(AppSettings next) async {
    value = next;
    notifyListeners();
    await _store.save(next);
  }
}

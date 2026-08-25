import 'package:flutter/foundation.dart';

import 'app_settings.dart';
import 'settings_store.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._store, this.value);
  final SettingsStore _store;
  AppSettings value;

  Future<void> update(AppSettings next) async {
    value = next;
    notifyListeners();
    await _store.save(next);
  }
}

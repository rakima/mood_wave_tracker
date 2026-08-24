import 'package:flutter/material.dart';

import 'app.dart';
import 'data/mood_record_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MoodWaveApp(store: MoodRecordRepository()));
}

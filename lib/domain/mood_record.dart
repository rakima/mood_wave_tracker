class MoodRecord {
  MoodRecord({
    required DateTime date,
    required this.maniaLevel,
    required this.depressionLevel,
    required this.sleepHours,
    required this.tookMedication,
    this.memo = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : date = dateOnly(date),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    validate();
  }

  final DateTime date;
  final int maniaLevel;
  final int depressionLevel;
  final double sleepHours;
  final bool tookMedication;
  final String memo;
  final DateTime createdAt;
  final DateTime updatedAt;

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String dateKey(DateTime value) {
    final day = dateOnly(value);
    return '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
  }

  void validate() {
    if (maniaLevel < 0 || maniaLevel > 5) {
      throw ArgumentError.value(maniaLevel, 'maniaLevel', 'must be 0 to 5');
    }
    if (depressionLevel < 0 || depressionLevel > 5) {
      throw ArgumentError.value(
        depressionLevel,
        'depressionLevel',
        'must be 0 to 5',
      );
    }
    if (!sleepHours.isFinite || sleepHours < 0 || sleepHours > 24) {
      throw ArgumentError.value(sleepHours, 'sleepHours', 'must be 0 to 24');
    }
  }

  Map<String, Object?> toMap() => {
        'date': dateKey(date),
        'mania_level': maniaLevel,
        'depression_level': depressionLevel,
        'sleep_hours': sleepHours,
        'took_medication': tookMedication ? 1 : 0,
        'memo': memo.trim(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory MoodRecord.fromMap(Map<String, Object?> map) => MoodRecord(
        date: DateTime.parse(map['date']! as String),
        maniaLevel: map['mania_level']! as int,
        depressionLevel: map['depression_level']! as int,
        sleepHours: (map['sleep_hours']! as num).toDouble(),
        tookMedication: map['took_medication'] == 1,
        memo: map['memo'] as String? ?? '',
        createdAt: DateTime.parse(map['created_at']! as String),
        updatedAt: DateTime.parse(map['updated_at']! as String),
      );
}

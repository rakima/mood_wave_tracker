import 'package:flutter/material.dart';

import '../data/mood_record_store.dart';
import '../domain/chart_point.dart';
import '../domain/mood_record.dart';
import '../l10n/app_strings.dart';
import '../settings/app_settings.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({required this.store, required this.language, super.key});
  final MoodRecordStore store;
  final AppLanguage language;
  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  int _days = 30;
  @override
  Widget build(BuildContext context) {
    final s = AppStrings(widget.language);
    final today = MoodRecord.dateOnly(DateTime.now());
    final from = today.subtract(Duration(days: _days - 1));
    return FutureBuilder<List<MoodRecord>>(
      future: widget.store.findBetween(from, today),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data!;
        final points = records.map(toChartPoint).toList();
        return CustomScrollView(slivers: [
          SliverAppBar.large(title: Text(s.t('状態グラフ', 'Mood chart'))),
          SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList.list(children: [
                Row(children: [
                  Expanded(
                      child: Text(s.t('表示期間', 'Period'),
                          style: Theme.of(context).textTheme.titleMedium)),
                  SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 7, label: Text('7日')),
                      ButtonSegment(value: 30, label: Text('30日')),
                      ButtonSegment(value: 90, label: Text('90日')),
                    ],
                    selected: {_days},
                    onSelectionChanged: (value) =>
                        setState(() => _days = value.first),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(s.t('点をタップすると、その日の詳細を確認できます。',
                    'Tap a point to see that day’s details.')),
                const SizedBox(height: 12),
                Row(children: [
                  _Legend(
                      color: Colors.red.shade400, label: s.t('躁 ＋', 'Mania +')),
                  const SizedBox(width: 20),
                  _Legend(
                      color: Colors.blue.shade400,
                      label: s.t('鬱 －', 'Depression −')),
                ]),
                const SizedBox(height: 12),
                AspectRatio(
                    aspectRatio: 0.8,
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant),
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: LayoutBuilder(
                              builder: (context, constraints) =>
                                  GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTapUp: (details) => _showNearest(
                                          context,
                                          records,
                                          details.localPosition,
                                          constraints.biggest,
                                          from,
                                          s),
                                      child: CustomPaint(
                                          painter: MoodChartPainter(
                                              points: points,
                                              from: from,
                                              dayCount: _days,
                                              maniaColor: Colors.red.shade400,
                                              depressionColor:
                                                  Colors.blue.shade400,
                                              lineColor: Theme.of(context)
                                                  .colorScheme
                                                  .outlineVariant,
                                              zeroColor: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                              textColor: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant)))),
                        ))),
                if (points.isEmpty)
                  Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Center(
                          child: Text(s.t(
                              '期間内の記録はまだありません', 'No records in this period')))),
              ])),
        ]);
      },
    );
  }

  void _showNearest(BuildContext context, List<MoodRecord> records, Offset tap,
      Size size, DateTime from, AppStrings s) {
    if (records.isEmpty) return;
    const left = 34.0, right = 8.0;
    final plotWidth = size.width - left - right;
    MoodRecord? nearest;
    var nearestDistance = double.infinity;
    for (final record in records) {
      final day = record.date.difference(from).inDays;
      final x = left + plotWidth * day / (_days - 1);
      final distance = (tap.dx - x).abs();
      if (distance < nearestDistance) {
        nearest = record;
        nearestDistance = distance;
      }
    }
    if (nearest == null || nearestDistance > 24) return;
    final record = nearest;
    showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${record.date.year}/${record.date.month}/${record.date.day}',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Text(
                        '${s.t('躁', 'Mania')} +${record.maniaLevel}　${s.t('鬱', 'Depression')} -${record.depressionLevel}'),
                    Text(
                        '${s.t('睡眠', 'Sleep')} ${record.sleepHours}h　${s.t('服薬', 'Medication')} ${record.tookMedication ? '○' : '×'}'),
                    if (record.memo.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(record.memo)),
                  ]),
            ));
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 20,
            height: 4,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label)
      ]);
}

class MoodChartPainter extends CustomPainter {
  MoodChartPainter(
      {required this.points,
      required this.from,
      required this.dayCount,
      required this.maniaColor,
      required this.depressionColor,
      required this.lineColor,
      required this.zeroColor,
      required this.textColor});
  final List<MoodChartPoint> points;
  final DateTime from;
  final int dayCount;
  final Color maniaColor, depressionColor, lineColor, zeroColor, textColor;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0, right = 8.0, top = 12.0, bottom = 30.0;
    final width = size.width - left - right,
        height = size.height - top - bottom;
    final bandHeight = height / 10;
    for (var distance = 1; distance <= 5; distance++) {
      final alpha = 0.018 + distance * 0.012;
      canvas.drawRect(
          Rect.fromLTWH(
              left, top + (5 - distance) * bandHeight, width, bandHeight),
          Paint()..color = maniaColor.withValues(alpha: alpha));
      canvas.drawRect(
          Rect.fromLTWH(
              left, top + (4 + distance) * bandHeight, width, bandHeight),
          Paint()..color = depressionColor.withValues(alpha: alpha));
    }
    for (var value = -5; value <= 5; value++) {
      final y = _y(value, top, height);
      canvas.drawLine(
          Offset(left, y),
          Offset(left + width, y),
          Paint()
            ..color = value == 0 ? zeroColor : lineColor
            ..strokeWidth = value == 0 ? 2.2 : 1);
      _text(canvas, value > 0 ? '+$value' : '$value', Offset(0, y - 7));
    }
    _series(canvas, points, (p) => p.maniaValue, maniaColor, left, top, width,
        height);
    _series(canvas, points, (p) => p.depressionValue, depressionColor, left,
        top, width, height);
    for (var index = 0; index < 5; index++) {
      final day = ((dayCount - 1) * index / 4).round();
      final date = from.add(Duration(days: day));
      final x = left + width * day / (dayCount - 1);
      _centeredText(canvas, '${date.month}/${date.day}', x, top + height + 8,
          left, left + width);
    }
  }

  void _series(
      Canvas canvas,
      Iterable<MoodChartPoint> values,
      int Function(MoodChartPoint) valueOf,
      Color color,
      double left,
      double top,
      double width,
      double height) {
    final series = values.toList();
    final path = Path();
    for (var i = 0; i < series.length; i++) {
      final day = series[i].date.difference(from).inDays;
      final point = Offset(left + width * day / (dayCount - 1),
          _y(valueOf(series[i]), top, height));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
    for (final value in series) {
      final day = value.date.difference(from).inDays;
      canvas.drawCircle(
          Offset(left + width * day / (dayCount - 1),
              _y(valueOf(value), top, height)),
          5,
          Paint()..color = color);
    }
  }

  double _y(int value, double top, double height) =>
      top + (5 - value) * height / 10;
  void _text(Canvas canvas, String value, Offset offset) {
    final p = TextPainter(
        text: TextSpan(
            text: value,
            style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: value == '0' ? FontWeight.bold : null)),
        textDirection: TextDirection.ltr)
      ..layout();
    p.paint(canvas, offset);
  }

  void _centeredText(
      Canvas canvas, String value, double x, double y, double min, double max) {
    final p = TextPainter(
        text: TextSpan(
            text: value, style: TextStyle(color: textColor, fontSize: 10)),
        textDirection: TextDirection.ltr)
      ..layout();
    p.paint(canvas, Offset((x - p.width / 2).clamp(min - 4, max - p.width), y));
  }

  @override
  bool shouldRepaint(covariant MoodChartPainter old) =>
      old.points != points ||
      old.dayCount != dayCount ||
      old.textColor != textColor;
}

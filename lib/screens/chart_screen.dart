import 'package:flutter/material.dart';

import '../data/mood_record_store.dart';
import '../domain/chart_point.dart';
import '../domain/mood_record.dart';
import '../l10n/app_strings.dart';
import '../settings/app_settings.dart';

class ChartScreen extends StatelessWidget {
  const ChartScreen({required this.store, required this.language, super.key});

  final MoodRecordStore store;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(language);
    final today = MoodRecord.dateOnly(DateTime.now());
    final from = today.subtract(const Duration(days: 29));
    return FutureBuilder<List<MoodRecord>>(
      future: store.findBetween(from, today),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final points = snapshot.data!.map(toChartPoint).toList();
        return CustomScrollView(
          slivers: [
            SliverAppBar.large(title: Text(strings.t('状態グラフ', 'Mood chart'))),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList.list(children: [
                Text(strings.t('直近30日', 'Last 30 days'),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(strings.t('0から上下に離れるほど、状態の振れが大きいことを表します。',
                    'Distance from 0 shows the size of the mood swing.')),
                const SizedBox(height: 16),
                Row(children: [
                  _Legend(
                      color: Colors.red.shade400,
                      label: strings.t('躁 ＋', 'Mania +')),
                  const SizedBox(width: 20),
                  _Legend(
                      color: Colors.blue.shade400,
                      label: strings.t('鬱 －', 'Depression −')),
                ]),
                const SizedBox(height: 12),
                AspectRatio(
                  aspectRatio: 0.8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: CustomPaint(
                        painter: MoodChartPainter(
                          points: points,
                          from: from,
                          maniaColor: Colors.red.shade400,
                          depressionColor: Colors.blue.shade400,
                          lineColor:
                              Theme.of(context).colorScheme.outlineVariant,
                          zeroColor: Theme.of(context).colorScheme.onSurface,
                          textColor:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                if (points.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Center(
                        child: Text(strings.t(
                            '期間内の記録はまだありません', 'No records in this period'))),
                  ),
              ]),
            ),
          ],
        );
      },
    );
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
        Text(label),
      ]);
}

class MoodChartPainter extends CustomPainter {
  MoodChartPainter({
    required this.points,
    required this.from,
    required this.maniaColor,
    required this.depressionColor,
    required this.lineColor,
    required this.zeroColor,
    required this.textColor,
  });

  final List<MoodChartPoint> points;
  final DateTime from;
  final Color maniaColor;
  final Color depressionColor;
  final Color lineColor;
  final Color zeroColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0;
    const right = 8.0;
    const top = 12.0;
    const bottom = 30.0;
    final width = size.width - left - right;
    final height = size.height - top - bottom;
    final bandHeight = height / 10;

    for (var distance = 1; distance <= 5; distance++) {
      final alpha = 0.018 + distance * 0.012;
      final positiveTop = top + (5 - distance) * bandHeight;
      final negativeTop = top + (4 + distance) * bandHeight;
      canvas.drawRect(Rect.fromLTWH(left, positiveTop, width, bandHeight),
          Paint()..color = maniaColor.withValues(alpha: alpha));
      canvas.drawRect(Rect.fromLTWH(left, negativeTop, width, bandHeight),
          Paint()..color = depressionColor.withValues(alpha: alpha));
    }

    for (var value = -5; value <= 5; value++) {
      final y = _y(value, top, height);
      canvas.drawLine(
        Offset(left, y),
        Offset(left + width, y),
        Paint()
          ..color = value == 0 ? zeroColor : lineColor
          ..strokeWidth = value == 0 ? 2.2 : 1,
      );
      _text(canvas, value > 0 ? '+$value' : '$value', Offset(0, y - 7));
    }

    _drawSeries(canvas, points.where((point) => point.maniaValue > 0).toList(),
        (point) => point.maniaValue, maniaColor, left, top, width, height);
    _drawSeries(
        canvas,
        points.where((point) => point.depressionValue < 0).toList(),
        (point) => point.depressionValue,
        depressionColor,
        left,
        top,
        width,
        height);

    for (final day in [0, 7, 14, 21, 29]) {
      final date = from.add(Duration(days: day));
      final x = left + width * day / 29;
      final label = '${date.month}/${date.day}';
      final painter = TextPainter(
        text: TextSpan(
            text: label, style: TextStyle(color: textColor, fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
          canvas,
          Offset(
              (x - painter.width / 2)
                  .clamp(left - 4, left + width - painter.width),
              top + height + 8));
    }
  }

  void _drawSeries(
      Canvas canvas,
      List<MoodChartPoint> series,
      int Function(MoodChartPoint) valueOf,
      Color color,
      double left,
      double top,
      double width,
      double height) {
    final path = Path();
    for (var index = 0; index < series.length; index++) {
      final point = series[index];
      final day = MoodRecord.dateOnly(point.date).difference(from).inDays;
      final offset =
          Offset(left + width * day / 29, _y(valueOf(point), top, height));
      if (index == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
    for (final point in series) {
      final day = MoodRecord.dateOnly(point.date).difference(from).inDays;
      canvas.drawCircle(
          Offset(left + width * day / 29, _y(valueOf(point), top, height)),
          4,
          Paint()..color = color);
    }
  }

  double _y(int value, double top, double height) =>
      top + (5 - value) * height / 10;

  void _text(Canvas canvas, String text, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: text == '0' ? FontWeight.bold : null)),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant MoodChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.textColor != textColor;
}

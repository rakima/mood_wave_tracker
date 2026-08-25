import 'package:flutter/material.dart';

class LevelSelector extends StatelessWidget {
  const LevelSelector({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.highColor,
    super.key,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final Color highColor;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(colors: [
                highColor.withValues(alpha: 0),
                highColor.withValues(alpha: 0.22),
              ]),
            ),
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              style: const ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(Colors.transparent),
              ),
              segments: [
                for (var level = 0; level <= 5; level++)
                  ButtonSegment(value: level, label: Text('$level')),
              ],
              selected: {value},
              onSelectionChanged: (selection) => onChanged(selection.first),
            ),
          ),
        ],
      );
}

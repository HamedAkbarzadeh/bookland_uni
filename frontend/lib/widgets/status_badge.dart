import 'package:flutter/material.dart';
import '../core/utils/formatters.dart';

class StatusBadge extends StatelessWidget {
  final String? condition;
  final String? status;

  const StatusBadge({super.key, this.condition, this.status});

  @override
  Widget build(BuildContext context) {
    final String text = condition != null
        ? Formatters.conditionToPersian(condition)
        : Formatters.statusToPersian(status);

    final Color color = condition != null
        ? Formatters.conditionColor(condition)
        : Formatters.statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

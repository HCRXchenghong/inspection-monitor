import 'package:flutter/material.dart';
import '../models/threat_level.dart';

/// 威胁等级标签
class ThreatBadge extends StatelessWidget {
  final ThreatLevel level;
  final bool compact;

  const ThreatBadge({super.key, required this.level, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: level.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(level.icon, size: 12, color: level.color),
            const SizedBox(width: 4),
            Text(
              level.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: level.color,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: level.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: level.color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(level.icon, size: 16, color: level.color),
          const SizedBox(width: 6),
          Text(
            level.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: level.color,
            ),
          ),
        ],
      ),
    );
  }
}

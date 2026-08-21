import 'package:flutter/material.dart';
import '../theme/eleme_theme.dart';

/// 威胁等级枚举
enum ThreatLevel {
  critical, // 极高
  high, // 高
  medium, // 中
  low, // 低
}

/// 从分数转换为威胁等级
ThreatLevel threatLevelFromScore(int score) {
  if (score >= 70) return ThreatLevel.critical;
  if (score >= 40) return ThreatLevel.high;
  if (score >= 20) return ThreatLevel.medium;
  return ThreatLevel.low;
}

extension ThreatLevelX on ThreatLevel {
  String get label {
    switch (this) {
      case ThreatLevel.critical:
        return '极高威胁';
      case ThreatLevel.high:
        return '高威胁';
      case ThreatLevel.medium:
        return '中威胁';
      case ThreatLevel.low:
        return '低威胁';
    }
  }

  String get description {
    switch (this) {
      case ThreatLevel.critical:
        return '几乎确定是摄像头，建议立即排查物理位置';
      case ThreatLevel.high:
        return '高度可疑，建议重点检查';
      case ThreatLevel.medium:
        return '有一定可疑性，建议留意';
      case ThreatLevel.low:
        return '可能是普通设备';
    }
  }

  Color get color {
    switch (this) {
      case ThreatLevel.critical:
        return ElemeTheme.danger;
      case ThreatLevel.high:
        return ElemeTheme.accent;
      case ThreatLevel.medium:
        return ElemeTheme.warning;
      case ThreatLevel.low:
        return ElemeTheme.safe;
    }
  }

  IconData get icon {
    switch (this) {
      case ThreatLevel.critical:
        return Icons.dangerous;
      case ThreatLevel.high:
        return Icons.warning_amber_rounded;
      case ThreatLevel.medium:
        return Icons.info_outline;
      case ThreatLevel.low:
        return Icons.check_circle_outline;
    }
  }
}

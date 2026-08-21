import 'threat_level.dart';

/// BLE 扫描发现的蓝牙设备
class BleDevice {
  final String id;
  final String name;
  final int rssi;
  final bool isConnectable;

  BleDevice({
    required this.id,
    required this.name,
    required this.rssi,
    this.isConnectable = true,
  });

  /// 是否为可疑设备名
  bool get isSuspiciousName {
    final lower = name.toLowerCase();
    const keywords = [
      'camera', 'cam', 'ipc', 'webcam', 'hidden', 'spy',
      'p2p', 'hd-', 'hdcam', 'video', 'lens',
      '摄像', '隐藏', '偷拍',
    ];
    return keywords.any((k) => lower.contains(k));
  }

  /// RSSI 信号强度判断距离
  /// >-40: 极近 (<1m)
  /// -40~-60: 近 (1-3m)
  /// -60~-80: 中 (3-10m)
  /// <-80: 远 (>10m)
  String get distanceLabel {
    if (rssi > -40) return '极近 (<1米)';
    if (rssi > -60) return '近 (1-3米)';
    if (rssi > -80) return '中 (3-10米)';
    return '远 (>10米)';
  }

  int get threatScore {
    int score = 0;
    if (isSuspiciousName) score += 40;
    if (rssi > -40) score += 20;
    if (name.isEmpty || _isRandomName) score += 15;
    return score;
  }

  bool get _isRandomName {
    // 纯数字或随机字符
    return RegExp(r'^[A-F0-9]{6,}$').hasMatch(name) ||
        RegExp(r'^[a-z0-9]{8}-[a-z0-9]{4}$').hasMatch(name);
  }

  ThreatLevel get threatLevel => threatLevelFromScore(threatScore);
}

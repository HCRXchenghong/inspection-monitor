import 'dart:io';
import 'package:wifi_scan/wifi_scan.dart';

/// Wi-Fi 热点扫描器
/// 扫描附近 Wi-Fi 网络，检测摄像头自带热点
class WifiApScanner {
  /// 可疑 SSID 模式
  static const List<String> suspiciousPatterns = [
    'p2p-', 'p2p_',
    'ipc-', 'ipc_',
    'cam-', 'cam_',
    'hd-', 'hd_',
    'hdcam', 'camera',
    'direct-', 'direct_',
    'squ-',
    'wifi-camera',
    'ipcam',
  ];

  /// 扫描附近 Wi-Fi
  static Future<List<WifiApResult>> scan() async {
    if (!Platform.isAndroid) {
      return [];
    }

    try {
      final canScan = await WiFiScan.instance.canGetScannedResults();
      if (canScan != CanGetScannedResults.yes) {
        return [];
      }

      final results = await WiFiScan.instance.getScannedResults();
      return results.map((ap) {
        return WifiApResult(
          ssid: ap.ssid,
          bssid: ap.bssid,
          level: ap.level,
          frequency: ap.frequency,
          capabilities: ap.capabilities,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// 判断 SSID 是否可疑
  static bool isSuspiciousSsid(String ssid) {
    final lower = ssid.toLowerCase();
    if (lower.isEmpty) return true; // 隐藏网络
    return suspiciousPatterns.any((p) => lower.startsWith(p) || lower.contains(p));
  }
}

/// Wi-Fi AP 扫描结果
class WifiApResult {
  final String ssid;
  final String? bssid;
  final int level;
  final int? frequency;
  final String? capabilities;

  WifiApResult({
    required this.ssid,
    this.bssid,
    required this.level,
    this.frequency,
    this.capabilities,
  });

  /// 信号强度标签
  String get levelLabel {
    if (level > -50) return '极强';
    if (level > -65) return '强';
    if (level > -75) return '中';
    return '弱';
  }

  bool get isHidden => ssid.isEmpty;

  bool get isSuspicious => WifiApScanner.isSuspiciousSsid(ssid);
}

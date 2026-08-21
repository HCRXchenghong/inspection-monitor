import 'dart:io';
import 'package:flutter/services.dart';

/// ARP 表读取服务
/// Android: 通过 Platform Channel 读取 /proc/net/arp
/// iOS: 不支持,回退到纯端口扫描
class ArpService {
  static const _platform = MethodChannel('com.security.room_guard/arp');

  /// 读取 ARP 表,返回 `Map<IP, MAC>`
  static Future<Map<String, String>> getArpTable() async {
    if (Platform.isAndroid) {
      try {
        final result = await _platform.invokeMethod('getArpTable');
        if (result is Map) {
          return result.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      } catch (e) {
        // Platform channel 失败,尝试 Dart fallback
      }
    }
    // iOS 或 Platform Channel 失败:无法读取 ARP 表
    return {};
  }

  /// Ping sweep 扫描子网,触发设备进入 ARP 表
  /// 并发 ping 整个子网 (256 个地址)
  static Future<void> pingSweep(String subnet, {int timeoutMs = 300}) async {
    final futures = <Future>[];
    for (int i = 1; i < 255; i++) {
      final ip = '$subnet.$i';
      futures.add(_pingPort(ip, timeoutMs));
      // 每批 32 个,避免过多并发
      if (futures.length >= 32) {
        await Future.wait(futures);
        futures.clear();
      }
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  /// 通过 TCP 连接 80 端口来触发 ARP (纯 Dart,不需要 ICMP)
  static Future<void> _pingPort(String ip, int timeoutMs) async {
    try {
      final socket = await Socket.connect(ip, 80, timeout: Duration(milliseconds: timeoutMs));
      socket.destroy();
    } catch (_) {
      // 连接失败也 OK,目的是触发 ARP 表更新
    }
  }
}

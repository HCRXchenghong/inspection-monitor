import 'dart:io';
import 'dart:async';

/// 端口扫描器 (纯 Dart TCP connect)
class PortScanner {
  /// 摄像头典型端口
  static const List<int> cameraPorts = [
    554,   // RTSP
    8554,  // RTSP 备用
    1935,  // RTMP
    80,    // HTTP
    8080,  // HTTP 备用
    8888,  // HTTP 国产
    23,    // Telnet
    9000,  // IoT
    34567, // 国产摄像头
    49152, // ONVIF
  ];

  /// 扫描单个 IP 的多个端口
  static Future<Set<int>> scanHost(String ip, {Duration timeout = const Duration(milliseconds: 400)}) async {
    final openPorts = <int>{};
    final futures = <Future<void>>[];

    for (final port in cameraPorts) {
      futures.add(_scanPort(ip, port, timeout).then((isOpen) {
        if (isOpen) openPorts.add(port);
      }));
    }
    await Future.wait(futures);
    return openPorts;
  }

  /// 扫描整个子网
  /// onProgress 回调 (scanned, total)
  /// onDeviceFound 回调 (ip, openPorts)
  static Future<void> scanSubnet(
    String subnet, {
    Duration timeout = const Duration(milliseconds: 400),
    void Function(int scanned, int total)? onProgress,
    void Function(String ip, Set<int> openPorts)? onDeviceFound,
  }) async {
    final total = 254;
    var scanned = 0;

    // 每批并发 16 个 IP
    for (int base = 1; base <= 254; base += 16) {
      final end = (base + 15).clamp(1, 254);
      final futures = <Future<void>>[];

      for (int i = base; i <= end; i++) {
        final ip = '$subnet.$i';
        futures.add(scanHost(ip, timeout: timeout).then((ports) {
          if (ports.isNotEmpty) {
            onDeviceFound?.call(ip, ports);
          }
        }));
      }
      await Future.wait(futures);
      scanned = end;
      onProgress?.call(scanned, total);
    }
  }

  /// 扫描单个端口
  static Future<bool> _scanPort(String ip, int port, Duration timeout) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: timeout);
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 获取端口含义
  static String portDescription(int port) {
    switch (port) {
      case 554:
        return 'RTSP 实时流传输';
      case 8554:
        return 'RTSP 备用';
      case 1935:
        return 'RTMP 推流';
      case 80:
        return 'HTTP Web 管理界面';
      case 8080:
        return 'HTTP Web 备用端口';
      case 8888:
        return 'HTTP 国产摄像头端口';
      case 23:
        return 'Telnet 调试口';
      case 9000:
        return 'IoT 服务端口';
      case 34567:
        return '国产摄像头默认端口';
      case 49152:
        return 'ONVIF 设备发现';
      default:
        return '未知服务';
    }
  }

  /// 判断端口是否为高威胁流媒体端口
  static bool isStreamingPort(int port) {
    return port == 554 || port == 8554 || port == 1935 || port == 34567;
  }
}

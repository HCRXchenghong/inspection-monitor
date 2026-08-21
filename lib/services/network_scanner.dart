import 'dart:async';
import 'package:network_info_plus/network_info_plus.dart';
import '../models/network_device.dart';
import 'arp_service.dart';
import 'port_scanner.dart';
import 'mdns_scanner.dart';
import 'upnp_scanner.dart';
import 'onvif_scanner.dart';
import 'http_probe_service.dart';
import 'oui_database.dart';

/// 网络扫描调度器 - 协调所有扫描方法
class NetworkScanner {
  final _info = NetworkInfo();

  // 扫描状态
  final Map<String, NetworkDevice> _devices = {};
  final _progressController = StreamController<ScanProgress>.broadcast();
  final _deviceController = StreamController<List<NetworkDevice>>.broadcast();

  Stream<ScanProgress> get progressStream => _progressController.stream;
  Stream<List<NetworkDevice>> get deviceStream => _deviceController.stream;
  List<NetworkDevice> get devices => _devices.values.toList();

  String? _gatewayIp;
  String? _localIp;
  String? _subnet;

  String? get gatewayIp => _gatewayIp;
  String? get localIp => _localIp;
  String? get subnet => _subnet;

  /// 开始全量扫描
  Future<List<NetworkDevice>> scan() async {
    _devices.clear();
    _progressController.add(ScanProgress(phase: '初始化', progress: 0.0));

    // 1. 获取网络信息
    await _getNetworkInfo();
    if (_subnet == null) {
      _progressController.add(ScanProgress(phase: '未连接 Wi-Fi', progress: 0.0, error: '请先连接 Wi-Fi'));
      return [];
    }

    // 2. Ping sweep + ARP 表 (并行)
    _progressController.add(ScanProgress(phase: '扫描局域网设备...', progress: 0.1));
    await Future.wait([
      ArpService.pingSweep(_subnet!),
      _scanArpTableDelayed(),
    ]);

    // 3. 并行执行所有扫描方法
    _progressController.add(ScanProgress(phase: '端口扫描...', progress: 0.2));
    final futures = <Future>[
      _scanPorts(),
      _scanMdns(),
      _scanUpnp(),
      _scanOnvif(),
      _scanArpTable(),
    ];
    await Future.wait(futures);

    // 4. HTTP 探测有 Web 端口的设备
    _progressController.add(ScanProgress(phase: 'HTTP 探测...', progress: 0.7));
    await _probeHttp();

    // 5. 计算威胁评分
    _progressController.add(ScanProgress(phase: '分析威胁...', progress: 0.9));
    _calculateThreatScores();
    _notifyDevices();

    _progressController.add(ScanProgress(phase: '扫描完成', progress: 1.0));
    return _devices.values.toList();
  }

  /// 获取网络信息
  Future<void> _getNetworkInfo() async {
    try {
      _localIp = await _info.getWifiIP();
      _gatewayIp = await _info.getWifiGatewayIP();
      if (_localIp != null) {
        final parts = _localIp!.split('.');
        if (parts.length >= 3) {
          _subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
        }
      }
    } catch (_) {}
  }

  /// 延迟读取 ARP 表 (等待 ping sweep 触发设备)
  Future<void> _scanArpTableDelayed() async {
    await Future.delayed(const Duration(seconds: 2));
  }

  /// 读取 ARP 表
  Future<void> _scanArpTable() async {
    final arpTable = await ArpService.getArpTable();
    for (final entry in arpTable.entries) {
      final ip = entry.key;
      final mac = entry.value;
      if (ip == _localIp) continue; // 跳过本机

      final vendor = OuiDatabase.lookupVendor(mac);
      _mergeDevice(NetworkDevice(
        ip: ip,
        mac: mac,
        vendor: vendor,
      ));
    }
    _notifyDevices();
  }

  /// 端口扫描
  Future<void> _scanPorts() async {
    if (_subnet == null) return;

    await PortScanner.scanSubnet(
      _subnet!,
      onProgress: (scanned, total) {
        final progress = 0.2 + 0.3 * (scanned / total);
        _progressController.add(ScanProgress(phase: '端口扫描 $scanned/$total', progress: progress));
      },
      onDeviceFound: (ip, ports) {
        _mergeDevice(NetworkDevice(
          ip: ip,
          openPorts: ports,
        ));
      },
    );
    _notifyDevices();
  }

  /// mDNS 扫描
  Future<void> _scanMdns() async {
    final results = await MdnsScanner.scan();
    for (final r in results) {
      _mergeDevice(NetworkDevice(
        ip: r.ip,
        mdnsName: r.name,
        mdnsServiceType: r.serviceType,
      ));
    }
    _notifyDevices();
  }

  /// UPnP 扫描
  Future<void> _scanUpnp() async {
    final results = await UpnpScanner.scan();
    for (final r in results) {
      _mergeDevice(NetworkDevice(
        ip: r.ip,
        upnpServer: r.server,
        upnpDeviceType: r.st,
      ));
    }
    _notifyDevices();
  }

  /// ONVIF 扫描
  Future<void> _scanOnvif() async {
    final ips = await OnvifScanner.scan();
    for (final ip in ips) {
      _mergeDevice(NetworkDevice(
        ip: ip,
        onvifDetected: true,
      ));
    }
    _notifyDevices();
  }

  /// HTTP 探测
  Future<void> _probeHttp() async {
    final httpPorts = [80, 8080, 8888];
    final futures = <Future>[];

    for (final device in _devices.values.toList()) {
      for (final port in httpPorts) {
        if (device.openPorts.contains(port)) {
          futures.add(
            HttpProbeService.probe(device.ip, port: port).then((result) {
              if (result != null) {
                _mergeDevice(NetworkDevice(
                  ip: device.ip,
                  httpTitle: result.title,
                  httpServer: result.server,
                ));
              }
            }),
          );
        }
      }
    }

    await Future.wait(futures);
    _notifyDevices();
  }

  /// 计算威胁评分
  void _calculateThreatScores() {
    for (final ip in _devices.keys.toList()) {
      final device = _devices[ip]!;
      var score = 0;
      final reasons = <String>[];

      // RTSP 端口
      if (device.openPorts.contains(554)) {
        score += 40;
        reasons.add('RTSP 端口 554 开放');
      }
      if (device.openPorts.contains(8554)) {
        score += 25;
        reasons.add('RTSP 备用端口 8554 开放');
      }
      if (device.openPorts.contains(1935)) {
        score += 25;
        reasons.add('RTMP 推流端口 1935 开放');
      }
      if (device.openPorts.contains(34567)) {
        score += 30;
        reasons.add('国产摄像头端口 34567 开放');
      }

      // 摄像头厂商 MAC
      if (OuiDatabase.isCameraVendor(device.vendor)) {
        score += 30;
        reasons.add('MAC 厂商为摄像头品牌: ${device.vendor}');
      }

      // mDNS 摄像头服务
      if (device.mdnsServiceType != null && MdnsScanner.isCameraService(device.mdnsServiceType!)) {
        score += 35;
        reasons.add('mDNS 发现摄像头服务: ${device.mdnsServiceType}');
      }

      // mDNS 名称关键词
      if (device.mdnsName != null && MdnsScanner.isCameraName(device.mdnsName!)) {
        score += 30;
        reasons.add('mDNS 设备名含摄像头关键词: ${device.mdnsName}');
      }

      // UPnP 摄像头类型
      final upnpResult = UpnpResult(ip: device.ip, server: device.upnpServer, st: device.upnpDeviceType);
      if (UpnpScanner.isCameraResponse(upnpResult)) {
        score += 35;
        reasons.add('UPnP 响应含摄像头标识');
      }

      // ONVIF
      if (device.onvifDetected) {
        score += 40;
        reasons.add('ONVIF WS-Discovery 响应');
      }

      // HTTP 标题关键词
      if (device.httpTitle != null) {
        final lower = device.httpTitle!.toLowerCase();
        if (HttpProbeService.cameraKeywords.any((k) => lower.contains(k))) {
          score += 25;
          reasons.add('Web 界面标题含摄像头关键词: ${device.httpTitle}');
        }
      }

      // 多端口开放
      if (device.openPorts.length >= 3) {
        score += 15;
        reasons.add('开放 ${device.openPorts.length} 个端口');
      }

      // 未知厂商 MAC
      if (device.mac != null && device.vendor == null) {
        score += 10;
        reasons.add('未知 MAC 厂商');
      }

      // 已知安全设备减分
      if (OuiDatabase.isKnownSafeVendor(device.vendor)) {
        score -= 20;
      }

      score = score.clamp(0, 100);

      _devices[ip] = device.copyWith(
        threatScore: score,
        threatReasons: reasons,
      );
    }
  }

  /// 合并设备信息
  void _mergeDevice(NetworkDevice newDevice) {
    final existing = _devices[newDevice.ip];
    if (existing != null) {
      _devices[newDevice.ip] = existing.merge(newDevice);
    } else {
      _devices[newDevice.ip] = newDevice;
    }
  }

  /// 通知设备更新
  void _notifyDevices() {
    final sorted = _devices.values.toList()
      ..sort((a, b) => b.threatScore.compareTo(a.threatScore));
    _deviceController.add(sorted);
  }

  void dispose() {
    _progressController.close();
    _deviceController.close();
  }
}

/// 扫描进度
class ScanProgress {
  final String phase;
  final double progress;
  final String? error;

  ScanProgress({required this.phase, required this.progress, this.error});
}

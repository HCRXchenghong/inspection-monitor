import 'threat_level.dart';

/// 扫描发现的网络设备
class NetworkDevice {
  final String ip;
  final String? mac;
  final String? vendor;
  final Set<int> openPorts;
  final String? mdnsName;
  final String? mdnsServiceType;
  final String? upnpDeviceType;
  final String? upnpServer;
  final bool onvifDetected;
  final String? httpTitle;
  final String? httpServer;
  final int threatScore;
  final List<String> threatReasons;

  NetworkDevice({
    required this.ip,
    this.mac,
    this.vendor,
    this.openPorts = const {},
    this.mdnsName,
    this.mdnsServiceType,
    this.upnpDeviceType,
    this.upnpServer,
    this.onvifDetected = false,
    this.httpTitle,
    this.httpServer,
    this.threatScore = 0,
    this.threatReasons = const [],
  });

  ThreatLevel get threatLevel => threatLevelFromScore(threatScore);

  String get displayName {
    if (mdnsName != null && mdnsName!.isNotEmpty) return mdnsName!;
    if (vendor != null && vendor!.isNotEmpty) return vendor!;
    return ip;
  }

  /// 判断是否为已知的手机/平板/电脑厂商 (安全设备)
  bool get isKnownSafeVendor {
    if (vendor == null) return false;
    const safeVendors = [
      'apple', 'samsung', 'huawei', 'xiaomi', 'oppo', 'vivo',
      'honhai', 'hon-hai', 'dell', 'lenovo', 'asus', 'acer',
      'intel', 'realtek', 'netgear', 'tenda router',
    ];
    final v = vendor!.toLowerCase();
    return safeVendors.any((s) => v.contains(s));
  }

  NetworkDevice copyWith({
    String? ip,
    String? mac,
    String? vendor,
    Set<int>? openPorts,
    String? mdnsName,
    String? mdnsServiceType,
    String? upnpDeviceType,
    String? upnpServer,
    bool? onvifDetected,
    String? httpTitle,
    String? httpServer,
    int? threatScore,
    List<String>? threatReasons,
  }) {
    return NetworkDevice(
      ip: ip ?? this.ip,
      mac: mac ?? this.mac,
      vendor: vendor ?? this.vendor,
      openPorts: openPorts ?? this.openPorts,
      mdnsName: mdnsName ?? this.mdnsName,
      mdnsServiceType: mdnsServiceType ?? this.mdnsServiceType,
      upnpDeviceType: upnpDeviceType ?? this.upnpDeviceType,
      upnpServer: upnpServer ?? this.upnpServer,
      onvifDetected: onvifDetected ?? this.onvifDetected,
      httpTitle: httpTitle ?? this.httpTitle,
      httpServer: httpServer ?? this.httpServer,
      threatScore: threatScore ?? this.threatScore,
      threatReasons: threatReasons ?? this.threatReasons,
    );
  }

  /// 合并两个同 IP 设备的信息
  NetworkDevice merge(NetworkDevice other) {
    if (ip != other.ip) return this;
    return copyWith(
      mac: mac ?? other.mac,
      vendor: vendor ?? other.vendor,
      openPorts: openPorts.union(other.openPorts),
      mdnsName: mdnsName ?? other.mdnsName,
      mdnsServiceType: mdnsServiceType ?? other.mdnsServiceType,
      upnpDeviceType: upnpDeviceType ?? other.upnpDeviceType,
      upnpServer: upnpServer ?? other.upnpServer,
      onvifDetected: onvifDetected || other.onvifDetected,
      httpTitle: httpTitle ?? other.httpTitle,
      httpServer: httpServer ?? other.httpServer,
    );
  }
}

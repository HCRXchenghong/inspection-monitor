import 'package:multicast_dns/multicast_dns.dart';

/// mDNS / Bonjour 设备发现
class MdnsScanner {
  /// 扫描结果
  static Future<List<MdnsResult>> scan({Duration timeout = const Duration(seconds: 5)}) async {
    final results = <MdnsResult>[];
    final client = MDnsClient();

    const serviceTypes = [
      '_rtsp._tcp',
      '_onvif._tcp',
      '_http._tcp',
      '_camera._tcp',
      '_video._tcp',
      '_svc._tcp',
      '_airplay._tcp',
      '_googlecast._tcp',
      '_ipp._tcp',
      '_sonos._tcp',
    ];

    await client.start();

    for (final type in serviceTypes) {
      try {
        final ptrStream = client.lookup<PtrResourceRecord>(
          ResourceRecordQuery.serverPointer(type),
        );
        await for (final ptr in ptrStream) {
          try {
            final srvStream = client.lookup<SrvResourceRecord>(
              ResourceRecordQuery.service(ptr.domainName),
            );
            await for (final srv in srvStream) {
              final ipStream = client.lookup<IPAddressResourceRecord>(
                ResourceRecordQuery.addressIPv4(srv.target),
              );
              await for (final ip in ipStream) {
                final name = srv.target.toString().replaceAll('.', '');
                results.add(MdnsResult(
                  ip: ip.address.address,
                  name: name,
                  serviceType: type,
                ));
              }
            }
          } catch (_) {
            // 单条记录失败不影响整体
          }
        }
      } catch (_) {
        // 单个服务类型失败不影响整体
      }
    }

    client.stop();
    return results;
  }

  /// 判断 mDNS 名称是否含摄像头关键词
  static bool isCameraName(String name) {
    final lower = name.toLowerCase();
    const keywords = ['camera', 'cam', 'ipc', 'webcam', 'hik', 'dahua',
                      'nvr', 'dvr', 'video', 'onvif', 'lens', 'hd-'];
    return keywords.any((k) => lower.contains(k));
  }

  /// 判断服务类型是否为摄像头相关
  static bool isCameraService(String type) {
    return type == '_rtsp._tcp' || type == '_onvif._tcp' ||
           type == '_camera._tcp' || type == '_video._tcp';
  }
}

/// mDNS 扫描结果
class MdnsResult {
  final String ip;
  final String name;
  final String serviceType;

  MdnsResult({required this.ip, required this.name, required this.serviceType});
}

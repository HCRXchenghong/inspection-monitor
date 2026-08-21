import 'dart:io';
import 'dart:async';

/// UPnP / SSDP 设备发现
class UpnpScanner {
  static const _ssdpAddress = '239.255.255.250';
  static const _ssdpPort = 1900;

  /// 发送 SSDP M-SEARCH 并监听响应
  static Future<List<UpnpResult>> scan({Duration timeout = const Duration(seconds: 5)}) async {
    final results = <UpnpResult>[];
    final completer = Completer<List<UpnpResult>>();
    final seenIps = <String>{};

    try {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4, 0,
        reuseAddress: true,
        ttl: 2,
      );

      // 开启多播
      // 发送 M-SEARCH 消息
      final searchMessage = StringBuffer();
      searchMessage.write('M-SEARCH * HTTP/1.1\r\n');
      searchMessage.write('HOST: $_ssdpAddress:$_ssdpPort\r\n');
      searchMessage.write('MAN: "ssdp:discover"\r\n');
      searchMessage.write('MX: 3\r\n');
      searchMessage.write('ST: ssdp:all\r\n\r\n');

      final data = searchMessage.toString().codeUnits;
      socket.send(data, InternetAddress(_ssdpAddress), _ssdpPort);

      // 监听响应
      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            final response = String.fromCharCodes(datagram.data);
            final ip = datagram.address.address;

            if (!seenIps.contains(ip)) {
              seenIps.add(ip);
              final result = _parseResponse(response, ip);
              if (result != null) results.add(result);
            }
          }
        }
      });

      // 超时后返回结果
      Future.delayed(timeout, () {
        if (!completer.isCompleted) {
          socket.close();
          completer.complete(results);
        }
      });
    } catch (e) {
      if (!completer.isCompleted) completer.complete(results);
    }

    return completer.future;
  }

  /// 解析 SSDP 响应
  static UpnpResult? _parseResponse(String response, String ip) {
    String? server;
    String? st;
    String? location;

    for (final line in response.split('\r\n')) {
      final lower = line.toLowerCase();
      if (lower.startsWith('server:')) {
        server = line.substring(7).trim();
      } else if (lower.startsWith('st:')) {
        st = line.substring(3).trim();
      } else if (lower.startsWith('location:')) {
        location = line.substring(9).trim();
      }
    }

    return UpnpResult(
      ip: ip,
      server: server,
      st: st,
      location: location,
    );
  }

  /// 判断 UPnP 响应是否为摄像头
  static bool isCameraResponse(UpnpResult result) {
    final text = '${result.server ?? ''} ${result.st ?? ''}'.toLowerCase();
    const keywords = ['camera', 'ipcamera', 'networkcamera', 'webcam',
                      'ipc', 'dvr', 'nvr', 'hikvision', 'dahua', 'video'];
    return keywords.any((k) => text.contains(k));
  }
}

/// UPnP 扫描结果
class UpnpResult {
  final String ip;
  final String? server;
  final String? st;
  final String? location;

  UpnpResult({required this.ip, this.server, this.st, this.location});
}

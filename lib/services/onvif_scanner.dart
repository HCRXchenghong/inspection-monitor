import 'dart:io';
import 'dart:async';

/// ONVIF WS-Discovery 发现
/// ONVIF 是 IP 摄像头的行业标准协议
class OnvifScanner {
  static const _wsdisAddress = '239.255.255.250';
  static const _wsdisPort = 3702;

  /// WS-Discovery Probe 消息 (SOAP/UDP)
  static const _probeMessage = '''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"
  xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing"
  xmlns:wsd="http://schemas.xmlsoap.org/ws/2005/04/discovery"
  xmlns:tds="http://www.onvif.org/ver10/device/wsdl">
  <soap:Header>
    <wsa:MessageID>uuid:roomguard-probe</wsa:MessageID>
    <wsa:To>urn:schemas-xmlsoap-org:ws:2005:04:discovery</wsa:To>
    <wsa:Action>http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe</wsa:Action>
  </soap:Header>
  <soap:Body>
    <wsd:Probe>
      <wsd:Types>tds:Device</wsd:Types>
    </wsd:Probe>
  </soap:Body>
</soap:Envelope>''';

  /// 发送 Probe 并监听响应
  static Future<List<String>> scan({Duration timeout = const Duration(seconds: 5)}) async {
    final ips = <String>[];
    final seenIps = <String>{};
    final completer = Completer<List<String>>();

    try {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4, 0,
        reuseAddress: true,
        ttl: 2,
      );

      // 发送 WS-Discovery Probe
      final data = _probeMessage.codeUnits;
      socket.send(data, InternetAddress(_wsdisAddress), _wsdisPort);

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            final ip = datagram.address.address;
            final response = String.fromCharCodes(datagram.data);

            // 检查是否为 ONVIF 设备响应
            if ((response.contains('ProbeMatch') ||
                 response.contains('tds:Device') ||
                 response.contains('onvif') ||
                 response.contains('Device'))) {
              if (!seenIps.contains(ip)) {
                seenIps.add(ip);
                ips.add(ip);
              }
            }
          }
        }
      });

      Future.delayed(timeout, () {
        if (!completer.isCompleted) {
          socket.close();
          completer.complete(ips);
        }
      });
    } catch (e) {
      if (!completer.isCompleted) completer.complete(ips);
    }

    return completer.future;
  }
}

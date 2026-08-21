import 'package:http/http.dart' as http;
import 'dart:convert';

/// HTTP 探测服务
/// 对开放 80/8080/8888 端口的设备尝试 HTTP GET,分析 Web 界面
class HttpProbeService {
  /// 摄像头 Web 界面常见关键词
  static const List<String> cameraKeywords = [
    'camera', 'ipc', 'dvr', 'nvr', 'webcam', 'hikvision', 'dahua',
    'foscam', 'reolink', 'amcrest', 'ipcam', 'ip cam',
    'h.264', 'h.265', 'h264', 'h265', 'video', 'rtsp',
    'onvif', 'surveillance', 'security camera',
    '摄像头', '监控', '录像',
  ];

  /// 探测单个设备的 Web 界面
  static Future<HttpProbeResult?> probe(String ip, {int port = 80, Duration timeout = const Duration(seconds: 2)}) async {
    try {
      final url = 'http://$ip:$port/';
      final response = await http.get(Uri.parse(url)).timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 401) {
        final body = response.body;
        final title = _extractTitle(body);
        final server = response.headers['server'];

        return HttpProbeResult(
          ip: ip,
          port: port,
          title: title,
          server: server,
          isCamera: _isCameraPage(title, server, body),
        );
      }
    } catch (_) {
      // 连接失败
    }
    return null;
  }

  /// 从 HTML 中提取 <title> 标签内容
  static String? _extractTitle(String html) {
    final match = RegExp(
      r'<title[^>]*>(.*?)</title>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(html);
    if (match != null) {
      final title = match.group(1)?.trim() ?? '';
      // 处理可能的编码问题
      try {
        return utf8.decode(title.codeUnits);
      } catch (_) {
        return title;
      }
    }
    return null;
  }

  /// 判断是否为摄像头 Web 界面
  static bool _isCameraPage(String? title, String? server, String body) {
    final combined = '${title ?? ''} ${server ?? ''} ${body.length > 5000 ? body.substring(0, 5000) : body}'.toLowerCase();
    return cameraKeywords.any((k) => combined.contains(k));
  }
}

/// HTTP 探测结果
class HttpProbeResult {
  final String ip;
  final int port;
  final String? title;
  final String? server;
  final bool isCamera;

  HttpProbeResult({
    required this.ip,
    required this.port,
    this.title,
    this.server,
    required this.isCamera,
  });
}

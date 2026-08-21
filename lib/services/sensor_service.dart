import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

/// 磁力计服务 - 检测磁场异常
class SensorService {
  StreamSubscription<MagnetometerEvent>? _subscription;
  final _controller = StreamController<MagneticData>.broadcast();

  Stream<MagneticData> get dataStream => _controller.stream;

  /// 正常地磁场范围 (μT)
  static const double normalMinField = 25.0;
  static const double normalMaxField = 65.0;
  /// 异常阈值
  static const double anomalyThreshold = 100.0;

  bool get isAvailable => _subscription != null;

  /// 开始监听磁力计
  void start() {
    _subscription?.cancel();
    _subscription = magnetometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen((event) {
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      final data = MagneticData(
        x: event.x,
        y: event.y,
        z: event.z,
        magnitude: magnitude,
        isAnomaly: magnitude > anomalyThreshold,
      );
      _controller.add(data);
    });
  }

  /// 停止监听
  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }
}

/// 磁力计数据
class MagneticData {
  final double x;
  final double y;
  final double z;
  final double magnitude;
  final bool isAnomaly;

  MagneticData({
    required this.x,
    required this.y,
    required this.z,
    required this.magnitude,
    required this.isAnomaly,
  });

  /// 强度等级标签
  String get levelLabel {
    if (magnitude < 30) return '正常 (低)';
    if (magnitude < 65) return '正常';
    if (magnitude < 100) return '偏高';
    if (magnitude < 200) return '异常';
    return '强异常';
  }
}

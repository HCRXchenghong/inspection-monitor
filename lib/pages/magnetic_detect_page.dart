import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/eleme_theme.dart';
import '../services/sensor_service.dart';

class MagneticDetectPage extends StatefulWidget {
  const MagneticDetectPage({super.key});

  @override
  State<MagneticDetectPage> createState() => _MagneticDetectPageState();
}

class _MagneticDetectPageState extends State<MagneticDetectPage> {
  final _sensor = SensorService();
  MagneticData? _data;
  bool _monitoring = false;
  bool _sensorAvailable = true;
  double _maxMagnitude = 0;

  @override
  void initState() {
    super.initState();
    _sensor.dataStream.listen((data) {
      if (mounted) {
        setState(() {
          _data = data;
          if (data.magnitude > _maxMagnitude) {
            _maxMagnitude = data.magnitude;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _sensor.dispose();
    super.dispose();
  }

  void _toggleMonitoring() {
    if (_monitoring) {
      _sensor.stop();
      setState(() => _monitoring = false);
    } else {
      try {
        _sensor.start();
        setState(() {
          _monitoring = true;
          _maxMagnitude = 0;
        });
      } catch (_) {
        setState(() => _sensorAvailable = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('磁场检测')),
      body: !_sensorAvailable
          ? _buildUnavailable()
          : Column(
              children: [
                _buildGauge(),
                _buildDataPanel(),
                const Spacer(),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildGauge() {
    final magnitude = _data?.magnitude ?? 0;
    final isAnomaly = _data?.isAnomaly ?? false;
    final color = _getColor(magnitude);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isAnomaly ? ElemeTheme.danger : ElemeTheme.divider, width: isAnomaly ? 2 : 1),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: MagneticGaugePainter(magnitude, color, isAnomaly),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      magnitude.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const Text('μT', style: TextStyle(fontSize: 14, color: ElemeTheme.textTertiary)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _data?.levelLabel ?? '等待检测',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(double magnitude) {
    if (magnitude < 30) return ElemeTheme.safe;
    if (magnitude < 65) return ElemeTheme.primary;
    if (magnitude < 100) return ElemeTheme.warning;
    if (magnitude < 200) return ElemeTheme.accent;
    return ElemeTheme.danger;
  }

  Widget _buildDataPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ElemeTheme.divider),
      ),
      child: Column(
        children: [
          _axisRow('X 轴', _data?.x ?? 0),
          const SizedBox(height: 8),
          _axisRow('Y 轴', _data?.y ?? 0),
          const SizedBox(height: 8),
          _axisRow('Z 轴', _data?.z ?? 0),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          _axisRow('峰值', _maxMagnitude, isHighlight: true),
        ],
      ),
    );
  }

  Widget _axisRow(String label, double value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: ElemeTheme.textTertiary)),
        Text(
          '${value.toStringAsFixed(1)} μT',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isHighlight ? ElemeTheme.accent : ElemeTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '将手机贴近可疑位置 (烟雾报警器、插座、相框等)，\n磁场值 > 100 μT 表示附近有电子器件',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: ElemeTheme.textTertiary),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _toggleMonitoring,
            icon: Icon(_monitoring ? Icons.stop : Icons.play_arrow, size: 20),
            label: Text(_monitoring ? '停止检测' : '开始检测'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildUnavailable() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sensors_off, size: 64, color: ElemeTheme.textTertiary),
            const SizedBox(height: 16),
            const Text('磁力计不可用', style: TextStyle(fontSize: 16, color: ElemeTheme.textSecondary)),
            const SizedBox(height: 8),
            const Text('您的设备没有地磁传感器', style: TextStyle(fontSize: 13, color: ElemeTheme.textTertiary)),
          ],
        ),
      ),
    );
  }
}

/// 磁力计仪表盘画笔
class MagneticGaugePainter extends CustomPainter {
  final double magnitude;
  final Color color;
  final bool isAnomaly;

  MagneticGaugePainter(this.magnitude, this.color, this.isAnomaly);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // 背景圆环
    final bgPaint = Paint()
      ..color = ElemeTheme.divider
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius, bgPaint);

    // 进度弧 (0-250 μT 映射到 270 度)
    final normalized = (magnitude / 250).clamp(0.0, 1.0);
    final sweep = normalized * 270;

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -math.pi * 0.75, sweep * math.pi / 180, false, arcPaint);

    // 异常闪烁圆点
    if (isAnomaly) {
      final alertPaint = Paint()
        ..color = ElemeTheme.danger
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius + 4, alertPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

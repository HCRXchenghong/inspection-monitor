import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/eleme_theme.dart';

class IrDetectPage extends StatefulWidget {
  const IrDetectPage({super.key});

  @override
  State<IrDetectPage> createState() => _IrDetectPageState();
}

class _IrDetectPageState extends State<IrDetectPage> {
  CameraController? _controller;
  bool _detecting = false;
  bool _cameraError = false;
  List<Offset> _irSpots = [];
  final bool _isFrontCamera = true;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _cameraError = true);
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() => _cameraError = true);
      return;
    }

    // 优先使用前置摄像头 (通常无 IR 滤光片)
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();
    _controller!.startImageStream(_analyzeImage);

    if (mounted) setState(() {});
  }

  void _analyzeImage(CameraImage image) {
    if (!_detecting || image.planes.length < 3) return;

    // 分析 U/V 色度通道 (YUV420)
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final width = image.width;
    final height = image.height;

    final spots = <Offset>[];

    // 采样色度通道 (色度分辨率为亮度的一半)
    const sampleSize = 16;
    for (int y = 0; y < height; y += sampleSize * 2) {
      for (int x = 0; x < width; x += sampleSize * 2) {
        final uvIdx = (y ~/ 2) * (uPlane.bytesPerRow) + (x ~/ 2);
        if (uvIdx >= vPlane.bytes.length || uvIdx >= uPlane.bytes.length) continue;

        // V 值偏高 = 偏红 (IR 光源在 CMOS 上常表现为红色/紫色偏移)
        final vVal = vPlane.bytes[uvIdx];
        // U 值偏低 = 偏暖
        final uVal = uPlane.bytes[uvIdx];
        // 亮度
        final yIdx = y * yPlane.bytesPerRow + x;
        if (yIdx >= yPlane.bytes.length) continue;
        final yVal = yPlane.bytes[yIdx];

        // IR 光源特征: 在暗环境中,V 值显著高于 U 值 (偏红)
        // 且亮度值不是极高 (区别于正常亮光源)
        if (vVal > 200 && vVal > uVal + 30 && yVal < 200 && yVal > 30) {
          spots.add(Offset(
            x.toDouble() / width,
            y.toDouble() / height,
          ));
        }
      }
    }

    // 去重 (相邻点合并)
    final deduped = <Offset>[];
    for (final spot in spots) {
      bool tooClose = false;
      for (final existing in deduped) {
        if ((spot - existing).distance < 0.05) {
          tooClose = true;
          break;
        }
      }
      if (!tooClose) deduped.add(spot);
    }

    if (mounted) {
      setState(() => _irSpots = deduped.length <= 10 ? deduped : []);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraError) {
      return Scaffold(
        appBar: AppBar(title: const Text('红外检测')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt, size: 64, color: ElemeTheme.textTertiary),
                const SizedBox(height: 16),
                const Text('无法访问相机', style: TextStyle(fontSize: 16, color: ElemeTheme.textSecondary)),
                const SizedBox(height: 8),
                const Text('请在系统设置中授予相机权限', style: TextStyle(fontSize: 13, color: ElemeTheme.textTertiary)),
              ],
            ),
          ),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('红外检测')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / _controller!.value.previewSize!.height;

    return Scaffold(
      appBar: AppBar(title: const Text('红外检测')),
      body: Stack(
        children: [
          Center(
            child: Transform.scale(
              scale: deviceRatio,
              child: CameraPreview(_controller!),
            ),
          ),
          if (_detecting && _irSpots.isNotEmpty)
            CustomPaint(
              painter: IrSpotPainter(_irSpots),
              size: size,
            ),
          // 顶部提示
          if (_detecting)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildAlertBanner(),
            ),
          // 底部控制栏
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner() {
    final hasAlert = _irSpots.isNotEmpty;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: hasAlert ? ElemeTheme.danger.withValues(alpha: 0.9) : ElemeTheme.primary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(hasAlert ? Icons.warning : Icons.visibility, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasAlert
                ? '检测到 ${_irSpots.length} 个疑似红外光源!可能是夜视摄像头'
                : '关灯全黑环境,缓慢扫描房间各角落',
              style: const TextStyle(fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _isFrontCamera ? '当前: 前置摄像头 (推荐)' : '当前: 后置摄像头',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '关闭所有灯光 → 全黑环境 → 开始检测 → 扫描房间',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => setState(() {
              _detecting = !_detecting;
              if (!_detecting) _irSpots = [];
            }),
            icon: Icon(_detecting ? Icons.stop : Icons.play_arrow, size: 20),
            label: Text(_detecting ? '停止检测' : '开始检测'),
          ),
        ],
      ),
    );
  }
}

/// IR 光斑标记画笔
class IrSpotPainter extends CustomPainter {
  final List<Offset> spots;

  IrSpotPainter(this.spots);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ElemeTheme.danger
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final fillPaint = Paint()
      ..color = ElemeTheme.danger.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    for (final spot in spots) {
      final dx = spot.dx * size.width;
      final dy = spot.dy * size.height;
      canvas.drawCircle(Offset(dx, dy), 25, fillPaint);
      canvas.drawCircle(Offset(dx, dy), 25, paint);
      canvas.drawLine(Offset(dx - 33, dy), Offset(dx - 17, dy), paint);
      canvas.drawLine(Offset(dx + 17, dy), Offset(dx + 33, dy), paint);
      canvas.drawLine(Offset(dx, dy - 33), Offset(dx, dy - 17), paint);
      canvas.drawLine(Offset(dx, dy + 17), Offset(dx, dy + 33), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

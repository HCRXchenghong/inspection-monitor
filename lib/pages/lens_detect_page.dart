import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/eleme_theme.dart';

class LensDetectPage extends StatefulWidget {
  const LensDetectPage({super.key});

  @override
  State<LensDetectPage> createState() => _LensDetectPageState();
}

class _LensDetectPageState extends State<LensDetectPage> {
  CameraController? _controller;
  bool _torchOn = false;
  bool _detecting = false;
  bool _cameraError = false;
  List<Offset> _brightSpots = [];

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

    // 优先选择后置摄像头
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();

    // 开启手电筒
    try {
      await _controller!.setFlashMode(FlashMode.torch);
      setState(() => _torchOn = true);
    } catch (_) {
      // 某些设备不支持
    }

    // 开始帧分析
    _controller!.startImageStream(_analyzeImage);

    if (mounted) setState(() {});
  }

  void _analyzeImage(CameraImage image) {
    if (!_detecting) return;

    // 分析 Y 通道 (亮度)
    final yPlane = image.planes[0];
    final bytes = yPlane.bytes;
    final width = image.width;
    final height = image.height;

    final spots = <Offset>[];

    // 采样: 每 8x8 像素取一个点
    const sampleSize = 8;
    for (int y = 0; y < height; y += sampleSize) {
      for (int x = 0; x < width; x += sampleSize) {
        final idx = y * yPlane.bytesPerRow + x;
        if (idx < bytes.length) {
          final val = bytes[idx];
          if (val > 240) {
            // 极亮点
            spots.add(Offset(
              x.toDouble() / width,
              y.toDouble() / height,
            ));
            
          }
        }
      }
    }

    if (spots.isNotEmpty && spots.length <= 20) {
      // 1-20 个亮点 = 可能是镜头反光 (不是大面积过曝)
      if (mounted) {
        setState(() {
          _brightSpots = spots;
        });
      }
    } else if (spots.isEmpty) {
      if (mounted) setState(() => _brightSpots = []);
    } else {
      // 超过 20 个亮点 = 大面积过曝,不是反光
      if (mounted) setState(() => _brightSpots = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraError) {
      return Scaffold(
        appBar: AppBar(title: const Text('镜头检测')),
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
        appBar: AppBar(title: const Text('镜头检测')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / _controller!.value.previewSize!.height;

    return Scaffold(
      appBar: AppBar(title: const Text('镜头检测')),
      body: Stack(
        children: [
          // 相机预览
          Center(
            child: Transform.scale(
              scale: deviceRatio,
              child: CameraPreview(_controller!),
            ),
          ),
          // 亮点标记
          if (_detecting && _brightSpots.isNotEmpty)
            CustomPaint(
              painter: BrightSpotPainter(_brightSpots, size),
              size: size,
            ),
          // 底部控制栏
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(),
          ),
          // 顶部提示
          if (_detecting)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildAlertBanner(),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner() {
    final hasAlert = _brightSpots.isNotEmpty;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: hasAlert ? ElemeTheme.danger.withValues(alpha: 0.9) : ElemeTheme.primary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            hasAlert ? Icons.warning : Icons.search,
            size: 18,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasAlert
                ? '检测到 ${_brightSpots.length} 个可疑反光点!请仔细检查该区域'
                : '缓慢移动手机扫描房间各角落',
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
          const Text(
            '关灯 → 开启检测 → 对准可疑区域缓慢移动',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // 手电筒开关
              GestureDetector(
                onTap: _toggleTorch,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _torchOn ? ElemeTheme.accent : Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.flash_on,
                    color: _torchOn ? Colors.white : Colors.white54,
                    size: 24,
                  ),
                ),
              ),
              const Spacer(),
              // 检测开关
              ElevatedButton.icon(
                onPressed: () => setState(() {
                  _detecting = !_detecting;
                  if (!_detecting) _brightSpots = [];
                }),
                icon: Icon(_detecting ? Icons.stop : Icons.play_arrow, size: 20),
                label: Text(_detecting ? '停止检测' : '开始检测'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTorch() async {
    try {
      _torchOn = !_torchOn;
      await _controller!.setFlashMode(_torchOn ? FlashMode.torch : FlashMode.off);
      setState(() {});
    } catch (_) {
      setState(() => _torchOn = !_torchOn);
    }
  }
}

/// 亮点标记画笔
class BrightSpotPainter extends CustomPainter {
  final List<Offset> spots;
  final Size screenSize;

  BrightSpotPainter(this.spots, this.screenSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ElemeTheme.danger
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (final spot in spots) {
      final dx = spot.dx * size.width;
      final dy = spot.dy * size.height;
      canvas.drawCircle(Offset(dx, dy), 20, paint);
      // 十字准星
      canvas.drawLine(Offset(dx - 28, dy), Offset(dx - 12, dy), paint);
      canvas.drawLine(Offset(dx + 12, dy), Offset(dx + 28, dy), paint);
      canvas.drawLine(Offset(dx, dy - 28), Offset(dx, dy - 12), paint);
      canvas.drawLine(Offset(dx, dy + 12), Offset(dx, dy + 28), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/eleme_theme.dart';
import '../widgets/feature_button.dart';
import 'network_scan_page.dart';
import 'lens_detect_page.dart';
import 'ir_detect_page.dart';
import 'magnetic_detect_page.dart';
import 'ble_scan_page.dart';
import 'checklist_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    super.initState();
    _checkAvailability();
    _setStatusBar();
  }

  void _setStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: ElemeTheme.primary,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _checkAvailability() {
    // 各功能可用性在各自页面检查
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElemeTheme.background,
      body: CustomScrollView(
        slivers: [
          // 顶部蓝色区域
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),
          // 功能入口
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '检测功能',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: ElemeTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureGrid(),
                ],
              ),
            ),
          ),
          // 安全提示
          SliverToBoxAdapter(
            child: _buildTips(),
          ),
          // 使用说明
          SliverToBoxAdapter(
            child: _buildGuide(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ElemeTheme.primary, ElemeTheme.primaryLight],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.shield, size: 28, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RoomGuard',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '酒店防偷拍检测工具',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '建议先连接酒店 Wi-Fi，然后从网络扫描开始检测',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: [
        FeatureButton(
          icon: Icons.wifi_find,
          label: '网络扫描',
          subtitle: '扫描 Wi-Fi 局域网设备',
          color: ElemeTheme.primary,
          onTap: () => _navigateTo(const NetworkScanPage()),
        ),
        FeatureButton(
          icon: Icons.bluetooth_searching,
          label: '蓝牙扫描',
          subtitle: '检测附近 BLE 设备',
          color: const Color(0xFF0082FC),
          onTap: () => _navigateTo(const BleScanPage()),
        ),
        FeatureButton(
          icon: Icons.camera_alt,
          label: '镜头检测',
          subtitle: '闪光灯反光检测',
          color: ElemeTheme.accent,
          onTap: () => _navigateTo(const LensDetectPage()),
        ),
        FeatureButton(
          icon: Icons.visibility,
          label: '红外检测',
          subtitle: '夜视红外补光检测',
          color: const Color(0xFFD63031),
          onTap: () => _navigateTo(const IrDetectPage()),
        ),
        FeatureButton(
          icon: Icons.explore,
          label: '磁场检测',
          subtitle: '电子器件磁场探测',
          color: const Color(0xFF6C5CE7),
          onTap: () => _navigateTo(const MagneticDetectPage()),
        ),
        FeatureButton(
          icon: Icons.checklist,
          label: '排查清单',
          subtitle: '人工排查引导',
          color: ElemeTheme.safe,
          onTap: () => _navigateTo(const ChecklistPage()),
        ),
      ],
    );
  }

  Widget _buildTips() {
    final tips = [
      {'icon': Icons.lightbulb_outline, 'text': '关灯全黑环境检测效果最佳'},
      {'icon': Icons.lightbulb_outline, 'text': '双面镜检测:指甲贴镜面，有缝=普通镜'},
      {'icon': Icons.lightbulb_outline, 'text': '多种方法交叉验证，提高检出率'},
      {'icon': Icons.lightbulb_outline, 'text': '断电法:关总电源，仍有指示灯=有电池'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ElemeTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tips_and_updates, size: 18, color: ElemeTheme.accent),
              SizedBox(width: 6),
              Text(
                '检测技巧',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ElemeTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(tip['icon'] as IconData, size: 14, color: ElemeTheme.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tip['text'] as String,
                    style: const TextStyle(fontSize: 13, color: ElemeTheme.textSecondary),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildGuide() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ElemeTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ElemeTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.school, size: 18, color: ElemeTheme.primary),
              SizedBox(width: 6),
              Text(
                '使用流程',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ElemeTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _stepItem('1', '连接酒店 Wi-Fi'),
          _stepItem('2', '点击"网络扫描"开始扫描'),
          _stepItem('3', '查看设备列表，关注标红设备'),
          _stepItem('4', '用镜头/红外检测进一步排查'),
          _stepItem('5', '按排查清单逐一检查房间'),
        ],
      ),
    );
  }

  Widget _stepItem(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: ElemeTheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13, color: ElemeTheme.textSecondary)),
        ],
      ),
    );
  }

  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }
}

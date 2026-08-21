import 'dart:io';
import 'package:flutter/material.dart';
import 'theme/eleme_theme.dart';
import 'pages/home_page.dart';
import 'pages/network_scan_page.dart';
import 'pages/lens_detect_page.dart';
import 'pages/ir_detect_page.dart';
import 'pages/magnetic_detect_page.dart';
import 'pages/ble_scan_page.dart';
import 'pages/checklist_page.dart';

class RoomGuardApp extends StatelessWidget {
  const RoomGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoomGuard - 酒店防偷拍检测',
      debugShowCheckedModeBanner: false,
      theme: ElemeTheme.lightTheme,
      home: const _MainShell(),
    );
  }
}

class _MainShell extends StatefulWidget {
  const _MainShell();

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _currentIndex = 0;

  final _pages = [
    const HomePage(),
    const _DetectionCenterPage(),
    const _GuidePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.shield_outlined), activeIcon: Icon(Icons.shield), label: '检测'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book), label: '指南'),
        ],
      ),
    );
  }
}

/// 检测中心 - 快速入口列表 (无蓝色头部,纯列表)
class _DetectionCenterPage extends StatelessWidget {
  const _DetectionCenterPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('检测中心')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTile(
            context,
            icon: Icons.wifi_find,
            title: '网络扫描',
            subtitle: '扫描 Wi-Fi 局域网设备，识别摄像头',
            color: ElemeTheme.primary,
            page: const NetworkScanPage(),
          ),
          _buildTile(
            context,
            icon: Icons.bluetooth_searching,
            title: '蓝牙扫描',
            subtitle: '检测附近 BLE 蓝牙设备',
            color: const Color(0xFF0082FC),
            page: const BleScanPage(),
          ),
          _buildTile(
            context,
            icon: Icons.camera_alt,
            title: '镜头检测',
            subtitle: '闪光灯反光检测',
            color: ElemeTheme.accent,
            page: const LensDetectPage(),
          ),
          _buildTile(
            context,
            icon: Icons.visibility,
            title: '红外检测',
            subtitle: '夜视红外补光检测',
            color: const Color(0xFFD63031),
            page: const IrDetectPage(),
          ),
          _buildTile(
            context,
            icon: Icons.explore,
            title: '磁场检测',
            subtitle: '电子器件磁场探测',
            color: const Color(0xFF6C5CE7),
            page: const MagneticDetectPage(),
          ),
          _buildTile(
            context,
            icon: Icons.checklist,
            title: '排查清单',
            subtitle: '人工排查引导',
            color: ElemeTheme.safe,
            page: const ChecklistPage(),
          ),
          const SizedBox(height: 20),
          _buildPlatformInfo(),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Widget page,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ElemeTheme.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ElemeTheme.textPrimary)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 13, color: ElemeTheme.textTertiary)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: ElemeTheme.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformInfo() {
    return Container(
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
              Icon(Icons.phone_android, size: 16, color: ElemeTheme.primary),
              SizedBox(width: 6),
              Text('平台能力', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ElemeTheme.primary)),
            ],
          ),
          const SizedBox(height: 8),
          if (Platform.isAndroid) ...[
            _platformRow('ARP 表扫描', true),
            _platformRow('端口扫描', true),
            _platformRow('mDNS / UPnP / ONVIF', true),
            _platformRow('Wi-Fi 热点扫描', true),
            _platformRow('BLE 蓝牙扫描', true),
            _platformRow('镜头 / 红外检测', true),
            _platformRow('磁场检测', true),
          ] else ...[
            _platformRow('ARP 表扫描', false),
            _platformRow('端口扫描', true),
            _platformRow('mDNS / UPnP / ONVIF', true),
            _platformRow('Wi-Fi 热点扫描', false),
            _platformRow('BLE 蓝牙扫描', true),
            _platformRow('镜头 / 红外检测', true),
            _platformRow('磁场检测', true),
          ],
        ],
      ),
    );
  }

  Widget _platformRow(String feature, bool supported) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(supported ? Icons.check_circle : Icons.cancel, size: 16, color: supported ? ElemeTheme.safe : ElemeTheme.textTertiary),
          const SizedBox(width: 6),
          Text(feature, style: const TextStyle(fontSize: 13, color: ElemeTheme.textSecondary)),
        ],
      ),
    );
  }
}

/// 指南页
class _GuidePage extends StatelessWidget {
  const _GuidePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('防偷拍指南')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            '为什么需要检测',
            '偷拍摄像头可能隐藏在酒店房间的任何位置，通过 Wi-Fi 或独立热点实时传输画面。入住后第一时间排查是保护个人隐私的重要手段。',
            Icons.security,
          ),
          _buildSection(
            '检测方法',
            '1. 网络扫描 - 扫描 Wi-Fi 局域网内的设备，识别摄像头\n'
            '2. 蓝牙扫描 - 检测附近 BLE 设备\n'
            '3. 镜头检测 - 关灯后用闪光灯检测镜头反光\n'
            '4. 红外检测 - 用前置摄像头检测红外补光灯\n'
            '5. 磁场检测 - 用磁力计检测隐藏的电子器件\n'
            '6. 排查清单 - 人工逐项检查常见藏匿位置',
            Icons.list_alt,
          ),
          _buildSection(
            '双面镜检测法',
            '将指甲尖贴在镜面上：\n- 如果指甲和镜像之间有缝隙 → 普通镜子\n- 如果指甲和镜像直接接触 → 双面镜（可疑）',
            Icons.flip,
          ),
          _buildSection(
            '断电检测法',
            '关闭房间总电源，观察是否有设备仍然亮灯。\n如果某个设备在断电后仍然工作，说明它有独立电池供电，更可疑。',
            Icons.power_off,
          ),
          _buildSection(
            '热感检测法',
            '运行中的摄像头会微微发热。用手指触摸可疑设备表面，感受是否有异常温度。',
            Icons.thermostat,
          ),
          _buildSection(
            '局限性提醒',
            '没有任何单一手段能 100% 发现所有偷拍摄像头。\n建议多种方法交叉使用，并结合人工排查。\n高度隐蔽的针孔设备可能需要专业 RF 探测器。',
            Icons.warning_amber,
          ),
          const SizedBox(height: 32),
          const Center(child: Text('RoomGuard v1.0.1', style: TextStyle(fontSize: 12, color: ElemeTheme.textTertiary))),
          const Center(child: Text('仅供个人隐私保护使用', style: TextStyle(fontSize: 11, color: ElemeTheme.textTertiary))),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ElemeTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: ElemeTheme.primary),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ElemeTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.6, color: ElemeTheme.textSecondary)),
        ],
      ),
    );
  }
}

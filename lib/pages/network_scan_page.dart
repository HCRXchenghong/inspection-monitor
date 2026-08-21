import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/eleme_theme.dart';
import '../models/network_device.dart';
import '../models/threat_level.dart';
import '../services/network_scanner.dart';
import '../widgets/device_card.dart';

class NetworkScanPage extends StatefulWidget {
  const NetworkScanPage({super.key});

  @override
  State<NetworkScanPage> createState() => _NetworkScanPageState();
}

class _NetworkScanPageState extends State<NetworkScanPage> {
  final _scanner = NetworkScanner();
  bool _scanning = false;
  ScanProgress? _progress;
  List<NetworkDevice> _devices = [];
  ThreatLevel? _filter;

  @override
  void initState() {
    super.initState();
    _scanner.progressStream.listen((p) {
      if (mounted) setState(() => _progress = p);
      if (p.error != null) {
        _showSnackBar(p.error!, isError: true);
      }
    });
    _scanner.deviceStream.listen((devices) {
      if (mounted) setState(() => _devices = devices);
    });
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    // 请求权限
    if (!await _requestPermissions()) return;

    setState(() => _scanning = true);
    try {
      await _scanner.scan();
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      // 位置权限 (Wi-Fi 信息和 BLE 扫描需要)
      final location = await Permission.locationWhenInUse.request();
      if (!location.isGranted) {
        _showSnackBar('需要位置权限来获取 Wi-Fi 网络信息');
        return false;
      }
      // 尝试精确位置
      if (await Permission.locationWhenInUse.isDenied) {
        _showSnackBar('请在系统设置中授予位置权限');
        return false;
      }
    }
    return true;
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? ElemeTheme.danger : ElemeTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<NetworkDevice> get _filteredDevices {
    if (_filter == null) return _devices;
    return _devices.where((d) => d.threatLevel == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('网络扫描')),
      body: Column(
        children: [
          _buildNetworkInfo(),
          _buildActionBar(),
          if (_scanning) _buildProgressBar(),
          Expanded(child: _buildDeviceList()),
        ],
      ),
    );
  }

  Widget _buildNetworkInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ElemeTheme.divider),
      ),
      child: Column(
        children: [
          _infoRow('网关', _scanner.gatewayIp ?? '未连接'),
          const SizedBox(height: 8),
          _infoRow('本机 IP', _scanner.localIp ?? '未获取'),
          const SizedBox(height: 8),
          _infoRow('子网', _scanner.subnet != null ? '${_scanner.subnet}.0/24' : '未知'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: ElemeTheme.textTertiary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ElemeTheme.textPrimary)),
      ],
    );
  }

  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _scanning ? null : _startScan,
              icon: _scanning
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.radar, size: 20),
              label: Text(_scanning ? '扫描中...' : '开始扫描'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _progress?.phase ?? '准备中...',
                style: const TextStyle(fontSize: 13, color: ElemeTheme.textSecondary),
              ),
              Text(
                '${((_progress?.progress ?? 0) * 100).toInt()}%',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ElemeTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: _progress?.progress,
            backgroundColor: ElemeTheme.divider,
            valueColor: const AlwaysStoppedAnimation(ElemeTheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    if (_devices.isEmpty && !_scanning) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        if (_devices.isNotEmpty) _buildFilterBar(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredDevices.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DeviceCard(device: _filteredDevices[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 40,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _filterChip('全部', null),
          _filterChip('极高', ThreatLevel.critical),
          _filterChip('高', ThreatLevel.high),
          _filterChip('中', ThreatLevel.medium),
          _filterChip('低', ThreatLevel.low),
        ],
      ),
    );
  }

  Widget _filterChip(String label, ThreatLevel? level) {
    final selected = _filter == level;
    final color = level?.color ?? ElemeTheme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filter = level),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: selected ? 1.0 : 0.3)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_protected_setup, size: 64, color: ElemeTheme.textTertiary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            '点击开始扫描局域网设备',
            style: TextStyle(fontSize: 16, color: ElemeTheme.textTertiary),
          ),
          const SizedBox(height: 8),
          const Text(
            '请确保已连接酒店 Wi-Fi',
            style: TextStyle(fontSize: 13, color: ElemeTheme.textTertiary),
          ),
        ],
      ),
    );
  }
}

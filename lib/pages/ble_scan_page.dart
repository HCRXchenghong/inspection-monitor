import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/eleme_theme.dart';
import '../models/threat_level.dart';
import '../models/ble_device.dart';
import '../services/ble_scanner.dart';

class BleScanPage extends StatefulWidget {
  const BleScanPage({super.key});

  @override
  State<BleScanPage> createState() => _BleScanPageState();
}

class _BleScanPageState extends State<BleScanPage> {
  final _scanner = BleScanner();
  List<BleDevice> _devices = [];
  bool _scanning = false;
  String? _statusText;

  @override
  void initState() {
    super.initState();
    _scanner.devicesStream.listen((devices) {
      if (mounted) {
        setState(() {
          _devices = devices..sort((a, b) => b.threatScore.compareTo(a.threatScore));
        });
      }
    });
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    await _requestPermissions();

    setState(() {
      _scanning = true;
      _statusText = '正在扫描...';
    });

    await _scanner.startScan(duration: const Duration(seconds: 15));

    if (mounted) {
      setState(() {
        _scanning = false;
        _statusText = _devices.isEmpty ? '未发现设备' : '发现 ${_devices.length} 个设备';
      });
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.locationWhenInUse.request();
      // Android 12+ 需要蓝牙扫描权限
      if (await Permission.bluetoothScan.isDenied) {
        await Permission.bluetoothScan.request();
      }
    } else if (Platform.isIOS) {
      await Permission.bluetooth.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('蓝牙扫描')),
      body: Column(
        children: [
          _buildStatusBar(),
          Expanded(child: _buildDeviceList()),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
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
          Row(
            children: [
              Icon(Icons.bluetooth_searching, size: 20, color: ElemeTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _statusText ?? '点击开始扫描附近蓝牙设备',
                  style: const TextStyle(fontSize: 14, color: ElemeTheme.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _scanning ? null : _startScan,
            icon: _scanning
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.radar, size: 20),
            label: Text(_scanning ? '扫描中...' : '开始扫描'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    if (_devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_disabled, size: 64, color: ElemeTheme.textTertiary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('暂无设备', style: TextStyle(fontSize: 16, color: ElemeTheme.textTertiary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        return _buildDeviceCard(device);
      },
    );
  }

  Widget _buildDeviceCard(BleDevice device) {
    final isSuspicious = device.isSuspiciousName;
    final color = device.threatLevel.color;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isSuspicious ? Icons.videocam : Icons.bluetooth,
                size: 20,
                color: color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ElemeTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${device.rssi} dBm · ${device.distanceLabel}',
                    style: const TextStyle(fontSize: 12, color: ElemeTheme.textTertiary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isSuspicious)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ElemeTheme.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '可疑',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ElemeTheme.danger),
                    ),
                  ),
                if (device.rssi > -40)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ElemeTheme.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '极近',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ElemeTheme.accent),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

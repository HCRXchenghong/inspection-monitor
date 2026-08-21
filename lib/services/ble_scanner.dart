import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/ble_device.dart';

/// BLE 蓝牙设备扫描器
class BleScanner {
  StreamSubscription? _scanSubscription;
  final Map<String, BleDevice> _devices = {};
  final _controller = StreamController<List<BleDevice>>.broadcast();
  bool _scanning = false;

  Stream<List<BleDevice>> get devicesStream => _controller.stream;
  List<BleDevice> get devices => _devices.values.toList();
  bool get isScanning => _scanning;

  /// 开始扫描
  Future<void> startScan({Duration duration = const Duration(seconds: 10)}) async {
    if (_scanning) return;

    _devices.clear();
    _scanning = true;

    try {
      final isAvailable = await FlutterBluePlus.isSupported;
      if (!isAvailable) {
        _scanning = false;
        _controller.add([]);
        return;
      }

      // 设置适配器状态监听
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        await FlutterBluePlus.turnOn();
      }

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final device = BleDevice(
            id: r.device.remoteId.str,
            name: r.device.platformName.isNotEmpty ? r.device.platformName : '未知设备',
            rssi: r.rssi,
            isConnectable: r.advertisementData.connectable,
          );
          _devices[device.id] = device;
        }
        _controller.add(_devices.values.toList());
      });

      await FlutterBluePlus.startScan(
        timeout: duration,
      );

      // 扫描超时后停止
      Future.delayed(duration, () {
        if (_scanning) stopScan();
      });
    } catch (e) {
      _scanning = false;
      _controller.add(_devices.values.toList());
    }
  }

  /// 停止扫描
  Future<void> stopScan() async {
    _scanning = false;
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    _controller.add(_devices.values.toList());
  }

  /// 释放资源
  void dispose() {
    _scanSubscription?.cancel();
    _controller.close();
  }
}

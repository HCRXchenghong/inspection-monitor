import 'package:flutter/material.dart';
import '../models/threat_level.dart';
import '../theme/eleme_theme.dart';
import '../models/network_device.dart';
import 'threat_badge.dart';

/// 网络设备卡片
class DeviceCard extends StatelessWidget {
  final NetworkDevice device;
  final VoidCallback? onTap;

  const DeviceCard({super.key, required this.device, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 第一行: 设备名 + 威胁标签
              Row(
                children: [
                  _vendorAvatar(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.displayName,
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
                          device.ip,
                          style: const TextStyle(
                            fontSize: 13,
                            color: ElemeTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ThreatBadge(level: device.threatLevel, compact: true),
                ],
              ),
              // 详情区域
              if (device.mac != null || device.vendor != null) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                _detailRow('MAC', device.mac ?? '未知'),
                if (device.vendor != null)
                  _detailRow('厂商', device.vendor!),
              ],
              // 开放端口
              if (device.openPorts.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: device.openPorts.toList().asMap().entries.map((entry) {
                    final port = entry.value;
                    final isStreaming = port == 554 || port == 8554 || port == 1935 || port == 34567;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isStreaming
                            ? ElemeTheme.danger.withValues(alpha: 0.08)
                            : ElemeTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$port',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isStreaming ? ElemeTheme.danger : ElemeTheme.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              // mDNS / UPnP / ONVIF 信息
              if (device.mdnsName != null || device.onvifDetected || device.upnpServer != null) ...[
                const SizedBox(height: 8),
                if (device.mdnsName != null)
                  _infoChip(Icons.dns, 'mDNS: ${device.mdnsName}'),
                if (device.onvifDetected)
                  _infoChip(Icons.videocam, 'ONVIF 设备'),
                if (device.upnpServer != null)
                  _infoChip(Icons.router, 'UPnP: ${device.upnpServer}'),
              ],
              // HTTP 标题
              if (device.httpTitle != null) ...[
                const SizedBox(height: 6),
                _infoChip(Icons.language, device.httpTitle!),
              ],
              // 威胁原因
              if (device.threatReasons.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                ...device.threatReasons.map((reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.fiber_manual_record, size: 8, color: device.threatLevel.color),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          reason,
                          style: TextStyle(
                            fontSize: 12,
                            color: device.threatLevel.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _vendorAvatar() {
    final isCamera = device.threatLevel.index >= 2;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: (isCamera ? ElemeTheme.danger : ElemeTheme.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        isCamera ? Icons.videocam : Icons.devices,
        size: 20,
        color: isCamera ? ElemeTheme.danger : ElemeTheme.primary,
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: ElemeTheme.textTertiary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: ElemeTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: ElemeTheme.textTertiary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: ElemeTheme.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

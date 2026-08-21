/// MAC 地址 OUI (前3字节) 厂商数据库
class OuiDatabase {
  /// OUI 前缀 -> 厂商名 (所有键唯一)
  static const Map<String, String> ouiMap = {
    // ===== 摄像头/安防厂商 =====
    '28:57:18': 'Hikvision (海康威视)',
    '18:68:CB': 'Hikvision (海康威视)',
    '4C:11:BF': 'Hikvision (海康威视)',
    '54:E4:BD': 'Hikvision (海康威视)',
    '8C:E6:1D': 'Hikvision (海康威视)',
    'BC:AD:36': 'Hikvision (海康威视)',
    '0C:0E:76': 'Hikvision (海康威视)',
    '1C:05:58': 'Hikvision (海康威视)',
    'E4:3F:A2': 'Hikvision (海康威视)',
    '9C:14:7E': 'Dahua (大华)',
    '14:AF:B5': 'Dahua (大华)',
    '3C:EF:8C': 'Dahua (大华)',
    'A0:BD:1D': 'Dahua (大华)',
    'F4:91:9E': 'Dahua (大华)',
    'E0:5D:2B': 'Dahua (大华)',
    '90:02:A9': 'Foscam',
    '00:21:31': 'Foscam',
    'B0:C5:54': 'IP Camera',
    '00:6E:5C': 'VStarcam',
    '00:16:18': 'Dericam',
    'EC:17:2F': 'Dericam',
    '48:9E:BD': 'Wansview',
    '48:9E:BB': 'Wansview',
    'C0:56:E3': 'Escam',
    'D4:A6:51': 'Escam',
    '28:6C:07': 'Xiaoyi (小蚁摄像头)',
    '34:CE:00': 'Xiaoyi (小蚁摄像头)',
    '70:8C:92': 'Xiaoyi (小蚁摄像头)',
    '0C:7A:15': 'D-Link (摄像头)',
    '00:1B:2F': 'D-Link',
    '90:8D:78': 'IP Camera',
    'C8:3A:35': 'Tenda',
    '14:60:05': 'Tenda',
    '00:0E:8E': 'Tenda',
    '00:0A:F5': 'Tenda',
    'EC:08:6B': 'Tuya (IoT)',
    '10:27:36': 'Tuya (IoT)',
    'D8:F1:5B': 'Tuya (IoT)',
    '7C:87:91': 'Tuya (IoT)',
    'AC:84:3C': 'Reolink',
    'B4:6D:35': 'Reolink',
    '00:1A:2C': 'Amcrest',
    '0C:8B:31': 'Amcrest',
    'B4:E6:2D': 'Amcrest',
    '38:AF:29': 'Ezviz (萤石)',
    'E0:41:36': 'Ezviz (萤石)',
    '50:E5:49': 'Ezviz (萤石)',

    // ===== 手机/平板/电脑厂商 (安全) =====
    'AC:DE:48': 'Apple',
    '00:1C:B3': 'Apple',
    '70:56:81': 'Apple',
    'D8:30:62': 'Apple',
    'F0:18:98': 'Apple',
    '3C:22:FB': 'Apple',
    '7C:50:79': 'Apple',
    '80:91:33': 'Apple',
    '5C:95:77': 'Apple',
    '5C:AA:FD': 'Apple',
    'AC:BC:32': 'Apple',
    'A4:5E:60': 'Apple',
    '00:17:F2': 'Apple',
    'DC:2B:2A': 'Apple',
    'F4:5C:89': 'Apple',
    '00:12:FB': 'Samsung',
    '00:1B:44': 'Samsung',
    'C0:97:27': 'Samsung',
    '08:EC:6C': 'Samsung',
    '94:35:0C': 'Samsung',
    '38:AA:92': 'Samsung',
    '00:25:9E': 'Huawei',
    '48:31:9D': 'Huawei',
    '88:12:4E': 'Huawei',
    '5C:C6:6E': 'Huawei',
    '00:E0:4C': 'Huawei',
    'A4:B1:97': 'Huawei',
    '64:09:80': 'Xiaomi',
    '7C:1C:4E': 'Xiaomi',
    '0C:1D:AF': 'Xiaomi',
    'C4:0E:10': 'Xiaomi',
    '88:11:74': 'OPPO',
    '80:9A:0D': 'OPPO',
    'C0:EE:FB': 'OPPO',
    'D8:9D:67': 'OPPO',
    '8C:88:2B': 'OPPO',
    '24:9F:28': 'vivo',
    '84:8F:69': 'vivo',
    'D2:5F:22': 'vivo',
    '0C:1A:5B': 'vivo',
    'A0:0B:BA': 'vivo',

    // ===== 网络设备 =====
    '00:1F:1F': 'HonHai (富士康)',
    '00:60:6E': 'Cisco',
    '00:1D:7E': 'Cisco',
    '00:0B:BE': 'Cisco',
    '00:09:0F': 'Netgear',
    '00:1F:33': 'Netgear',
    '20:4E:7F': 'Netgear',
    '00:90:0C': 'TP-Link',
    '50:C7:BF': 'TP-Link',
    '14:E6:E8': 'TP-Link',
    'F4:EC:07': 'TP-Link',
    'B0:95:8E': 'TP-Link',
    '00:0C:29': 'Dell',
    '00:14:22': 'Dell',
    '00:15:C5': 'Dell',
    'F0:1F:AF': 'Dell',
    '00:13:02': 'Lenovo',
    '00:11:25': 'Lenovo',
    '00:16:6F': 'Lenovo',
    '00:1F:D0': 'Lenovo',
    '00:13:E8': 'Asus',
    '00:0C:6E': 'Asus',
    '00:13:46': 'Asus',
    'AC:9B:0A': 'Asus',
    '00:02:3F': 'Asus',
    '00:01:6C': 'Asus',
    '00:01:8C': 'Acer',
    '00:0A:E4': 'Acer',
    '00:02:72': 'Intel',
    '00:0B:97': 'Intel',
    'A0:88:6E': 'Intel',
    '00:1D:E0': 'Intel',
    '00:21:5D': 'Intel',
    '00:24:D6': 'Intel',
    '80:86:00': 'Micro-Star',
    '00:24:8C': 'Micro-Star',
    '00:0E:0C': 'Realtek',
    '52:54:00': 'QEMU/VM (虚拟机)',
    '00:50:56': 'VMware',
    '00:1C:42': 'Parallels',
    '08:00:27': 'VirtualBox',

    // ===== 其他常见 IoT =====
    '00:24:E4': 'Google Nest',
    '18:B4:30': 'Google Nest',
    '00:71:47': 'Google',
    'F4:F5:E8': 'Google',
    'F0:F5:60': 'Google',
    '68:DB:CA': 'Amazon Echo',
    '44:65:0D': 'Amazon Echo',
    'A0:02:25': 'Amazon',
    '0C:47:C9': 'Amazon',
    '00:17:88': 'Philips Hue',
    'EC:1B:BD': 'Philips Hue',
    '00:1A:11': 'Google',
  };

  /// 已知摄像头厂商关键词
  static const Set<String> cameraVendorKeywords = {
    'hikvision', 'dahua', 'foscam', 'vstarcam', 'dericam', 'wansview',
    'escam', 'xiaoyi', '小蚁', '萤石', 'ezviz', 'reolink', 'amcrest',
    'ip camera', 'camera', 'tuya', 'ipcam', 'ipc',
  };

  /// 根据 MAC 地址查询厂商
  static String? lookupVendor(String? mac) {
    if (mac == null || mac.isEmpty) return null;
    final clean = mac.toUpperCase().replaceAll(':', '').replaceAll('-', '');
    if (clean.length < 6) return null;
    final oui = '${clean.substring(0, 2)}:${clean.substring(2, 4)}:${clean.substring(4, 6)}';
    return ouiMap[oui];
  }

  /// 判断厂商是否为摄像头相关
  static bool isCameraVendor(String? vendor) {
    if (vendor == null) return false;
    final lower = vendor.toLowerCase();
    return cameraVendorKeywords.any((k) => lower.contains(k));
  }

  /// 判断厂商是否为已知安全设备 (手机/电脑)
  static bool isKnownSafeVendor(String? vendor) {
    if (vendor == null) return false;
    const safeKeywords = [
      'apple', 'samsung', 'huawei', 'xiaomi', 'oppo', 'vivo',
      'honhai', 'hon-hai', '富士康', 'dell', 'lenovo', 'asus',
      'acer', 'intel', 'realtek', 'netgear', 'tp-link',
      'cisco', 'd-link', 'vmware', 'virtualbox', 'parallels',
      'qemu', 'micro-star',
    ];
    final lower = vendor.toLowerCase();
    return safeKeywords.any((s) => lower.contains(s));
  }
}

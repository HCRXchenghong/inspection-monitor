# RoomGuard — 酒店防偷拍检测工具

> 基于 Flutter 构建的一站式酒店房间隐私安全检测应用。通过 Wi-Fi 网络扫描、蓝牙 BLE 扫描、镜头反光检测、红外补光检测、磁场异常检测等多种技术手段,帮助你在入住酒店时快速排查是否存在偷拍摄像头。

---

## 目录

- [功能总览](#功能总览)
- [检测原理详解](#检测原理详解)
  - [一、Wi-Fi 网络扫描](#一wi-fi-网络扫描)
  - [二、蓝牙 BLE 扫描](#二蓝牙-ble-扫描)
  - [三、镜头反光检测](#三镜头反光检测)
  - [四、红外补光检测](#四红外补光检测)
  - [五、磁场异常检测](#五磁场异常检测)
  - [六、Wi-Fi 热点扫描](#六wi-fi-热点扫描)
  - [七、人工排查清单](#七人工排查清单)
- [综合威胁评分系统](#综合威胁评分系统)
- [平台支持矩阵](#平台支持矩阵)
- [安装与使用](#安装与使用)
- [技术架构](#技术架构)
- [权限说明](#权限说明)
- [局限性说明](#局限性说明)
- [额外排查建议](#额外排查建议)
- [开发说明](#开发说明)

---

## 功能总览

| # | 功能 | 检测目标 | 技术手段 |
|---|------|---------|---------|
| 1 | Wi-Fi 网络扫描 | 连接酒店 Wi-Fi 的摄像头 | ARP 表 + 端口扫描 + mDNS + UPnP + ONVIF + HTTP 探测 |
| 2 | 蓝牙 BLE 扫描 | 用蓝牙控制/传输的摄像头 | BLE 广播扫描 |
| 3 | 镜头反光检测 | 任何带镜头的摄像头 | 手机相机 + 闪光灯 + 帧亮度分析 |
| 4 | 红外补光检测 | 带夜视红外灯的摄像头 | 前置相机 + 红外光源检测 |
| 5 | 磁场异常检测 | 隐藏的电子器件 | 地磁传感器 (磁力计) |
| 6 | Wi-Fi 热点扫描 | 自带 Wi-Fi 热点的摄像头 | 系统 Wi-Fi 扫描 API |
| 7 | 人工排查清单 | 常见藏匿位置 | 引导式检查流程 |

---

## 检测原理详解

### 一、Wi-Fi 网络扫描

这是最核心的检测手段。如果偷拍摄像头连接了酒店 Wi-Fi 进行实时视频传输,它必然是局域网中的一个可见网络设备。本应用通过 **六种技术叠加** 来发现和识别它:

#### 1.1 ARP 表扫描

**原理**:路由器维护一张 ARP (Address Resolution Protocol) 表,记录了所有同网段设备的 IP 地址和 MAC 地址映射。MAC 地址的前 3 字节 (OUI, Organizationally Unique Identifier) 是 IEEE 分配给厂商的固定编码,据此可以判断设备制造商。

**实现**:
- 通过 `network_info_plus` 获取当前 Wi-Fi 网关 IP 和本机 IP,推算子网范围 (如 `192.168.1.0/24`)
- Android 端通过 Platform Channel (Kotlin) 读取 `/proc/net/arp` 文件,直接获取局域网所有已知设备的 IP 和 MAC
- 需先执行 ping sweep 触发网络通信,使设备进入 ARP 表
- 内置 OUI 厂商数据库,自动识别设备品牌

**摄像头厂商 MAC OUI 特征**:
| 厂商 | 常见 OUI 前缀 | 说明 |
|------|-------------|------|
| Hikvision (海康威视) | 28:57:18, 18:68:CB, 4C:11:BF, 54:E4:BD, 8C:E6:1D | 全球最大安防厂商 |
| Dahua (大华) | 9C:14:7E, 14:AF:B5, 3C:EF:8C, A0:BD:1D | 第二大安防厂商 |
| Foscam | 90:02:A9, 00:21:31 | 网络摄像头 |
| VStarcam | 00:6E:5C | 云台摄像头 |
| Dericam | 00:16:18 | IP 摄像头 |
| D-Link | 00:1B:2F, 00:15:5D | 部分型号为摄像头 |
| Tenda | 00:0A:F5, C8:3A:35 | 部分IoT摄像头 |
| Xiaoyi (小蚁) | 28:6C:07 | 小米生态链摄像头 |

#### 1.2 端口扫描

**原理**:IP 摄像头几乎都会开放特定端口对外提供视频流或管理界面。通过 TCP connect 扫描可以检测目标 IP 上哪些端口处于监听状态。

**摄像头典型端口**:
| 端口 | 协议 | 含义 | 威胁权重 |
|------|------|------|---------|
| 554 | RTSP | 实时流传输协议,最典型的摄像头标志 | 极高 |
| 8554 | RTSP (备用) | 部分摄像头 RTSP 备用端口 | 高 |
| 1935 | RTMP | 实时消息协议,推流用 | 高 |
| 80 | HTTP | Web 管理界面 / 视频预览页 | 中 |
| 8080 | HTTP (备用) | 部分摄像头 Web 端口 | 中 |
| 8888 | HTTP | 部分国产摄像头 Web 端 | 中 |
| 23 | Telnet | 摄像头调试口 (老旧型号) | 中 |
| 9000 | — | 部分 IoT 摄像头 | 中 |
| 34567 | — | 部分国产摄像头默认端口 | 高 |
| 49152 | ONVIF | ONVIF 设备发现 | 中 |

**实现**:纯 Dart 实现,使用 `Socket.connect(host, port)` 带 300ms 超时,并发扫描整个子网 (256 IP × 10 端口)。通过 `compute()` 在 isolate 中执行避免阻塞 UI。

#### 1.3 mDNS / Bonjour 发现

**原理**:许多 IoT 设备 (包括摄像头) 通过 mDNS (Multicast DNS) 在局域网内主动广播自己的服务。例如 `_rtsp._tcp` 表示 RTSP 流媒体服务,`_onvif._tcp` 表示 ONVIF 兼容设备。设备名 (hostname) 中常常包含 "camera"、"IPC"、"cam"、"hik"、"dahua" 等关键词。

**实现**:使用 `multicast_dns` 包,通过 `MDnsClient` 查询以下服务类型:
- `_rtsp._tcp` — RTSP 流媒体
- `_onvif._tcp` — ONVIF 摄像头
- `_http._tcp` — HTTP 服务
- `_camera._tcp` — 摄像头 (部分厂商自定义)
- `_video._tcp` — 视频服务
- `_svc._tcp` — 通用服务发现

#### 1.4 UPnP / SSDP 发现

**原理**:支持 UPnP (通用即插即用) 的设备会响应 SSDP (简单服务发现协议) 的搜索请求。摄像头在响应中的 `ST` (Search Target) 或 `SERVER` 字段可能包含 `NetworkCamera`、`IPCamera`、`webcam` 等标识。

**实现**:使用 `RawDatagramSocket` 向 SSDP 组播地址 `239.255.255.250:1900` 发送 M-SEARCH 消息,监听设备响应:

```
M-SEARCH * HTTP/1.1
HOST: 239.255.255.250:1900
MAN: "ssdp:discover"
MX: 3
ST: ssdp:all
```

#### 1.5 ONVIF 发现

**原理**:ONVIF (Open Network Video Interface Forum) 是 IP 摄像头的行业标准协议。支持 ONVIF 的摄像头会响应 WS-Discovery 多播消息。这是比通用 SSDP 更精准的摄像头探测手段。

**实现**:使用 `RawDatagramSocket` 向 WS-Discovery 多播地址 `239.255.255.250:3702` 发送 Probe 消息 (SOAP/UDP),监听摄像头响应。响应中包含设备类型 (`tds:Device`) 和服务地址,可以确认是 IP 摄像头。

#### 1.6 HTTP 探测

**原理**:对于端口 80/8080/8888 开放的设备,尝试 HTTP GET 请求其根路径,分析响应 HTML 中的标题 (`<title>`) 和关键字。摄像头 Web 界面的标题通常包含 "camera"、"IPC"、"DVR"、"NVR"、"webcam"、"H.264"、"H.265" 等关键词。

**实现**:使用 `http` 包发送 GET 请求,提取 HTML `<title>` 标签内容和响应头 `Server` 字段,与摄像头关键词列表匹配。

#### 1.7 综合

以上六种技术并行执行,结果汇总后进行综合威胁评分 (见后文)。这样可以最大限度地覆盖不同类型、不同品牌、不同配置的摄像头。

---

### 二、蓝牙 BLE 扫描

**原理**:部分微型/隐藏式摄像头使用蓝牙 (BLE) 进行设备配对、参数配置或低带宽数据传输。通过扫描周围的 BLE 广播设备,可以发现可疑的摄像头控制端。

**识别逻辑**:
- 设备名包含 "camera"、"cam"、"IPC"、"隐藏"、"摄像" 等关键词
- 设备名为乱码/随机字符串 (部分隐藏摄像头不广播名称或使用随机名)
- 信号强度 (RSSI) 异常接近 (>-40dBm 说明设备在 1 米内)

**实现**:使用 `flutter_blue_plus` 包扫描 BLE 设备,获取设备名、MAC (Android)、RSSI。

---

### 三、镜头反光检测

**原理**:摄像头镜头是凸透镜,在强光照射下会产生明显的亮点反射。在完全黑暗的环境中,用手机闪光灯照射可疑区域,摄像头镜头会反射出一个明亮的小亮点,与周围环境形成鲜明对比。

**检测流程**:
1. 关闭房间所有灯光,制造全黑环境
2. 打开 App 的镜头检测功能,手机闪光灯常亮
3. 将手机对准可疑位置 (烟雾报警器、闹钟、插座等),缓慢移动
4. App 实时分析相机画面,标记亮度异常的亮点
5. 发现持续存在的亮点时发出警告

**常见藏匿位置**:
- 烟雾报警器 / 天花板圆形小孔
- 闹钟、收音机、电子设备
- USB 充电器 / 电源适配器
- 纸巾盒、相框、装饰品
- 空调出风口、暖气片
- 螺丝钉 (针孔镜头藏在螺丝帽内)
- 镜子后方 (双面镜)
- 衣柜挂钩、衣架

**实现**:使用 `camera` 包获取实时相机预览并开启手电筒 (torch),对相机帧进行 YCbCr 亮度分析,检测超过阈值的亮点。`image` 包用于像素级处理。

---

### 四、红外补光检测

**原理**:带夜视功能的摄像头配备 IR LED 红外补光灯。这些红外光人眼不可见,但大多数手机的前置摄像头没有红外截止滤光片 (IR-Cut Filter),可以在画面中看到暗红色或紫色的光斑。部分后置摄像头也可以检测到。

**检测流程**:
1. 关闭房间所有灯光,制造全黑环境
2. 打开 App 的红外检测功能,切换到前置摄像头
3. 缓慢扫描房间各角落
3. 画面中出现暗红色/紫色/白色光斑 = 疑似红外补光灯
4. App 标记可疑光斑并发出警告

**实现**:使用 `camera` 包切换到前置摄像头,分析帧数据中红色通道 (R) 和蓝色通道 (B) 的偏移,检测疑似红外光源。前置摄像头通常对红外更敏感。

---

### 五、磁场异常检测

**原理**:所有电子器件在工作时都会产生电磁场。隐藏式摄像头虽然体积小,但其电路板和磁性安装底座仍会产生可检测的局部磁场异常。手机内置的地磁传感器 (磁力计) 可以检测这种异常。

**检测方法**:
- 正常地磁场强度约 25-65 μT (微特斯拉)
- 将手机贴近可疑位置,如果磁场总矢量 `sqrt(x² + y² + z²)` 超过 100 μT,说明附近有电子器件
- 数值越高,说明器件越近或功率越大

**常见应用场景**:
- 检测墙壁/家具内隐藏的器件
- 检测非金属物体后方是否有电子设备
- 辅助定位已发现但看不到的设备

**实现**:使用 `sensors_plus` 包读取磁力计三轴数据 (`MagnetometerEvent`),实时计算总矢量并显示。设定阈值线和,超过时视觉警告。

---

### 六、Wi-Fi 热点扫描

**原理**:部分隐藏式摄像头不连接酒店 Wi-Fi,而是自带 Wi-Fi 热点,用户通过连接该热点来查看实时画面。这类热点会出现在系统的 Wi-Fi 扫描列表中。其 SSID (网络名) 常包含以下特征:

- "P2P-" / "P2P_"
- "IPC-" / "IPC_"
- "CAM-" / "CAM_"
- "HD-"/ "HD_"
- "DIRECT-"
- 不明意义的字母数字组合

**实现**:Android 端使用 `wifi_scan` 包扫描附近 Wi-Fi 网络 (包括隐藏网络),匹配可疑 SSID 模式。iOS 受系统限制无法扫描 Wi-Fi 列表,需提示用户手动在系统设置中查看。

---

### 七、人工排查清单

App 内置一个引导式排查清单,覆盖所有常见藏匿点,引导用户逐一检查:

**天花板与墙面**:
- 烟雾报警器 (最常见藏匿点)
- 天花板圆形小孔 / 黑点
- 空调出风口内部
- 灯具底座
- 墙面电源插座面板
- 墙面螺丝钉 (针孔镜头)

**桌面与家具**:
- 闹钟 / 数字时钟
- 收音机 / 蓝牙音箱
- USB 充电器 / 电源适配器
- 纸巾盒 (底部)
- 相框 (背面)
- 花瓶 / 装饰品
- 衣柜 / 保险箱内

**卫生间**:
- 浴帘杆 / 浴帘扣
- 洗发水瓶
- 镜子 (双面镜检测:指甲贴镜面,有缝隙=普通镜,无缝隙=双面镜)
- 排风扇
- 卫生纸盒

**其他**:
- 衣架 / 挂钩
- 拖鞋
- 空调遥控器
- 电视底部

---

## 综合威胁评分系统

对每个发现的网络设备进行多维度评分,综合判断威胁等级:

### 评分维度

| 维度 | 条件 | 分数 |
|------|------|------|
| RTSP 端口 | 554 端口开放 | +40 |
| RTMP 端口 | 1935 端口开放 | +25 |
| 摄像头厂商 MAC | OUI 匹配已知摄像头厂商 | +30 |
| mDNS 摄像头服务 | 发现 `_rtsp._tcp` / `_onvif._tcp` | +35 |
| mDNS 关键词 | 设备名含 camera/IPC/cam 等 | +30 |
| UPnP 摄像头类型 | 响应含 NetworkCamera/IPCamera | +35 |
| ONVIF 响应 | WS-Discovery Probe 响应 | +40 |
| HTTP 标题关键词 | Web 界面标题含摄像头关键词 | +25 |
| 多端口开放 | 3 个以上端口开放 | +15 |
| 未知厂商 MAC | OUI 无法识别 | +10 |
| 已知手机厂商 MAC | Apple/Samsung/Huawei 等 | -20 |

### 威胁等级

| 等级 | 分数范围 | 颜色 | 说明 |
|------|---------|------|------|
| 极高 | ≥ 70 | 红色 | 几乎确定是摄像头,建议立即排查物理位置 |
| 高 | 40-69 | 橙色 | 高度可疑,建议重点检查 |
| 中 | 20-39 | 黄色 | 有一定可疑性,建议留意 |
| 低 | < 20 | 绿色 | 可能是普通设备 |

---

## 平台支持矩阵

| 功能 | Android | iOS | 备注 |
|------|---------|-----|------|
| ARP 表扫描 | ✅ | ❌ | iOS 沙盒限制无法读取 ARP 表 |
| 端口扫描 | ✅ | ✅ | 纯 Dart TCP connect |
| mDNS 发现 | ✅ | ✅ | `multicast_dns` 包跨平台 |
| UPnP 发现 | ✅ | ✅ | `RawDatagramSocket` |
| ONVIF 发现 | ✅ | ✅ | `RawDatagramSocket` |
| HTTP 探测 | ✅ | ✅ | `http` 包 |
| BLE 扫描 | ✅ | ✅ | `flutter_blue_plus` |
| 镜头反光检测 | ✅ | ✅ | `camera` 包 |
| 红外补光检测 | ✅ | ✅ | 前置摄像头 |
| 磁场检测 | ✅ | ✅ | `sensors_plus` |
| Wi-Fi 热点扫描 | ✅ | ❌ | iOS 不允许第三方扫描 Wi-Fi |

> 如果手机不支持某项功能 (无传感器、无相机、系统限制等),App 会自动禁用该功能入口并显示提示。

---

## 安装与使用

### 环境要求

- Flutter 3.x (建议 3.10+)
- Dart 3.x
- Android 6.0+ (API 23+)
- iOS 12.0+

### 编译运行

```bash
cd room_guard
flutter pub get
flutter run
```

### 打包发布

```bash
# Android APK
flutter build apk --release

# iOS (需要 macOS + Xcode)
flutter build ios --release
```

### 使用流程

1. 连接酒店 Wi-Fi
2. 打开 App,进入"网络扫描"页
3. 点击"开始扫描",等待扫描完成 (约 10-30 秒)
4. 查看设备列表,关注标红/标橙的设备
5. 对可疑设备,用"镜头检测"和"红外检测"进一步排查
6. 使用"磁场检测"贴近可疑位置辅助定位
7. 按照排查清单逐一检查房间各处

---

## 技术架构

```
room_guard/
├── lib/
│   ├── main.dart                      # 应用入口
│   ├── app.dart                       # App 根组件
│   ├── theme/
│   │   └── eleme_theme.dart           # 饿了么风格主题
│   ├── models/
│   │   ├── network_device.dart        # 网络设备模型
│   │   ├── ble_device.dart             # BLE 设备模型
│   │   └── threat_level.dart          # 威胁等级枚举
│   ├── services/
│   │   ├── arp_service.dart           # ARP 表读取 (Platform Channel)
│   │   ├── port_scanner.dart          # 端口扫描 (纯 Dart)
│   │   ├── mdns_scanner.dart          # mDNS 发现
│   │   ├── upnp_scanner.dart          # UPnP/SSDP 发现
│   │   ├── onvif_scanner.dart         # ONVIF WS-Discovery
│   │   ├── http_probe_service.dart    # HTTP Web 界面探测
│   │   ├── ble_scanner.dart           # BLE 蓝牙扫描
│   │   ├── wifi_ap_scanner.dart      # Wi-Fi 热点扫描
│   │   ├── oui_database.dart          # MAC OUI 厂商数据库
│   │   ├── network_scanner.dart       # 网络扫描调度器
│   │   └── sensor_service.dart        # 磁力计服务
│   ├── pages/
│   │   ├── home_page.dart             # 首页 (Tab 导航)
│   │   ├── network_scan_page.dart      # 网络扫描页
│   │   ├── lens_detect_page.dart       # 镜头反光检测页
│   │   ├── ir_detect_page.dart         # 红外检测页
│   │   ├── magnetic_detect_page.dart  # 磁场检测页
│   │   ├── ble_scan_page.dart          # 蓝牙扫描页
│   │   └── checklist_page.dart        # 排查清单页
│   └── widgets/
│       ├── device_card.dart            # 设备卡片
│       ├── threat_badge.dart           # 威胁等级标签
│       └── feature_button.dart         # 功能入口按钮
├── android/app/src/main/kotlin/
│   └── com/security/room_guard/
│       └── MainActivity.kt            # ARP Platform Channel
└── assets/
    └── oui_data.json                   # 完整 OUI 数据库
```

---

## 权限说明

### Android (android/app/src/main/AndroidManifest.xml)

```xml
<!-- 网络权限 -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />

<!-- 位置权限 (Wi-Fi 扫描和 BLE 扫描需要) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- 蓝牙权限 (Android 12+) -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- 相机权限 -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" />
<uses-feature android:name="android.hardware.camera.flash" />
```

### iOS (ios/Runner/Info.plist)

```xml
<!-- 本地网络权限 (mDNS/UPnP/端口扫描) -->
<key>NSLocalNetworkUsageDescription</key>
<string>需要本地网络权限来扫描局域网设备</string>

<!-- 相机权限 -->
<key>NSCameraUsageDescription</key>
<string>需要相机权限来检测摄像头镜头反光和红外补光</string>

<!-- 蓝牙权限 -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>需要蓝牙权限来扫描可疑 BLE 设备</string>

<!-- 位置权限 (Wi-Fi 信息) -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>需要位置权限来获取 Wi-Fi 网络信息</string>
```

---

## 局限性说明

1. **网络扫描局限**:只能发现连接了**同一 Wi-Fi 网络**的摄像头。如果摄像头使用自带 4G/SIM 卡、独立热点或离线存储,网络扫描无法发现。
2. **ARP 表局限**:只有与本机通信过的设备才会出现在 ARP 表中。虽然 App 会执行 ping sweep 尽量覆盖,但不保证 100% 完整。
3. **端口扫描局限**:部分摄像头配置了非标准端口或启用了端口过滤,可能无法被端口扫描发现。
4. **镜头检测局限**:需要较暗环境才能有效检测;高度隐蔽的无镜头针孔设备无法检测;依赖人眼二次确认。
5. **红外检测局限**:并非所有摄像头都有红外补光灯;部分手机后置摄像头有红外截止滤光片,效果较差。
6. **磁场检测局限**:只能检测有磁性的电子器件,无法区分设备类型;金属物体也会产生干扰。
7. **BLE 扫描局限**:并非所有摄像头都有蓝牙;BLE 设备名可能被伪装。
8. **Wi-Fi 热点扫描局限**:iOS 不支持;隐藏 SSID 的热点无法被名称匹配。

> 没有任何单一手段能 100% 发现所有偷拍摄像头。建议多种手段组合使用,交叉验证。

---

## 额外排查建议

### 立即可用的非技术手段

1. **关灯看红点**:关掉所有灯,全黑环境用眼睛扫视房间,寻找暗红色小点 (红外 LED)
2. **手电筒扫射**:用手机手电筒从不同角度照射可疑区域,寻找镜头反光
3. **双面镜检测**:指甲尖贴在镜面上,如果指甲和镜像之间有缝隙 = 普通镜子;如果没有缝隙 (指甲和镜像直接接触) = 双面镜
4. **检查插座面板**:拆开看看面板内是否有多余器件
5. **闻气味**:新安装的电子设备可能有轻微焊接气味

### 网络层面额外手段

1. **路由器管理页**:浏览器访问网关 IP (通常 192.168.1.1 / 192.168.0.1),查看"已连接设备"列表,对比已知设备
2. **流量监控**:如果可以登录路由器管理页,查看各设备流量,异常高流量的设备可能正在传输视频
3. **Fing / 网络扫描工具**:使用专业网络扫描 App (如 Fing) 辅助交叉验证
4. **DNS 查询分析**:如果设备通过 VPN 或代理上网,检查 DNS 查询是否指向已知摄像头云服务域名

### 物理排查额外建议

1. **断电法**:关闭房间总电源,如果某个设备仍在工作 (有指示灯),说明它有独立供电 (电池),更可疑
2. **热感**:运行中的摄像头会微微发热,用手触摸可疑设备感受温度
3. **超声波**:部分电子器件会发出超声波,但手机麦克风很难捕捉到
4. **专业设备**:如有条件,使用专业的 RF 信号探测器或红外探测仪

---

## 开发说明

### 技术栈

- **框架**: Flutter 3.x / Dart 3.x
- **UI 风格**: 参考饿了么 (Ele.me) 设计语言
  - 主色: #0097FF (饿了么蓝)
  - 强调色: #FF6000 (橙色)
  - 危险色: #FF4D4F (红色)
  - 背景色: #F5F5F5
  - 卡片: 白色, 圆角 12px, 阴影

### 第三方依赖

| 依赖 | 用途 |
|------|------|
| `network_info_plus` | Wi-Fi 网络信息 (IP, 网关) |
| `connectivity_plus` | 网络连接状态检测 |
| `multicast_dns` | mDNS/Bonjour 设备发现 |
| `camera` | 相机预览 + 手电筒控制 |
| `sensors_plus` | 磁力计传感器 |
| `flutter_blue_plus` | BLE 蓝牙扫描 |
| `http` | HTTP 探测 |
| `permission_handler` | 运行时权限管理 |
| `wifi_scan` | Wi-Fi 热点扫描 (Android) |
| `image` | 图像帧处理 |

### 许可证

MIT License - 仅供个人隐私保护使用,请勿用于非法用途。

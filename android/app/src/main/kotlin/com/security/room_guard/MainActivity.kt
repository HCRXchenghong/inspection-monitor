package com.security.room_guard

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.InputStreamReader

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.security.room_guard/arp"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getArpTable" -> {
                        result.success(getArpTable())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /// 读取 /proc/net/arp 获取局域网设备 IP-MAC 映射
    private fun getArpTable(): Map<String, String> {
        val arpMap = HashMap<String, String>()
        try {
            val process = Runtime.getRuntime().exec(arrayOf("cat", "/proc/net/arp"))
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            var line: String?
            var firstLine = true
            while (reader.readLine().also { line = it } != null) {
                if (firstLine) {
                    firstLine = false
                    continue // 跳过表头
                }
                val parts = line!!.trim().split(Regex("\\s+"))
                if (parts.size >= 4) {
                    val ip = parts[0]
                    val mac = parts[3]
                    // 过滤无效 MAC (00:00:00:00:00:00 或 incomplete)
                    if (mac != "00:00:00:00:00:00" && mac != "00:00:00:00:00:00" && mac.lowercase() != "incomplete") {
                        arpMap[ip] = mac
                    }
                }
            }
            reader.close()
            process.waitFor()
        } catch (e: Exception) {
            // 读取失败,返回空表
        }
        return arpMap
    }
}

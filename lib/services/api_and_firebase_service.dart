// -*- coding: utf-8 -*-
// Dịch vụ kết nối Firebase Realtime Database, FCM, Flask REST API & Gửi tin nhắn SMS/Gọi khẩn cấp

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/fall_event.dart';

class ApiAndFirebaseService {
  static const String _prefServerUrlKey = 'flask_server_url';
  static const String _prefEmergencyPhoneKey = 'emergency_phone';

  static String serverBaseUrl = 'http://192.168.1.15:5000';
  static String emergencyPhone = '';

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Đọc địa chỉ IP Server & Số điện thoại khẩn cấp đã lưu trong máy điện thoại
  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_prefServerUrlKey) ?? 'http://192.168.1.15:5000';
    serverBaseUrl = (savedUrl == 'http://192.168.1.10:5000') ? 'http://192.168.1.15:5000' : savedUrl;
    final savedPhone = prefs.getString(_prefEmergencyPhoneKey) ?? '';
    emergencyPhone = (savedPhone == '115') ? '' : savedPhone;
  }

  /// Lưu địa chỉ IP Server & Số điện thoại mới mà không cần tạo lại file APK
  static Future<void> saveSettings(String newUrl, String newPhone) async {
    String cleaned = newUrl.trim();
    if (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    serverBaseUrl = cleaned;
    emergencyPhone = newPhone.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefServerUrlKey, serverBaseUrl);
    await prefs.setString(_prefEmergencyPhoneKey, emergencyPhone);
  }

  /// Gửi tin nhắn SMS khẩn cấp từ điện thoại tới người thân
  Future<bool> sendEmergencySMS({String? customMessage}) async {
    if (emergencyPhone.trim().isEmpty) return false;
    final body = customMessage ??
        'CANH BAO KHAN CAP! He thong AI phat hien nguoi nha bi TE NGA. Vui long kiem tra va ho tro ngay!';
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: emergencyPhone,
      queryParameters: <String, String>{'body': body},
    );
    try {
      return await launchUrl(smsUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[SMS] Lỗi mở ứng dụng tin nhắn: $e');
      return false;
    }
  }

  /// Gọi điện thoại khẩn cấp tới số người thân
  Future<bool> makeEmergencyCall() async {
    if (emergencyPhone.trim().isEmpty) return false;
    final Uri telUri = Uri(scheme: 'tel', path: emergencyPhone);
    try {
      return await launchUrl(telUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[CALL] Lỗi mở ứng dụng gọi điện: $e');
      return false;
    }
  }

  /// Đăng ký nhận thông báo đẩy (Push Notification) từ topic 'fall_alerts'
  Future<void> initFCMNotifications({
    required Function(RemoteMessage) onForegroundMessage,
  }) async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await _messaging.subscribeToTopic('fall_alerts');
      debugPrint('[FCM] Đã đăng ký nhận cảnh báo từ topic: fall_alerts');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      onForegroundMessage(message);
    });
  }

  /// Lắng nghe trạng thái cảnh báo thời gian thực từ nhánh /system_status trên Firebase
  Stream<DatabaseEvent> watchSystemStatus() {
    return _dbRef.child('system_status').onValue;
  }

  /// Lắng nghe danh sách lịch sử sự kiện té ngã từ nhánh /fall_events trên Firebase
  Stream<List<FallEvent>> watchFallEvents() {
    return _dbRef.child('fall_events').onValue.map((event) {
      final List<FallEvent> list = [];
      final data = event.snapshot.value;
      if (data is Map) {
        data.forEach((key, value) {
          if (value is Map) {
            list.add(FallEvent.fromJson(Map<String, dynamic>.from(value)));
          }
        });
      }
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  /// Xác nhận an toàn và tắt còi báo động (đồng bộ cả Flask Server & Firebase)
  Future<bool> acknowledgeAlarm() async {
    try {
      await _dbRef.child('system_status').update({
        'is_fall': false,
        'acknowledged_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[Firebase] Lỗi cập nhật trạng thái an toàn: $e');
    }

    try {
      final res = await http
          .post(Uri.parse('$serverBaseUrl/api/ack_alarm'))
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[API] Không kết nối được Flask LAN, đã tắt trên Firebase: $e');
      return true;
    }
  }

  /// Ghép đường dẫn ảnh chụp hiện trường đầy đủ từ Flask Server
  static String resolveSnapshotUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '$serverBaseUrl$path';
  }
}

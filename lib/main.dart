// -*- coding: utf-8 -*-
// ỨNG DỤNG DI ĐỘNG FLUTTER NHẬN CẢNH BÁO TÉ NGÃ THỜI GIAN THỰC (TUẦN 8)
// ĐATN: Hệ thống phát hiện té ngã thời gian thực sử dụng MediaPipe và mạng LSTM
// Sinh viên thực hiện: Huỳnh Minh Chiến - MSSV: 22050025

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/login_screen.dart';

/// Hàm xử lý thông báo đẩy (Push Notification) khi ứng dụng chạy nền hoặc tắt màn hình
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM-Background] Nhận cảnh báo ngã khẩn cấp: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const FallDetectionMobileApp());
}

class FallDetectionMobileApp extends StatelessWidget {
  const FallDetectionMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Care Vision - Cảnh báo Té ngã',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

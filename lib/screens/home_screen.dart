// -*- coding: utf-8 -*-
// 2. MÀN HÌNH TRANG CHỦ GIÁM SÁT, NHẬN THÔNG BÁO FCM & GỬI TIN NHẮN SMS KHẨN CẤP (Tuần 8)

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/fall_event.dart';
import '../services/api_and_firebase_service.dart';
import 'history_screen.dart';
import 'event_detail_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiAndFirebaseService _service = ApiAndFirebaseService();
  bool _isFallAlert = false;
  String _lastUpdate = 'Đang đồng bộ...';
  String _lastEventId = '';

  @override
  void initState() {
    super.initState();
    _setupFCM();
    _listenToSystemStatus();
  }

  void _setupFCM() {
    _service.initFCMNotifications(
      onForegroundMessage: (RemoteMessage msg) {
        if (!mounted) return;
        setState(() => _isFallAlert = true);
        _showEmergencyDialog(
          title: msg.notification?.title ?? 'CẢNH BÁO KHẨN CẤP: PHÁT HIỆN TÉ NGÃ!',
          body: msg.notification?.body ?? 'Phát hiện sự cố té ngã từ hệ thống Camera AI.',
          data: msg.data,
        );
      },
    );
  }

  void _listenToSystemStatus() {
    _service.watchSystemStatus().listen((event) {
      final val = event.snapshot.value;
      if (val is Map && mounted) {
        setState(() {
          _isFallAlert = val['is_fall'] == true;
          _lastUpdate = val['last_update']?.toString() ?? 'Vừa xong';
          _lastEventId = val['last_event_id']?.toString() ?? '';
        });
      }
    });
  }

  void _showEmergencyDialog({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF7F1D1D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(body, style: const TextStyle(color: Colors.white, fontSize: 14)),
        actions: [
          TextButton.icon(
            onPressed: () => _service.sendEmergencySMS(
              customMessage: 'KHAN CAP! Phat hien te nga luc $_lastUpdate. Vui long kiem tra ngay!',
            ),
            icon: const Icon(Icons.sms, color: Colors.amberAccent),
            label: const Text('GỬI SMS NGƯỜI THÂN', style: TextStyle(color: Colors.amberAccent)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _service.acknowledgeAlarm();
            },
            child: const Text('TẮT CÒI', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red.shade900),
            onPressed: () {
              Navigator.of(ctx).pop();
              final ev = FallEvent.fromJson(data);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EventDetailScreen(event: ev)),
              );
            },
            child: const Text('XEM CHI TIẾT'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Giám sát Té ngã Thời gian thực', style: TextStyle(color: Colors.white, fontSize: 18)),
        actions: [
          IconButton(
            tooltip: 'Lịch sử sự kiện',
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
            },
          ),
          IconButton(
            tooltip: 'Đổi IP / SĐT khẩn cấp',
            icon: const Icon(Icons.settings, color: Color(0xFF60A5FA)),
            onPressed: () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _isFallAlert ? const Color(0xFFB91C1C) : const Color(0xFF065F46),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: (_isFallAlert ? Colors.red : Colors.green).withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    _isFallAlert ? Icons.notification_important_rounded : Icons.verified_user_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isFallAlert ? 'CẢNH BÁO KHẨN CẤP: PHÁT HIỆN TÉ NGÃ!' : 'TRẠNG THÁI: AN TOÀN BÌNH THƯỜNG',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Cập nhật gần nhất: $_lastUpdate\nSĐT khẩn cấp: ${ApiAndFirebaseService.emergencyPhone}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          onPressed: () async {
                            final ok = await _service.sendEmergencySMS();
                            if (!ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Không mở được ứng dụng Tin nhắn trên máy này!')),
                              );
                            }
                          },
                          icon: const Icon(Icons.sms, size: 18),
                          label: const Text('Gửi tin nhắn SMS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFB91C1C),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          onPressed: () => _service.makeEmergencyCall(),
                          icon: const Icon(Icons.call, size: 18),
                          label: const Text('Gọi khẩn cấp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                  if (_isFallAlert) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        onPressed: () async {
                          await _service.acknowledgeAlarm();
                          setState(() => _isFallAlert = false);
                        },
                        icon: const Icon(Icons.volume_off),
                        label: const Text(
                          'XÁC NHẬN AN TOÀN & TẮT CÒI BÁO ĐỘNG',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sự kiện té ngã gần đây (Firebase)',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
                  },
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Xem tất cả'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: StreamBuilder<List<FallEvent>>(
                stream: _service.watchFallEvents(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final events = snapshot.data ?? [];
                  if (events.isEmpty) {
                    return const Center(
                      child: Text(
                        'Chưa ghi nhận sự cố té ngã nào trên Firebase.',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final ev = events[i];
                      return Card(
                        color: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFDC2626),
                            child: Icon(Icons.personal_injury, color: Colors.white),
                          ),
                          title: Text(
                            'Phát hiện Té ngã (${ev.confidencePercent})',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${ev.cameraSource} • ${ev.timestamp}',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => EventDetailScreen(event: ev)),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

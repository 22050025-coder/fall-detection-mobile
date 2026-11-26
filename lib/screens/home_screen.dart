// -*- coding: utf-8 -*-
// 2. MÀN HÌNH CHÍNH TỐI GIẢN HIỆN ĐẠI (Minimalist Dashboard: Live Webcam + Status + Actions + Events)

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/fall_event.dart';
import '../services/api_and_firebase_service.dart';
import '../widgets/mjpeg_live_view.dart';
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
  String _lastUpdate = 'Đang đồng bộ';

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
        _showEmergencySheet(
          title: msg.notification?.title ?? 'Phát hiện té ngã khẩn cấp!',
          body: msg.notification?.body ?? 'Hệ thống Camera AI phát hiện người nhà bị ngã.',
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
        });
      }
    });
  }

  void _showEmergencySheet({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151C2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF87171), size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF334155)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _service.sendEmergencySMS();
                    },
                    icon: const Icon(Icons.sms_outlined, size: 18),
                    label: const Text('Gửi SMS'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      final ev = FallEvent.fromJson(data);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => EventDetailScreen(event: ev)),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Xem ảnh'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String streamUrl = '${ApiAndFirebaseService.serverBaseUrl}/video_feed';

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        elevation: 0,
        titleSpacing: 18,
        title: Row(
          children: [
            const Text(
              'AI Care Vision',
              style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: (_isFallAlert ? const Color(0xFFDC2626) : const Color(0xFF10B981)).withOpacity(0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isFallAlert ? '● Cảnh báo' : '● An toàn',
                style: TextStyle(
                  color: _isFallAlert ? const Color(0xFFF87171) : const Color(0xFF34D399),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Lịch sử',
            icon: const Icon(Icons.history_rounded, color: Color(0xFF94A3B8), size: 22),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
            },
          ),
          IconButton(
            tooltip: 'Cài đặt IP / SĐT',
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF94A3B8), size: 21),
            onPressed: () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KHUNG WEBCAM TRỰC TIẾP TỐI GIẢN, BO GÓC HIỆN ĐẠI
            Container(
              width: double.infinity,
              height: 225,
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isFallAlert ? const Color(0xFFEF4444) : const Color(0xFF1E293B),
                  width: _isFallAlert ? 2.0 : 1.2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18.5),
                child: MjpegLiveView(streamUrl: streamUrl),
              ),
            ),
            const SizedBox(height: 14),

            // 2. THANH TRẠNG THÁI & NÚT HÀNH ĐỘNG TỐI GIẢN
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: _isFallAlert ? const Color(0xFF7F1D1D).withOpacity(0.45) : const Color(0xFF151C2C),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _isFallAlert ? const Color(0xFFEF4444).withOpacity(0.5) : const Color(0xFF1E293B),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (_isFallAlert ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isFallAlert ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                          color: _isFallAlert ? const Color(0xFFF87171) : const Color(0xFF34D399),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isFallAlert ? 'Phát hiện sự cố té ngã!' : 'Hệ thống giám sát bình thường',
                              style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Cập nhật: $_lastUpdate',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (_isFallAlert)
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            await _service.acknowledgeAlarm();
                            setState(() => _isFallAlert = false);
                          },
                          child: const Text('Tắt còi', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'Nhắn SMS',
                          color: const Color(0xFF3B82F6),
                          onTap: () async {
                            final ok = await _service.sendEmergencySMS();
                            if (!ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Vui lòng nhập SĐT người thân trong Cài đặt')),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _actionButton(
                          icon: Icons.phone_outlined,
                          label: 'Gọi khẩn cấp',
                          color: const Color(0xFF10B981),
                          onTap: () async {
                            final ok = await _service.makeEmergencyCall();
                            if (!ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Vui lòng nhập SĐT người thân trong Cài đặt')),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 3. DANH SÁCH SỰ KIỆN GẦN ĐÂY TỐI GIẢN
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hoạt động gần đây',
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
                  },
                  child: const Text(
                    'Tất cả →',
                    style: TextStyle(color: Color(0xFF60A5FA), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<List<FallEvent>>(
                stream: _service.watchFallEvents(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  final events = snapshot.data ?? [];
                  if (events.isEmpty) {
                    return const Center(
                      child: Text(
                        'Chưa có sự cố nào được ghi nhận',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final ev = events[i];
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => EventDetailScreen(event: ev)),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF151C2C),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF1E293B)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.person_off_outlined, color: Color(0xFFF87171), size: 19),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cảnh báo té ngã • ${ev.confidencePercent}',
                                      style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${ev.cameraSource}  •  ${ev.timestamp}',
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: Color(0xFF475569), size: 20),
                            ],
                          ),
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

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

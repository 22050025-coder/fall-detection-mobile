// -*- coding: utf-8 -*-
// 4. MÀN HÌNH CHI TIẾT SỰ KIỆN & ẢNH CHỤP CHỨNG CỨ (Tuần 8 - ĐATN Huỳnh Minh Chiến 22050025)

import 'package:flutter/material.dart';
import '../models/fall_event.dart';
import '../services/api_and_firebase_service.dart';

class EventDetailScreen extends StatelessWidget {
  final FallEvent event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final String fullImageUrl = ApiAndFirebaseService.resolveSnapshotUrl(event.snapshotUrl);
    final ApiAndFirebaseService service = ApiAndFirebaseService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Chi tiết sự kiện té ngã',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Khung hiển thị ảnh chụp hiện trường có khoanh vùng đỏ người ngã
            Container(
              width: double.infinity,
              height: 240,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEF4444), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: fullImageUrl.isNotEmpty
                    ? Image.network(
                        fullImageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Text(
                            'Ảnh minh chứng lưu tại máy chủ Flask\n(Kiểm tra kết nối cùng mạng LAN với Server)',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image_not_supported, size: 54, color: Colors.white38),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                children: [
                  _infoRow('Mã sự kiện (Event ID):', event.eventId),
                  const Divider(color: Color(0xFF334155), height: 24),
                  _infoRow('Nhãn hành vi AI (Bi-LSTM):', 'TÉ NGÃ KHẨN CẤP (FALL)', isAlert: true),
                  const Divider(color: Color(0xFF334155), height: 24),
                  _infoRow('Độ tin cậy dự đoán:', event.confidencePercent),
                  const Divider(color: Color(0xFF334155), height: 24),
                  _infoRow('Nguồn thu Camera:', event.cameraSource),
                  const Divider(color: Color(0xFF334155), height: 24),
                  _infoRow('Thời điểm ghi nhận:', event.timestamp),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await service.acknowledgeAlarm();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xác nhận an toàn và tắt còi báo động!')),
                  );
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  'XÁC NHẬN ĐÃ XỬ LÝ AN TOÀN & TẮT CÒI',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isAlert = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isAlert ? const Color(0xFFF87171) : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

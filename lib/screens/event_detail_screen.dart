// -*- coding: utf-8 -*-
// 4. MÀN HÌNH CHI TIẾT SỰ KIỆN TỐI GIẢN HIỆN ĐẠI (Minimalist Event Detail)

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
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Chi tiết sự cố',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 230,
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: fullImageUrl.isNotEmpty
                    ? Image.network(
                        fullImageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Text(
                            'Ảnh lưu trên Laptop\n(Kết nối cùng Wi-Fi với Laptop để tải ảnh)',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image_not_supported_outlined, size: 42, color: Color(0xFF475569)),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF151C2C),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                children: [
                  _infoRow('Trạng thái AI', 'Té ngã khẩn cấp', isAlert: true),
                  const Divider(color: Color(0xFF1E293B), height: 22),
                  _infoRow('Độ tin cậy (Bi-LSTM)', event.confidencePercent),
                  const Divider(color: Color(0xFF1E293B), height: 22),
                  _infoRow('Thiết bị Camera', event.cameraSource),
                  const Divider(color: Color(0xFF1E293B), height: 22),
                  _infoRow('Thời gian ghi nhận', event.timestamp),
                  const Divider(color: Color(0xFF1E293B), height: 22),
                  _infoRow('Mã sự kiện', event.eventId),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  await service.acknowledgeAlarm();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xác nhận an toàn và tắt cảnh báo')),
                  );
                },
                icon: const Icon(Icons.check_rounded, size: 20),
                label: const Text(
                  'Xác nhận đã xử lý an toàn',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
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
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isAlert ? const Color(0xFFF87171) : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
        ),
      ],
    );
  }
}

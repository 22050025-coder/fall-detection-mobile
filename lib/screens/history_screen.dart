// -*- coding: utf-8 -*-
// 3. MÀN HÌNH LỊCH SỬ SỰ KIỆN TÉ NGÃ (Tuần 8 - ĐATN Huỳnh Minh Chiến 22050025)

import 'package:flutter/material.dart';
import '../models/fall_event.dart';
import '../services/api_and_firebase_service.dart';
import 'event_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ApiAndFirebaseService service = ApiAndFirebaseService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Lịch sử sự kiện té ngã',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<FallEvent>>(
        stream: service.watchFallEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(
              child: Text(
                'Danh sách lịch sử trống.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ev = events[index];
              final imgUrl = ApiAndFirebaseService.resolveSnapshotUrl(ev.snapshotUrl);

              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => EventDetailScreen(event: ev)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 76,
                          height: 60,
                          color: const Color(0xFF0F172A),
                          child: imgUrl.isNotEmpty
                              ? Image.network(
                                  imgUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image, color: Colors.redAccent),
                                )
                              : const Icon(Icons.camera_alt_outlined, color: Colors.white54),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cảnh báo Té ngã • Độ tin cậy: ${ev.confidencePercent}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Nguồn thu: ${ev.cameraSource}',
                              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Thời điểm: ${ev.timestamp}',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

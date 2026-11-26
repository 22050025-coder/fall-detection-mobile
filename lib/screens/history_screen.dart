// -*- coding: utf-8 -*-
// 3. MÀN HÌNH LỊCH SỬ SỰ KIỆN TỐI GIẢN HIỆN ĐẠI (Minimalist History Screen)

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
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Lịch sử sự kiện',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<List<FallEvent>>(
        stream: service.watchFallEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có lịch sử sự cố',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final ev = events[index];
              final imgUrl = ApiAndFirebaseService.resolveSnapshotUrl(ev.snapshotUrl);

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => EventDetailScreen(event: ev)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151C2C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 68,
                          height: 54,
                          color: const Color(0xFF0B0F19),
                          child: imgUrl.isNotEmpty
                              ? Image.network(
                                  imgUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.image_outlined,
                                    color: Color(0xFF475569),
                                    size: 22,
                                  ),
                                )
                              : const Icon(Icons.videocam_outlined, color: Color(0xFF475569), size: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Té ngã • ${ev.confidencePercent}',
                                    style: const TextStyle(
                                      color: Color(0xFFF87171),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              ev.cameraSource,
                              style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ev.timestamp,
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
    );
  }
}

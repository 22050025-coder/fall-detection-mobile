// -*- coding: utf-8 -*-
// Модели dữ liệu Sự kiện Té ngã (Tuần 8 - ĐATN Huỳnh Minh Chiến 22050025)

class FallEvent {
  final String eventId;
  final String action;
  final double confidence;
  final String cameraSource;
  final String snapshotUrl;
  final String timestamp;
  final bool acknowledged;

  FallEvent({
    required this.eventId,
    required this.action,
    required this.confidence,
    required this.cameraSource,
    required this.snapshotUrl,
    required this.timestamp,
    this.acknowledged = false,
  });

  factory FallEvent.fromJson(Map<String, dynamic> json) {
    double conf = 0.95;
    if (json['confidence'] is num) {
      conf = (json['confidence'] as num).toDouble();
    } else if (json['confidence'] is String) {
      final cleaned = (json['confidence'] as String).replaceAll('%', '').trim();
      conf = (double.tryParse(cleaned) ?? 95.0) / (cleaned.contains('.') && double.parse(cleaned) <= 1.0 ? 1.0 : 100.0);
    }

    return FallEvent(
      eventId: json['event_id']?.toString() ?? 'fall_${DateTime.now().millisecondsSinceEpoch}',
      action: json['action']?.toString() ?? 'fall',
      confidence: conf,
      cameraSource: json['camera_source']?.toString() ?? 'Camera 0 (Phòng khách)',
      snapshotUrl: json['snapshot_url']?.toString() ?? json['url']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? json['time']?.toString() ?? '',
      acknowledged: json['acknowledged'] == true,
    );
  }

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';
}

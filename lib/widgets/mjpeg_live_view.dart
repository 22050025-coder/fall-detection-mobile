// -*- coding: utf-8 -*-
// Widget hiển thị luồng Video Webcam AI trực tiếp (MJPEG Stream /video_feed)
// Giải mã trực tiếp byte JPEG (SOI 0xFFD8 -> EOI 0xFFD9) với gaplessPlayback: true mượt 30 FPS

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MjpegLiveView extends StatefulWidget {
  final String streamUrl;

  const MjpegLiveView({super.key, required this.streamUrl});

  @override
  State<MjpegLiveView> createState() => _MjpegLiveViewState();
}

class _MjpegLiveViewState extends State<MjpegLiveView> {
  http.Client? _client;
  StreamSubscription<List<int>>? _subscription;
  Uint8List? _currentFrame;
  bool _hasError = false;
  String _errorText = '';
  bool _isConnecting = true;

  @override
  void initState() {
    super.initState();
    _startStream();
  }

  @override
  void didUpdateWidget(covariant MjpegLiveView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamUrl != widget.streamUrl) {
      _stopStream();
      _startStream();
    }
  }

  @override
  void dispose() {
    _stopStream();
    super.dispose();
  }

  void _stopStream() {
    _subscription?.cancel();
    _subscription = null;
    _client?.close();
    _client = null;
  }

  Future<void> _startStream() async {
    if (!mounted) return;
    setState(() {
      _isConnecting = true;
      _hasError = false;
    });

    _client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(widget.streamUrl));
      final response = await _client!.send(request).timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _isConnecting = false;
            _errorText = 'Máy chủ trả về mã lỗi ${response.statusCode}';
          });
        }
        return;
      }

      final List<int> buffer = [];
      int soiIndex = -1;

      _subscription = response.stream.listen(
        (List<int> chunk) {
          buffer.addAll(chunk);

          while (true) {
            if (soiIndex == -1) {
              for (int i = 0; i < buffer.length - 1; i++) {
                if (buffer[i] == 0xFF && buffer[i + 1] == 0xD8) {
                  soiIndex = i;
                  break;
                }
              }
              if (soiIndex == -1) {
                if (buffer.length > 2) {
                  final last = buffer.last;
                  buffer.clear();
                  if (last == 0xFF) buffer.add(last);
                }
                break;
              }
            }

            int eoiIndex = -1;
            for (int i = soiIndex + 2; i < buffer.length - 1; i++) {
              if (buffer[i] == 0xFF && buffer[i + 1] == 0xD9) {
                eoiIndex = i + 2;
                break;
              }
            }

            if (eoiIndex != -1) {
              final frameBytes = Uint8List.fromList(buffer.sublist(soiIndex, eoiIndex));
              buffer.removeRange(0, eoiIndex);
              soiIndex = -1;

              if (mounted) {
                setState(() {
                  _currentFrame = frameBytes;
                  _isConnecting = false;
                  _hasError = false;
                });
              }
            } else {
              if (buffer.length > 1500000) {
                buffer.clear();
                soiIndex = -1;
              }
              break;
            }
          }
        },
        onError: (e) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _isConnecting = false;
              _errorText = 'Mất kết nối luồng Webcam';
            });
          }
        },
        onDone: () {
          if (mounted && _currentFrame == null) {
            setState(() {
              _hasError = true;
              _isConnecting = false;
              _errorText = 'Luồng Webcam đã đóng';
            });
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isConnecting = false;
          _errorText = 'Chưa kết nối được Flask Server (${widget.streamUrl})';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentFrame != null && !_hasError) {
      return Stack(
        children: [
          Positioned.fill(
            child: Image.memory(
              _currentFrame!,
              gaplessPlayback: true,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Colors.redAccent, size: 10),
                  SizedBox(width: 5),
                  Text('LIVE WEBCAM AI', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              tooltip: 'Làm mới kết nối Camera',
              icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
              onPressed: () {
                _stopStream();
                _startStream();
              },
            ),
          ),
        ],
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isConnecting) ...[
              const CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF60A5FA)),
              const SizedBox(height: 10),
              const Text(
                'Đang kết nối luồng Webcam từ Laptop...',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
              ),
            ] else ...[
              const Icon(Icons.videocam_off_outlined, color: Colors.amberAccent, size: 34),
              const SizedBox(height: 6),
              Text(
                _errorText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
              ),
              const SizedBox(height: 4),
              const Text(
                'Hãy chạy app.py trên Laptop và kiểm tra đúng IP Wi-Fi',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  _stopStream();
                  _startStream();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Kết nối lại Webcam', style: TextStyle(fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

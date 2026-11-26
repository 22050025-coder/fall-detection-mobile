// -*- coding: utf-8 -*-
// 1. MÀN HÌNH ĐĂNG NHẬP TỐI GIẢN HIỆN ĐẠI (Minimalist UI)

import 'package:flutter/material.dart';
import '../services/api_and_firebase_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController(text: 'admin');
  final TextEditingController _passController = TextEditingController(text: '123456');
  final TextEditingController _serverController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _showAdvanced = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    await ApiAndFirebaseService.loadSettings();
    setState(() {
      _serverController.text = ApiAndFirebaseService.serverBaseUrl;
      _phoneController.text = ApiAndFirebaseService.emergencyPhone;
    });
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final user = _userController.text.trim();
    final pass = _passController.text.trim();
    final srv = _serverController.text.trim();
    final phone = _phoneController.text.trim();

    if (user.isEmpty || pass.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMsg = 'Vui lòng nhập tài khoản và mật khẩu';
      });
      return;
    }

    await ApiAndFirebaseService.saveSettings(srv, phone);
    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  InputDecoration _minimalInput(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 13),
      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
      filled: true,
      fillColor: const Color(0xFF111827),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1F2937)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D4ED8).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.35)),
                  ),
                  child: const Icon(Icons.shield_outlined, size: 32, color: Color(0xFF60A5FA)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'AI Care Vision',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Giám sát & Cảnh báo té ngã thời gian thực',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151C2C),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _userController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: _minimalInput('Tài khoản', Icons.person_outline_rounded),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: _minimalInput('Mật khẩu', Icons.lock_outline_rounded),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Cấu hình kết nối & SĐT khẩn cấp',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5, fontWeight: FontWeight.w500),
                              ),
                              Icon(
                                _showAdvanced ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: const Color(0xFF64748B),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_showAdvanced) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: _minimalInput(
                            'SĐT người thân (Nhận SMS / Gọi)',
                            Icons.phone_outlined,
                            hint: 'VD: 0901234567',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _serverController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: _minimalInput(
                            'Địa chỉ IP Laptop (Flask Server)',
                            Icons.wifi_tethering_rounded,
                            hint: 'http://192.168.1.15:5000',
                          ),
                        ),
                      ],
                      if (_errorMsg != null) ...[
                        const SizedBox(height: 12),
                        Text(_errorMsg!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12.5)),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            _isLoading ? 'Đang kết nối...' : 'Đăng nhập',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

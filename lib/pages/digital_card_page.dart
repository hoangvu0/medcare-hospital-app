import 'dart:math';
import 'package:flutter/material.dart';

import '../state/app_settings_store.dart';
import '../state/medical_store.dart';

class DigitalCardPage extends StatefulWidget {
  const DigitalCardPage({super.key});

  @override
  State<DigitalCardPage> createState() => _DigitalCardPageState();
}

class _DigitalCardPageState extends State<DigitalCardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  @override
  Widget build(BuildContext context) {
    final profile = MedicalScope.of(context).profile;
    final settings = AppSettingsScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final maskedBhyt = settings.maskText(
      profile.insuranceNumber,
      visiblePrefix: 4,
      visibleSuffix: 3,
    );
    final maskedPhone = settings.maskText(
      profile.phone,
      visiblePrefix: 3,
      visibleSuffix: 3,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thẻ Y tế Điện tử'),
        actions: [
          IconButton(
            tooltip: 'Lật thẻ',
            icon: const Icon(Icons.flip_camera_android_rounded),
            onPressed: _flipCard,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(
            child: Text(
              'Chạm vào thẻ để lật giữa Thẻ Bệnh Viện & Thẻ BHYT',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),

          // 3D Flip Card
          GestureDetector(
            onTap: _flipCard,
            child: AnimatedBuilder(
              animation: _flipAnimation,
              builder: (context, child) {
                final angle = _flipAnimation.value * pi;
                final isUnder = angle > (pi / 2);

                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  alignment: Alignment.center,
                  child: isUnder
                      ? Transform(
                          transform: Matrix4.identity()..rotateY(pi),
                          alignment: Alignment.center,
                          child: _buildBackCard(profile, maskedBhyt),
                        )
                      : _buildFrontCard(profile, maskedPhone),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _flipCard,
                  icon: const Icon(Icons.autorenew),
                  label: Text(_isFront ? 'Xem Thẻ BHYT' : 'Xem Thẻ Bệnh Nhân'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mã QR sẵn sàng quét tại Kiosk tiếp đón tầng 1.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('Quét Kiosk'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Details overview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('THÔNG TIN LIÊN KẾT Y TẾ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0057CD))),
                const Divider(height: 18),
                _cardRow('Họ và tên bệnh nhân', profile.name),
                _cardRow('Mã định danh viện', profile.id),
                _cardRow('Số thẻ BHYT quốc gia', maskedBhyt),
                _cardRow('Hạn sử dụng BHYT', '31/12/2026 (Còn hạn)'),
                _cardRow('Nơi đăng ký KCB ban đầu', 'Bệnh viện MedCare Hospital'),
                _cardRow('Mức hưởng quyền lợi', '80% chi phí khám chữa bệnh đúng tuyến'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrontCard(dynamic profile, String phone) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x401E3A8A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_hospital, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'MedCare Hospital',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('VIP PLATINUM', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Icon(Icons.nfc, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Mã BN: ${profile.id}',
                style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 2, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CHỦ THẺ', style: TextStyle(color: Colors.white54, fontSize: 9)),
                  Text(
                    profile.name as String,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('NHÓM MÁU', style: TextStyle(color: Colors.white54, fontSize: 9)),
                  Text(
                    profile.bloodType as String,
                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard(dynamic profile, String maskedBhyt) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF047857), Color(0xFF065F46), Color(0xFF064E3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40065F46),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.health_and_safety, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'BẢO HIỂM Y TẾ VIỆT NAM',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('ĐÚNG TUYẾN 80%', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Center(
            child: Text(
              maskedBhyt,
              style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 3, fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Họ tên: ${profile.name}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('Ngày sinh: ${profile.dateOfBirth} • Giới tính: ${profile.gender}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  const Text('Nơi KCB BĐ: BV Đa khoa MedCare (Mã 01-089)', style: TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.qr_code, size: 36, color: Colors.black),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

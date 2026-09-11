import 'package:flutter/material.dart';

import '../state/medical_store.dart';

class EmergencySosPage extends StatelessWidget {
  const EmergencySosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final profile = store.profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cấp cứu Khẩn cấp SOS'),
        backgroundColor: const Color(0xFFBA1A1A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Emergency Call Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFBA1A1A), Color(0xFF93000A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40BA1A1A),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.phone_in_talk, size: 40, color: Color(0xFFBA1A1A)),
                ),
                const SizedBox(height: 14),
                const Text(
                  'HOTLINE CẤP CỨU 24/7',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                const Text(
                  '1900 8899',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () {
                    _showCallDialog(context, '1900 8899');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFBA1A1A),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.call),
                  label: const Text('GỌI CẤP CỨU NGAY', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Medical ID Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade200, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.medical_information, color: Color(0xFFBA1A1A)),
                    SizedBox(width: 8),
                    Text(
                      'THẺ Y TẾ KHẨN CẤP (MEDICAL ID)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFBA1A1A)),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _idRow('Họ và tên bệnh nhân', profile.name),
                _idRow('Mã hồ sơ bệnh án', profile.id),
                _idRow('Nhóm máu', profile.bloodType, isHighlight: true),
                _idRow('Dị ứng đặc biệt', profile.allergies, isDanger: true),
                _idRow('Bệnh lý mạn tính', 'Viêm loét dạ dày tá tràng (Hp+)'),
                _idRow('Người liên hệ khẩn cấp', 'Mẹ: Nguyễn Thị Mai (0987 654 321)'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // First-Aid quick guide
          const Text(
            'HƯỚNG DẪN SƠ CẤP CỨU NHANH',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0057CD), letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          _firstAidTile('Đau ngực dữ dội', 'Để người bệnh ngồi nửa nằm nửa ngồi, nới lỏng áo, gọi cấp cứu ngay lập tức.'),
          _firstAidTile('Ngất xỉu / Bất tỉnh', 'Đặt nằm ngửa, nâng chân cao 30cm, kiểm tra đường thở, không tụ tập đông người.'),
          _firstAidTile('Co giật / Động kinh', 'Nằm nghiêng an toàn, lót gối mềm dưới đầu, không nhét bất kỳ vật gì vào miệng.'),
        ],
      ),
    );
  }

  Widget _idRow(String label, String val, {bool isHighlight = false, bool isDanger = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            val,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDanger ? Colors.red : (isHighlight ? const Color(0xFF0057CD) : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _firstAidTile(String title, String desc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFFDAD6),
          child: Icon(Icons.health_and_safety, color: Color(0xFFBA1A1A), size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 11)),
      ),
    );
  }

  void _showCallDialog(BuildContext context, String number) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cuộc gọi cấp cứu'),
        content: Text('Đang kết nối đến Trung tâm Cấp cứu MedCare ($number)...'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

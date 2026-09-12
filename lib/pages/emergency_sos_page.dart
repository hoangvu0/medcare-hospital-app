import 'package:flutter/material.dart';

import '../state/medical_store.dart';

class EmergencySosPage extends StatefulWidget {
  const EmergencySosPage({super.key});

  @override
  State<EmergencySosPage> createState() => _EmergencySosPageState();
}

class _EmergencySosPageState extends State<EmergencySosPage> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isAlarmActive = false;
  final bool _isAmbulanceDispatched = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final profile = store.activeFamilyMember;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cấp cứu Khẩn cấp SOS'),
        backgroundColor: const Color(0xFFBA1A1A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isAlarmActive ? Icons.volume_up : Icons.volume_off),
            tooltip: 'Âm thanh còi hú khẩn cấp',
            onPressed: () {
              setState(() => _isAlarmActive = !_isAlarmActive);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isAlarmActive ? '🚨 Đang phát còi hú báo động đỏ cấp cứu 115' : 'Đã tắt âm thanh cảnh báo.'),
                  backgroundColor: _isAlarmActive ? Colors.red : Colors.grey,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // GPS Location Card
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF93C5FD)),
            ),
            child: Row(
              children: [
                const Icon(Icons.my_location, color: Color(0xFF0057CD)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VỊ TRÍ GPS HIỆN TẠI (ĐÃ ĐỊNH VỊ CHÍNH XÁC)',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0057CD)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${store.profile.address} (21°01\'15.4"N 105°51\'08.2"E)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Live GPS', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Emergency Call Banner with Pulsing Effect
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFBA1A1A),
                      Color.lerp(const Color(0xFF93000A), const Color(0xFFD32F2F), _animController.value)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFBA1A1A).withValues(alpha: 0.3 + 0.3 * _animController.value),
                      blurRadius: 16 + 8 * _animController.value,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.phone_in_talk, size: 40, color: Color(0xFFBA1A1A)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'HOTLINE CẤP CỨU NGOẠI VIỆN 24/7',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                const Text(
                  '1900 8899',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Đường dây nóng Cấp cứu Y tế & 115',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _showCallDialog(context, '1900 8899'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFBA1A1A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.call, size: 22),
                    label: const Text('BẤM GỌI CẤP CỨU NGAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Live Ambulance Dispatch Tracker
          if (_isAmbulanceDispatched)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade400, width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.amber.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emergency, color: Colors.amber, size: 24),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'XE CỨU THƯƠNG ĐANG DI CHUYỂN ĐẾN (LIVE)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(6)),
                        child: const Text('ETA: 7 PHÚT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Biển số xe cứu thương', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text('29B - 998.88 (Xe Cấp cứu số 02)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          Text('Bác sĩ kíp trực cấp cứu', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text('BSCKII. Trần Văn An • SĐT: 0912 345 678', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      IconButton.filledTonal(
                        onPressed: () => _showCallDialog(context, '0912 345 678'),
                        icon: const Icon(Icons.phone, color: Colors.green),
                        tooltip: 'Gọi kíp xe',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(value: 0.65, color: Colors.amber, backgroundColor: Color(0xFFE2E8F0)),
                  const SizedBox(height: 6),
                  const Text('Đang qua ngã tư Phố Huế - Đại Cồ Việt (cách 1.8km)', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey)),
                ],
              ),
            ),

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
                _idRow('Bệnh lý mạn tính', 'Tăng huyết áp vô căn (Đang điều trị)'),
                _idRow('Người liên hệ khẩn cấp', 'Mẹ: Nguyễn Thị Mai (0987 654 321)'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // First-Aid quick guide
          const Text(
            'HƯỚNG DẪN SƠ CẤP CỨU NHANH TRONG KHI CHỜ XE',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0057CD), letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          _firstAidTile('Ép tim ngoài lồng ngực (CPR)', 'Đặt 2 tay giữa ngực, ép sâu 5cm với nhịp độ 100-120 lần/phút.'),
          _firstAidTile('Đau ngực / Nghi ngờ Nhồi máu cơ tim', 'Để người bệnh ngồi nửa nằm nửa ngồi, nới lỏng áo, không cho ăn uống.'),
          _firstAidTile('Đột quỵ não (F.A.S.T)', 'Kiểm tra Méo miệng (Face), Yếu tay (Arm), Nói ngọng (Speech). Ghi nhớ giờ khởi phát!'),
          _firstAidTile('Co giật / Động kinh', 'Nằm nghiêng an toàn, lót gối mềm dưới đầu, không nhét bất kỳ vật gì vào miệng.'),
        ],
      ),
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
        content: Text('Đang kết nối khẩn cấp đến Trung tâm Cấp cứu MedCare ($number)...\nTọa độ GPS và Medical ID của bạn đã được truyền trực tiếp đến kíp cấp cứu.'),
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



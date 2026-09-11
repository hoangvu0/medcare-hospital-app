import 'package:flutter/material.dart';

import '../state/medical_store.dart';

class LiveQueuePage extends StatelessWidget {
  const LiveQueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final queue = store.queueInfo;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isYourTurn = queue.currentNumber >= queue.patientNumber;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi Hàng đợi Khám'),
        actions: [
          IconButton(
            tooltip: 'Cập nhật hàng đợi',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              store.refreshQueue();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã đồng bộ trạng thái hàng đợi phòng khám!'), duration: Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Clinic banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFFE0E7FF),
                  child: Icon(Icons.meeting_room_rounded, color: Color(0xFF0057CD)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        queue.department,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF0057CD), fontWeight: FontWeight.bold),
                      ),
                      Text(
                        queue.room,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Bác sĩ: ${queue.doctorName}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Big Queue display
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isYourTurn
                    ? [const Color(0xFF16A34A), const Color(0xFF15803D)]
                    : [const Color(0xFF0057CD), const Color(0xFF003882)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (isYourTurn ? Colors.green : const Color(0xFF0057CD)).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  isYourTurn ? 'ĐÃ ĐẾN LƯỢT KHÁM CỦA BẠN!' : 'SỐ THỨ TỰ ĐANG KHÁM',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${queue.currentNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Số phiếu của bạn: ${queue.patientNumber} (${queue.ticketCode})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Wait stats
          Row(
            children: [
              Expanded(
                child: _queueStatBox(
                  context,
                  title: 'Người đang chờ trước',
                  value: '${queue.waitCount} người',
                  icon: Icons.people_alt_outlined,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _queueStatBox(
                  context,
                  title: 'Ước tính thời gian',
                  value: '~${queue.estimatedMinutes} phút',
                  icon: Icons.timer_outlined,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Guidelines card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.checklist_rounded, color: Color(0xFF0057CD), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'HƯỚNG DẪN TRƯỚC KHI VÀO PHÒNG KHÁM',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0057CD)),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _bulletItem('1. Chuẩn bị sẵn thẻ BHYT bản cứng hoặc trên ứng dụng.'),
                _bulletItem('2. Cầm sẵn sổ khám bệnh và các kết quả xét nghiệm máu / chẩn đoán hình ảnh gần nhất.'),
                _bulletItem('3. Bật chuông điện thoại để nhận thông báo rung khi còn 2 số nữa đến lượt.'),
                _bulletItem('4. Khi màn hình báo đến lượt, vui lòng gõ cửa và bước vào phòng 305.'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: () {
              store.refreshQueue();
            },
            icon: const Icon(Icons.sync_rounded),
            label: const Text('Cập nhật tiến độ hàng đợi'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _queueStatBox(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _bulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, height: 1.4),
      ),
    );
  }
}


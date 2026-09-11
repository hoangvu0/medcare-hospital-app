import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../state/medical_store.dart';

class MedicationTrackerPage extends StatelessWidget {
  const MedicationTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final schedule = store.medicineSchedule;
    final adherence = store.medicineAdherenceRate;
    final takenCount = schedule.where((m) => m.isTaken).length;
    final totalCount = schedule.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhắc lịch Uống thuốc'),
        actions: [
          IconButton(
            tooltip: 'Xem đơn thuốc gốc',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.prescription),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Adherence Progress Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0057CD), Color(0xFF003882)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x330057CD),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tuân thủ phác đồ hôm nay',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(adherence * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '$takenCount / $totalCount liều thuốc đã uống',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: adherence,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ADE80)),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  adherence >= 1.0
                      ? 'Tuyệt vời! Bạn đã hoàn thành toàn bộ liều thuốc trong ngày.'
                      : 'Đơn thuốc tiệt trừ vi khuẩn Helicobacter Pylori (14 ngày).',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Prescription summary badge
          Row(
            children: [
              const Text(
                'LỊCH UỐNG THUỐC TRONG NGÀY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0057CD),
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                'Toa thuốc: DT-2026-089',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Morning section
          _buildPeriodSection(
            context,
            title: 'Buổi Sáng',
            icon: Icons.wb_sunny_rounded,
            iconColor: Colors.amber,
            items: schedule.where((m) => m.period == 'Sáng').toList(),
            store: store,
          ),
          const SizedBox(height: 16),

          // Evening section
          _buildPeriodSection(
            context,
            title: 'Buổi Tối',
            icon: Icons.nights_stay_rounded,
            iconColor: Colors.indigo,
            items: schedule.where((m) => m.period == 'Tối').toList(),
            store: store,
          ),
          const SizedBox(height: 20),

          // Note Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Lưu ý y khoa: Kháng sinh Clarithromycin & Amoxicillin phải uống đủ liều 14 ngày ngay cả khi hết triệu chứng đau dạ dày để tránh vi khuẩn kháng thuốc.',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<dynamic> items,
    required MedicalStore store,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) {
          final isTaken = item.isTaken as bool;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isTaken
                    ? Colors.green.withValues(alpha: 0.5)
                    : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: CircleAvatar(
                backgroundColor: isTaken ? const Color(0xFFDCFCE7) : const Color(0xFFE0E7FF),
                child: Icon(
                  isTaken ? Icons.check_circle : Icons.medication_liquid_outlined,
                  color: isTaken ? Colors.green : const Color(0xFF0057CD),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.medicineName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        decoration: isTaken ? TextDecoration.lineThrough : null,
                        color: isTaken ? Colors.grey : null,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.timeSlot,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Liều dùng: ${item.dosage}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  Text(item.instruction, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  if (item.takenAt != null)
                    Text(
                      'Đã uống lúc ${item.takenAt!.hour.toString().padLeft(2, '0')}:${item.takenAt!.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              trailing: IconButton(
                tooltip: isTaken ? 'Đánh dấu chưa uống' : 'Đánh dấu đã uống',
                icon: Icon(
                  isTaken ? Icons.check_box : Icons.check_box_outline_blank,
                  color: isTaken ? Colors.green : Colors.grey,
                  size: 28,
                ),
                onPressed: () => store.toggleMedicineTaken(item.id),
              ),
            ),
          );
        }),
      ],
    );
  }
}


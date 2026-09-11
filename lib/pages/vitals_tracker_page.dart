import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../state/medical_store.dart';

class VitalsTrackerPage extends StatelessWidget {
  const VitalsTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final vitals = store.vitals;
    final latest = vitals.isNotEmpty ? vitals.first : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉ số Sinh hiệu & Sức khỏe'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVitalDialog(context, store),
        icon: const Icon(Icons.add),
        label: const Text('Đo chỉ số mới'),
        backgroundColor: const Color(0xFF0057CD),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (latest != null) ...[
            Text(
              'CHỈ SỐ GẦN NHẤT (${_formatDate(latest.timestamp)})',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0057CD),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            // Grid of 4 key vitals
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                _vitalCard(
                  context,
                  title: 'Huyết áp',
                  value: '${latest.systolic}/${latest.diastolic}',
                  unit: 'mmHg',
                  badge: latest.bpStatus,
                  badgeColor: Colors.green,
                  icon: Icons.favorite_rounded,
                  iconColor: Colors.red,
                ),
                _vitalCard(
                  context,
                  title: 'Nhịp tim',
                  value: '${latest.heartRate}',
                  unit: 'bpm',
                  badge: latest.heartRate <= 80 ? 'Bình thường' : 'Hơi nhanh',
                  badgeColor: Colors.blue,
                  icon: Icons.monitor_heart_rounded,
                  iconColor: Colors.purple,
                ),
                _vitalCard(
                  context,
                  title: 'Đường huyết đói',
                  value: latest.bloodGlucose.toStringAsFixed(1),
                  unit: 'mg/dL',
                  badge: latest.bloodGlucose <= 100 ? 'An toàn' : 'Hơi cao',
                  badgeColor: Colors.teal,
                  icon: Icons.water_drop_rounded,
                  iconColor: Colors.teal,
                ),
                _vitalCard(
                  context,
                  title: 'Thể trạng BMI',
                  value: latest.bmi.toStringAsFixed(1),
                  unit: 'kg/m²',
                  badge: latest.bmiCategory,
                  badgeColor: Colors.orange,
                  icon: Icons.accessibility_new_rounded,
                  iconColor: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Weight & Height Detail
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(

                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _miniStat('Chiều cao', '${latest.heightCm.toInt()} cm'),
                  const SizedBox(
                    height: 30,
                    child: VerticalDivider(width: 20),
                  ),
                  _miniStat('Cân nặng', '${latest.weightKg} kg'),
                  const SizedBox(
                    height: 30,
                    child: VerticalDivider(width: 20),
                  ),
                  _miniStat('Tiêu chuẩn WHO', 'Chuẩn châu Á'),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // History timeline
          const Text(
            'LỊCH SỬ CÁC LẦN ĐO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0057CD),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          ...vitals.map((item) => _buildHistoryItem(context, item)),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _vitalCard(
    BuildContext context, {
    required String title,
    required String value,
    required String unit,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required Color iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              Icon(icon, color: iconColor, size: 18),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: badgeColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHistoryItem(BuildContext context, VitalSignRecord item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE0E7FF),
            child: const Icon(Icons.speed, color: Color(0xFF0057CD), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'HA: ${item.systolic}/${item.diastolic} mmHg',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Tim: ${item.heartRate} bpm',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Đường huyết: ${item.bloodGlucose} mg/dL • BMI: ${item.bmi.toStringAsFixed(1)} (${item.weightKg}kg)',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                if (item.note != null && item.note!.isNotEmpty)
                  Text(
                    'Ghi chú: ${item.note}',
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
          Text(
            _formatDate(item.timestamp),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showAddVitalDialog(BuildContext context, MedicalStore store) {
    final sysCtrl = TextEditingController(text: '120');
    final diaCtrl = TextEditingController(text: '80');
    final hrCtrl = TextEditingController(text: '75');
    final gluCtrl = TextEditingController(text: '95');
    final weightCtrl = TextEditingController(text: '68');
    final noteCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ghi nhận chỉ số sinh hiệu mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: sysCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tâm thu (Sys)', suffixText: 'mmHg'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: diaCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tâm trương (Dia)', suffixText: 'mmHg'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: hrCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Nhịp tim', suffixText: 'bpm'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: gluCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Đường huyết', suffixText: 'mg/dL'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Cân nặng hiện tại', suffixText: 'kg'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Ghi chú (Tùy chọn)', hintText: 'VD: Đo lúc vừa thức dậy'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final sys = int.tryParse(sysCtrl.text) ?? 120;
              final dia = int.tryParse(diaCtrl.text) ?? 80;
              final hr = int.tryParse(hrCtrl.text) ?? 75;
              final glu = double.tryParse(gluCtrl.text) ?? 95.0;
              final weight = double.tryParse(weightCtrl.text) ?? 68.0;

              store.addVitalRecord(
                VitalSignRecord(
                  timestamp: DateTime.now(),
                  systolic: sys,
                  diastolic: dia,
                  heartRate: hr,
                  bloodGlucose: glu,
                  weightKg: weight,
                  heightCm: 174.0,
                  note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                ),
              );

              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã cập nhật chỉ số sinh hiệu thành công!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Lưu chỉ số'),
          ),
        ],
      ),
    );
  }
}

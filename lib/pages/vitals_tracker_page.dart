import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../state/medical_store.dart';

/// Trang quản lý và theo dõi chỉ số sinh hiệu sức khỏe cá nhân (Vitals Tracker).
/// Cung cấp theo dõi: Huyết áp, Nhịp tim, Đường huyết đói, Thể trạng BMI,
/// cùng lịch sử đo lường y tế và phân loại chuẩn WHO / ADA.
class VitalsTrackerPage extends StatefulWidget {
  const VitalsTrackerPage({super.key});

  @override
  State<VitalsTrackerPage> createState() => _VitalsTrackerPageState();
}

class _VitalsTrackerPageState extends State<VitalsTrackerPage> {
  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final vitals = store.vitals;
    final latest = vitals.isNotEmpty ? vitals.first : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉ số Sinh hiệu & Sức khỏe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Chuẩn tham chiếu y khoa',
            onPressed: () => _showMedicalReferenceSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddVitalModal(context, store),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Đo chỉ số mới'),
        backgroundColor: const Color(0xFF0057CD),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          if (latest != null) ...[
            _buildSectionHeader(
              context,
              title: 'CHỈ SỐ SINH HIỆU MỚI NHẤT',
              subtitle: 'Cập nhật lúc: ${_formatTimestamp(latest.timestamp)}',
            ),
            const SizedBox(height: 12),
            _buildVitalsGrid(context, latest),
            const SizedBox(height: 14),
            _buildBodyMetricsCard(context, latest, isDark),
            const SizedBox(height: 14),
            _buildHealthStatusBanner(context, latest, isDark),
          ] else
            _buildEmptyState(context, isDark),

          const SizedBox(height: 24),
          _buildSectionHeader(
            context,
            title: 'LỊCH SỬ CÁC LẦN ĐO',
            subtitle: 'Tổng cộng ${vitals.length} bản ghi theo dõi',
          ),
          const SizedBox(height: 12),
          if (vitals.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Chưa có lịch sử đo lường nào.'),
              ),
            )
          else
            ...vitals.map((item) => _buildHistoryCard(context, item, isDark)),
        ],
      ),
    );
  }

  // Tiêu đề phân đoạn với phong cách hiện đại
  Widget _buildSectionHeader(BuildContext context, {required String title, String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0057CD),
            letterSpacing: 0.6,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }

  // Lưới 4 chỉ số sinh hiệu then chốt (Huyết áp, Nhịp tim, Đường huyết đói, Thể trạng BMI)
  Widget _buildVitalsGrid(BuildContext context, VitalSignRecord record) {
    // Đánh giá nhịp tim
    final hrStatus = record.heartRate < 60
        ? 'Nhịp chậm'
        : (record.heartRate <= 100 ? 'Bình thường' : 'Nhịp nhanh');
    final hrColor = record.heartRate < 60 || record.heartRate > 100
        ? Colors.amber.shade800
        : const Color(0xFF10B981);

    // Đánh giá đường huyết đói (ADA)
    final gluStatus = record.bloodGlucose < 100
        ? 'Bình thường'
        : (record.bloodGlucose <= 125 ? 'Tiền đái tháo đường' : 'Đường huyết cao');
    final gluColor = record.bloodGlucose < 100
        ? const Color(0xFF10B981)
        : (record.bloodGlucose <= 125 ? Colors.orange : Colors.redAccent);

    // Màu sắc Huyết áp
    final bpColor = record.systolic < 120 && record.diastolic < 80
        ? const Color(0xFF10B981)
        : (record.systolic < 140 ? Colors.orange : Colors.redAccent);

    // Màu sắc BMI
    final bmiColor = record.bmi >= 18.5 && record.bmi < 23.0
        ? const Color(0xFF10B981)
        : Colors.orange;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.22,
      children: [
        _vitalCard(
          context,
          title: 'Huyết áp',
          value: '${record.systolic}/${record.diastolic}',
          unit: 'mmHg',
          badgeText: record.bpStatus,
          badgeColor: bpColor,
          icon: Icons.favorite_rounded,
          iconColor: Colors.redAccent,
        ),
        _vitalCard(
          context,
          title: 'Nhịp tim',
          value: '${record.heartRate}',
          unit: 'bpm',
          badgeText: hrStatus,
          badgeColor: hrColor,
          icon: Icons.monitor_heart_rounded,
          iconColor: Colors.deepPurple,
        ),
        _vitalCard(
          context,
          title: 'Đường huyết đói',
          value: record.bloodGlucose.toStringAsFixed(1),
          unit: 'mg/dL',
          badgeText: gluStatus,
          badgeColor: gluColor,
          icon: Icons.water_drop_rounded,
          iconColor: Colors.teal,
        ),
        _vitalCard(
          context,
          title: 'Thể trạng BMI',
          value: record.bmi.toStringAsFixed(1),
          unit: 'kg/m²',
          badgeText: record.bmiCategory,
          badgeColor: bmiColor,
          icon: Icons.accessibility_new_rounded,
          iconColor: Colors.blueAccent,
        ),
      ],
    );
  }

  // Thẻ hiển thị một chỉ số đơn lẻ
  Widget _vitalCard(
    BuildContext context, {
    required String title,
    required String value,
    required String unit,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required Color iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
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
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                badgeText,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Thẻ thống kê thể trạng Chiều cao & Cân nặng & Phân loại WHO
  Widget _buildBodyMetricsCard(BuildContext context, VitalSignRecord record, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricStat('Chiều cao', '${record.heightCm.toInt()} cm', Icons.height_rounded),
          const SizedBox(
            height: 32,
            child: VerticalDivider(width: 24, thickness: 1),
          ),
          _buildMetricStat('Cân nặng', '${record.weightKg} kg', Icons.scale_rounded),
          const SizedBox(
            height: 32,
            child: VerticalDivider(width: 24, thickness: 1),
          ),
          _buildMetricStat('Tiêu chuẩn WHO', 'Châu Á - TBD', Icons.verified_user_outlined),
        ],
      ),
    );
  }

  Widget _buildMetricStat(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // Banner tư vấn sức khỏe tổng hợp
  Widget _buildHealthStatusBanner(BuildContext context, VitalSignRecord record, bool isDark) {
    final bool allGood = record.systolic < 130 &&
        record.diastolic < 85 &&
        record.heartRate >= 60 &&
        record.heartRate <= 100 &&
        record.bloodGlucose < 100;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: allGood
            ? const Color(0xFF10B981).withValues(alpha: 0.1)
            : Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: allGood
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : Colors.amber.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            allGood ? Icons.check_circle_rounded : Icons.health_and_safety_outlined,
            color: allGood ? const Color(0xFF10B981) : Colors.amber.shade900,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allGood ? 'Tình trạng tổng quan: TỐT' : 'Gợi ý chú ý sức khỏe',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: allGood ? const Color(0xFF047857) : Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  allGood
                      ? 'Các chỉ số huyết áp, tim mạch và đường huyết đang nằm trong ngưỡng mục tiêu.'
                      : 'Nên duy trì đo huyết áp và đường huyết định kỳ mỗi sáng để theo dõi ổn định.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.grey.shade300 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Thẻ lịch sử từng lần đo
  Widget _buildHistoryCard(BuildContext context, VitalSignRecord item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0057CD).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.speed_rounded,
              color: Color(0xFF0057CD),
              size: 20,
            ),
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item.heartRate} bpm',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Đường huyết: ${item.bloodGlucose} mg/dL  •  BMI: ${item.bmi.toStringAsFixed(1)} (${item.weightKg}kg)',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
                if (item.note != null && item.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.notes_rounded, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.note!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTimestamp(item.timestamp),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 4),
              Text(
                item.bpStatus,
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF0057CD), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Trạng thái khi chưa có chỉ số
  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.monitor_heart_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'Chưa có dữ liệu sinh hiệu nào',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Nhấn nút "Đo chỉ số mới" để bắt đầu theo dõi sức khỏe của bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // Mở BottomSheet / Dialog thêm mới chỉ số sinh hiệu
  void _openAddVitalModal(BuildContext context, MedicalStore store) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) => _AddVitalBottomSheet(store: store),
    );
  }

  // Bảng tra cứu chuẩn y tế
  void _showMedicalReferenceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bảng tham chiếu chuẩn Y khoa',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildReferenceRow('Huyết áp tối ưu', '< 120 / < 80 mmHg', 'ESC/ESH'),
              _buildReferenceRow('Huyết áp bình thường', '120-129 / 80-84 mmHg', 'ESC/ESH'),
              _buildReferenceRow('Tiền tăng huyết áp', '130-139 / 85-89 mmHg', 'ESC/ESH'),
              _buildReferenceRow('Nhịp tim nghỉ ngơi', '60 - 100 nhịp/phút', 'AHA'),
              _buildReferenceRow('Đường huyết lúc đói', '70 - 99 mg/dL', 'ADA'),
              _buildReferenceRow('BMI chuẩn châu Á', '18.5 - 22.9 kg/m²', 'WHO WPRO'),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đã hiểu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferenceRow(String label, String value, String standard) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Row(
            children: [
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Text('($standard)', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$min';
  }
}

/// Bottom Sheet nhập liệu chỉ số sinh hiệu mới, sạch sẽ và có Form validation
class _AddVitalBottomSheet extends StatefulWidget {
  const _AddVitalBottomSheet({required this.store});

  final MedicalStore store;

  @override
  State<_AddVitalBottomSheet> createState() => _AddVitalBottomSheetState();
}

class _AddVitalBottomSheetState extends State<_AddVitalBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _sysCtrl;
  late final TextEditingController _diaCtrl;
  late final TextEditingController _hrCtrl;
  late final TextEditingController _gluCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _sysCtrl = TextEditingController(text: '120');
    _diaCtrl = TextEditingController(text: '80');
    _hrCtrl = TextEditingController(text: '75');
    _gluCtrl = TextEditingController(text: '95');
    _weightCtrl = TextEditingController(text: '68');
    _heightCtrl = TextEditingController(text: '174');
    _noteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _sysCtrl.dispose();
    _diaCtrl.dispose();
    _hrCtrl.dispose();
    _gluCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final sys = int.tryParse(_sysCtrl.text) ?? 120;
    final dia = int.tryParse(_diaCtrl.text) ?? 80;
    final hr = int.tryParse(_hrCtrl.text) ?? 75;
    final glu = double.tryParse(_gluCtrl.text) ?? 95.0;
    final weight = double.tryParse(_weightCtrl.text) ?? 68.0;
    final height = double.tryParse(_heightCtrl.text) ?? 174.0;
    final note = _noteCtrl.text.trim();

    widget.store.addVitalRecord(
      VitalSignRecord(
        timestamp: DateTime.now(),
        systolic: sys,
        diastolic: dia,
        heartRate: hr,
        bloodGlucose: glu,
        weightKg: weight,
        heightCm: height,
        note: note.isEmpty ? null : note,
      ),
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu chỉ số sinh hiệu thành công!'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh kéo nhỏ (handle)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ghi nhận Sinh hiệu Mới',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Huyết áp
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sysCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Tâm thu (Sys)', 'mmHg'),
                      validator: (v) {
                        final val = int.tryParse(v ?? '');
                        if (val == null || val < 50 || val > 260) {
                          return '50-260';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _diaCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Tâm trương (Dia)', 'mmHg'),
                      validator: (v) {
                        final val = int.tryParse(v ?? '');
                        if (val == null || val < 30 || val > 160) {
                          return '30-160';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Nhịp tim & Đường huyết
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hrCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Nhịp tim', 'bpm'),
                      validator: (v) {
                        final val = int.tryParse(v ?? '');
                        if (val == null || val < 30 || val > 220) {
                          return '30-220';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _gluCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration('Đường huyết', 'mg/dL'),
                      validator: (v) {
                        final val = double.tryParse(v ?? '');
                        if (val == null || val < 20 || val > 500) {
                          return '20-500';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Cân nặng & Chiều cao
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration('Cân nặng', 'kg'),
                      validator: (v) {
                        final val = double.tryParse(v ?? '');
                        if (val == null || val < 2 || val > 300) {
                          return 'Hợp lệ';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _heightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration('Chiều cao', 'cm'),
                      validator: (v) {
                        final val = double.tryParse(v ?? '');
                        if (val == null || val < 40 || val > 250) {
                          return 'Hợp lệ';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Ghi chú
              TextFormField(
                controller: _noteCtrl,
                decoration: _inputDecoration('Ghi chú (Tùy chọn)', null).copyWith(
                  hintText: 'VD: Đo sau bữa ăn 2 tiếng, cảm thấy khỏe...',
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Hủy bỏ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Lưu chỉ số'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0057CD),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String? suffix) {
    return InputDecoration(
      labelText: label,
      suffixText: suffix,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0057CD), width: 1.8),
      ),
    );
  }
}

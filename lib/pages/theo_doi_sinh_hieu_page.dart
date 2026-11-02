import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../state/medical_store.dart';

/// Trang theo dõi chỉ số sinh hiệu sức khỏe cá nhân (Vitals Tracker).
/// Cung cấp theo dõi: Huyết áp, Nhịp tim, Đường huyết đói, Thể trạng BMI,
/// cùng lịch sử đo lường y tế và phân loại chuẩn WHO / ADA / ESC.
class VitalsTrackerPage extends StatefulWidget {
  const VitalsTrackerPage({super.key});

  @override
  State<VitalsTrackerPage> createState() => _VitalsTrackerPageState();
}

class _VitalsTrackerPageState extends State<VitalsTrackerPage> {
  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final activeMember = store.activeFamilyMember;
    final vitals = store.vitals
        .where(
          (v) =>
              v.patientId == activeMember.id ||
              (v.patientId == null &&
                  (activeMember.relation == FamilyRelation.self ||
                      activeMember.id == store.profile.id)),
        )
        .toList();
    final latest = vitals.isNotEmpty ? vitals.first : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉ số Sinh hiệu & Sức khỏe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Chuẩn tham chiếu y khoa',
            onPressed: () => _showReferenceSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddModal(context, store),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Đo chỉ số mới'),
        backgroundColor: const Color(0xFF0057CD),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          if (latest != null) ...[
            _sectionHeader(
              title: 'CHỈ SỐ SINH HIỆU MỚI NHẤT',
              subtitle: 'Cập nhật lúc: ${_fmt(latest.timestamp)}',
            ),
            const SizedBox(height: 12),
            _buildGrid(context, latest),
            const SizedBox(height: 14),
            _buildBodyCard(context, latest, isDark),
            const SizedBox(height: 14),
            _buildStatusBanner(context, latest, isDark),
          ] else
            _buildEmpty(isDark),
          const SizedBox(height: 24),
          _sectionHeader(
            title: 'LỊCH SỬ CÁC LẦN ĐO',
            subtitle: 'Tổng cộng ${vitals.length} bản ghi',
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
            ...vitals.map((r) => _buildHistoryItem(context, r, isDark)),
        ],
      ),
    );
  }

  // ── Tiêu đề phân đoạn ────────────────────────────────────────────────────

  Widget _sectionHeader({required String title, String? subtitle}) {
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
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }

  // ── Lưới 4 chỉ số sinh hiệu ────────────────────────────────────────────

  Widget _buildGrid(BuildContext context, VitalSignRecord r) {
    final hrStatus = r.heartRate < 60
        ? 'Nhịp chậm'
        : (r.heartRate <= 100 ? 'Bình thường' : 'Nhịp nhanh');
    final hrColor = (r.heartRate < 60 || r.heartRate > 100)
        ? Colors.orange
        : const Color(0xFF10B981);

    final gluStatus = r.bloodGlucose < 100
        ? 'Bình thường'
        : (r.bloodGlucose <= 125 ? 'Tiền đái tháo đường' : 'Đường huyết cao');
    final gluColor = r.bloodGlucose < 100
        ? const Color(0xFF10B981)
        : (r.bloodGlucose <= 125 ? Colors.orange : Colors.redAccent);

    final bpColor = (r.systolic < 120 && r.diastolic < 80)
        ? const Color(0xFF10B981)
        : (r.systolic < 140 ? Colors.orange : Colors.redAccent);

    final bmiColor = (r.bmi >= 18.5 && r.bmi < 23.0)
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
          value: '${r.systolic}/${r.diastolic}',
          unit: 'mmHg',
          badge: r.bpStatus,
          badgeColor: bpColor,
          icon: Icons.favorite_rounded,
          iconColor: Colors.redAccent,
        ),
        _vitalCard(
          context,
          title: 'Nhịp tim',
          value: '${r.heartRate}',
          unit: 'bpm',
          badge: hrStatus,
          badgeColor: hrColor,
          icon: Icons.monitor_heart_rounded,
          iconColor: Colors.deepPurple,
        ),
        _vitalCard(
          context,
          title: 'Đường huyết đói',
          value: r.bloodGlucose.toStringAsFixed(1),
          unit: 'mg/dL',
          badge: gluStatus,
          badgeColor: gluColor,
          icon: Icons.water_drop_rounded,
          iconColor: Colors.teal,
        ),
        _vitalCard(
          context,
          title: 'Thể trạng BMI',
          value: r.bmi.toStringAsFixed(1),
          unit: 'kg/m²',
          badge: r.bmiCategory,
          badgeColor: bmiColor,
          icon: Icons.accessibility_new_rounded,
          iconColor: Colors.blueAccent,
        ),
      ],
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
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(icon, color: iconColor, size: 18),
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
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                badge,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Thẻ chiều cao / cân nặng ─────────────────────────────────────────────

  Widget _buildBodyCard(BuildContext context, VitalSignRecord r, bool isDark) {
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
          Expanded(
            child: _miniStat(
              'Chiều cao',
              '${r.heightCm.toInt()} cm',
              Icons.height_rounded,
            ),
          ),
          const SizedBox(
            height: 32,
            child: VerticalDivider(width: 18, thickness: 1),
          ),
          Expanded(
            child: _miniStat(
              'Cân nặng',
              '${r.weightKg} kg',
              Icons.scale_rounded,
            ),
          ),
          const SizedBox(
            height: 32,
            child: VerticalDivider(width: 18, thickness: 1),
          ),
          Expanded(
            child: _miniStat(
              'Tiêu chuẩn',
              'WHO Châu Á',
              Icons.verified_user_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: Colors.grey.shade500),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ── Banner đánh giá tổng quan ─────────────────────────────────────────────

  Widget _buildStatusBanner(
    BuildContext context,
    VitalSignRecord r,
    bool isDark,
  ) {
    final good =
        r.systolic < 130 &&
        r.diastolic < 85 &&
        r.heartRate >= 60 &&
        r.heartRate <= 100 &&
        r.bloodGlucose < 100;

    final color = good ? const Color(0xFF10B981) : Colors.amber.shade800;
    final bgColor = good
        ? const Color(0xFF10B981).withValues(alpha: 0.1)
        : Colors.amber.withValues(alpha: 0.12);
    final borderColor = good
        ? const Color(0xFF10B981).withValues(alpha: 0.3)
        : Colors.amber.withValues(alpha: 0.3);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            good
                ? Icons.check_circle_rounded
                : Icons.health_and_safety_outlined,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  good ? 'Tình trạng tổng quan: TỐT' : 'Gợi ý chú ý sức khỏe',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  good
                      ? 'Huyết áp, tim mạch và đường huyết đang nằm trong ngưỡng mục tiêu.'
                      : 'Nên đo huyết áp và đường huyết định kỳ mỗi sáng để theo dõi ổn định.',
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

  // ── Thẻ lịch sử từng lần đo ──────────────────────────────────────────────

  Widget _buildHistoryItem(
    BuildContext context,
    VitalSignRecord r,
    bool isDark,
  ) {
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
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'HA: ${r.systolic}/${r.diastolic} mmHg',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${r.heartRate} bpm',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Đường huyết: ${r.bloodGlucose} mg/dL  •  BMI: ${r.bmi.toStringAsFixed(1)} (${r.weightKg}kg)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
                if (r.note != null && r.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.notes_rounded,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          r.note!,
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
                _fmt(r.timestamp),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 4),
              Text(
                r.bpStatus,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF0057CD),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Trạng thái rỗng ──────────────────────────────────────────────────────

  Widget _buildEmpty(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.monitor_heart_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'Chưa có dữ liệu sinh hiệu nào',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Nhấn "Đo chỉ số mới" để bắt đầu theo dõi sức khỏe của bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ── Modal thêm chỉ số mới ─────────────────────────────────────────────────

  void _openAddModal(BuildContext context, MedicalStore store) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddVitalSheet(store: store),
    );
  }

  // ── Bảng tra cứu tham chiếu y khoa ───────────────────────────────────────

  void _showReferenceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
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
              _refRow('Huyết áp tối ưu', '< 120 / < 80 mmHg', 'ESC/ESH'),
              _refRow(
                'Huyết áp bình thường',
                '120-129 / 80-84 mmHg',
                'ESC/ESH',
              ),
              _refRow('Tiền tăng huyết áp', '130-139 / 85-89 mmHg', 'ESC/ESH'),
              _refRow('Nhịp tim nghỉ ngơi', '60 - 100 nhịp/phút', 'AHA'),
              _refRow('Đường huyết lúc đói', '70 - 99 mg/dL', 'ADA'),
              _refRow('BMI chuẩn châu Á', '18.5 - 22.9 kg/m²', 'WHO WPRO'),
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

  Widget _refRow(String label, String value, String src) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 6),
          Text(
            '($src)',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmt(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m $h:$min';
  }
}

// ── Bottom Sheet nhập liệu ────────────────────────────────────────────────────

class _AddVitalSheet extends StatefulWidget {
  const _AddVitalSheet({required this.store});

  final MedicalStore store;

  @override
  State<_AddVitalSheet> createState() => _AddVitalSheetState();
}

class _AddVitalSheetState extends State<_AddVitalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _sys;
  late final TextEditingController _dia;
  late final TextEditingController _hr;
  late final TextEditingController _glu;
  late final TextEditingController _weight;
  late final TextEditingController _height;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _sys = TextEditingController(text: '120');
    _dia = TextEditingController(text: '80');
    _hr = TextEditingController(text: '75');
    _glu = TextEditingController(text: '95');
    _weight = TextEditingController(text: '68');
    _height = TextEditingController(text: '174');
    _note = TextEditingController();
  }

  @override
  void dispose() {
    _sys.dispose();
    _dia.dispose();
    _hr.dispose();
    _glu.dispose();
    _weight.dispose();
    _height.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.store.addVitalRecord(
      VitalSignRecord(
        timestamp: DateTime.now(),
        systolic: int.tryParse(_sys.text) ?? 120,
        diastolic: int.tryParse(_dia.text) ?? 80,
        heartRate: int.tryParse(_hr.text) ?? 75,
        bloodGlucose: double.tryParse(_glu.text) ?? 95.0,
        weightKg: double.tryParse(_weight.text) ?? 68.0,
        heightCm: double.tryParse(_height.text) ?? 174.0,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        patientId: widget.store.activeFamilyMember.id,
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 20),
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sys,
                      keyboardType: TextInputType.number,
                      decoration: _dec('Tâm thu', 'mmHg'),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return (n == null || n < 50 || n > 260)
                            ? '50–260'
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _dia,
                      keyboardType: TextInputType.number,
                      decoration: _dec('Tâm trương', 'mmHg'),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return (n == null || n < 30 || n > 160)
                            ? '30–160'
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hr,
                      keyboardType: TextInputType.number,
                      decoration: _dec('Nhịp tim', 'bpm'),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return (n == null || n < 30 || n > 220)
                            ? '30–220'
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _glu,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _dec('Đường huyết', 'mg/dL'),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        return (n == null || n < 20 || n > 500)
                            ? '20–500'
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weight,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _dec('Cân nặng', 'kg'),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        return (n == null || n < 2 || n > 300)
                            ? 'Không hợp lệ'
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _height,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _dec('Chiều cao', 'cm'),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        return (n == null || n < 40 || n > 250)
                            ? 'Không hợp lệ'
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                decoration: _dec(
                  'Ghi chú (tùy chọn)',
                  null,
                ).copyWith(hintText: 'VD: Đo sau bữa ăn 2 tiếng...'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Hủy'),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

  InputDecoration _dec(String label, String? suffix) => InputDecoration(
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

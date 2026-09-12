import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../routes/app_routes.dart';
import '../state/medical_store.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});
  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  int _selectedDate = 0;
  String? _selectedTime;
  bool _isSelf = true;
  bool _useInsurance = false;
  final _reasonController = TextEditingController();

  static const _times = ['08:00', '09:00', '10:00', '14:00', '15:00', '16:00'];
  static const _primary = Color(0xFF0D6EFD);
  static const _success = Color(0xFF10B981);
  static const _danger = Color(0xFFEF4444);
  static const _warning = Color(0xFFF59E0B);

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final doctor = _doctorFromArguments(context, store);
    final dates = List.generate(7, (i) => DateTime.now().add(Duration(days: i + 1)));
    final date = dates[_selectedDate];
    final dateStr = _dateKey(date);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt lịch khám'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Thông tin slot',
            onPressed: () => _showSlotLegend(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          _DoctorSummary(doctor: doctor),
          const SizedBox(height: 16),

          // Chọn ngày
          _CardSection(
            title: 'Chọn ngày khám',
            child: SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: dates.length,
                separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final item = dates[index];
                  final selected = _selectedDate == index;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedDate = index;
                      _selectedTime = null; // reset giờ khi đổi ngày
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 62,
                      decoration: BoxDecoration(
                        color: selected ? _primary : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? _primary : Colors.grey.shade300,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _weekday(item),
                            style: TextStyle(
                              fontSize: 11,
                              color: selected ? Colors.white70 : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.day}/${item.month}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: selected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Chọn khung giờ với slot availability
          _CardSection(
            title: 'Khung giờ tiếp nhận',
            child: _buildTimeSlotGrid(store, doctor.id, dateStr),
          ),
          const SizedBox(height: 16),

          // Thông tin người khám
          _CardSection(
            title: 'Thông tin người khám',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('Bản thân'),
                      icon: Icon(Icons.person),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('Người thân'),
                      icon: Icon(Icons.people),
                    ),
                  ],
                  selected: {_isSelf},
                  onSelectionChanged: (value) =>
                      setState(() => _isSelf = value.first),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSelf
                      ? store.profile.name
                      : 'Người thân (cần bổ sung hồ sơ)',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _useInsurance,
                  onChanged: (value) => setState(() => _useInsurance = value),
                  title: const Text('Áp dụng BHYT'),
                  subtitle: const Text(
                    'Mức tạm tính sẽ được xác nhận tại cơ sở khám.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Lý do khám
          _CardSection(
            title: 'Lý do khám',
            child: TextField(
              controller: _reasonController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Mô tả triệu chứng hoặc nhu cầu khám.',
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, store, doctor, date, dateStr),
    );
  }

  // ── Lưới slot giờ ──────────────────────────────────────────────────────────

  Widget _buildTimeSlotGrid(MedicalStore store, String doctorId, String dateStr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: _times.map((time) {
            final slot = store.getSlotInfo(doctorId, dateStr, time);
            return _TimeSlotChip(
              time: time,
              slot: slot,
              selected: _selectedTime == time,
              onTap: slot.isFull
                  ? null
                  : () => setState(() => _selectedTime = time),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Chú thích màu
        Row(
          children: [
            _legend(color: _success, label: 'Còn chỗ'),
            const SizedBox(width: 14),
            _legend(color: _warning, label: 'Sắp đầy (≤2)'),
            const SizedBox(width: 14),
            _legend(color: _danger, label: 'Hết chỗ'),
          ],
        ),
      ],
    );
  }

  Widget _legend({required Color color, required String label}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      );

  // ── Bottom bar xác nhận ───────────────────────────────────────────────────

  Widget _buildBottomBar(
    BuildContext context,
    MedicalStore store,
    DoctorProfile doctor,
    DateTime date,
    String dateStr,
  ) {
    final canProceed = _selectedTime != null;
    final slot = _selectedTime != null
        ? store.getSlotInfo(doctor.id, dateStr, _selectedTime!)
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (slot != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_seat_outlined,
                        size: 15,
                        color: slot.isFull
                            ? _danger
                            : slot.remaining <= 2
                                ? _warning
                                : _success),
                    const SizedBox(width: 6),
                    Text(
                      slot.isFull
                          ? 'Slot $_selectedTime đã hết chỗ — chọn giờ khác'
                          : 'Khung $_selectedTime: còn ${slot.remaining}/${slot.capacity} chỗ',
                      style: TextStyle(
                        fontSize: 12,
                        color: slot.isFull
                            ? _danger
                            : slot.remaining <= 2
                                ? _warning
                                : _success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: canProceed
                    ? () => _continueBooking(context, store, doctor, date, dateStr)
                    : null,
                icon: const Icon(Icons.arrow_forward),
                label: Text(
                  canProceed ? 'Xem lại lịch hẹn — $_selectedTime' : 'Chọn khung giờ để tiếp tục',
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logic đặt lịch ──────────────────────────────────────────────────────────

  DoctorProfile _doctorFromArguments(BuildContext context, MedicalStore store) {
    final argument = ModalRoute.of(context)?.settings.arguments;
    return argument is DoctorProfile ? argument : store.doctors[1];
  }

  void _continueBooking(
    BuildContext context,
    MedicalStore store,
    DoctorProfile doctor,
    DateTime date,
    String dateStr,
  ) {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập lý do khám.')),
      );
      return;
    }

    final time = _selectedTime!;

    // ── Kiểm tra slot race condition: lần cuối trước khi navigate ──
    final slot = store.getSlotInfo(doctor.id, dateStr, time);
    if (slot.isFull) {
      _showSlotFullDialog(context, time);
      setState(() => _selectedTime = null);
      return;
    }

    final parts = time.split(':');
    final draft = AppointmentDraft(
      doctor: doctor,
      dateTime: DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      ),
      patientName: _isSelf ? store.profile.name : 'Người thân',
      reason: reason,
      useInsurance: _useInsurance,
    );
    Navigator.pushNamed(
      context,
      AppRoutes.confirmAppointment,
      arguments: draft,
    );
  }

  void _showSlotFullDialog(BuildContext context, String time) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.event_busy, color: _danger),
            SizedBox(width: 8),
            Text('Hết chỗ!'),
          ],
        ),
        content: Text(
          'Xin lỗi, khung giờ $time vừa hết chỗ trong lúc bạn đặt.\n\nVui lòng chọn khung giờ khác.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đổi giờ khác'),
          ),
        ],
      ),
    );
  }

  void _showSlotLegend(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Trạng thái slot khám',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _legendRow(Icons.check_circle_outlined, _success, 'Còn chỗ',
                'Slot còn nhiều chỗ trống, bạn có thể đặt bình thường.'),
            const SizedBox(height: 12),
            _legendRow(Icons.warning_amber_outlined, _warning, 'Sắp đầy',
                'Còn ≤2 chỗ. Nhanh tay đặt trước khi hết!'),
            const SizedBox(height: 12),
            _legendRow(Icons.block, _danger, 'Hết chỗ',
                'Slot đã đầy. Chọn khung giờ khác hoặc ngày khác.'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đã hiểu'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendRow(IconData icon, Color color, String title, String desc) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(desc, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      );

  String _weekday(DateTime value) =>
      const ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'][value.weekday % 7];
}

// ── Time Slot Chip Widget ─────────────────────────────────────────────────────

class _TimeSlotChip extends StatelessWidget {
  const _TimeSlotChip({
    required this.time,
    required this.slot,
    required this.selected,
    this.onTap,
  });

  final String time;
  final SlotConfig slot;
  final bool selected;
  final VoidCallback? onTap;

  static const _primary = Color(0xFF0D6EFD);
  static const _success = Color(0xFF10B981);
  static const _danger = Color(0xFFEF4444);
  static const _warning = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final isFull = slot.isFull;
    final isAlmostFull = !isFull && slot.remaining <= 2;

    final borderColor = selected
        ? _primary
        : isFull
            ? _danger.withValues(alpha: 0.4)
            : isAlmostFull
                ? _warning.withValues(alpha: 0.5)
                : _success.withValues(alpha: 0.4);

    final bgColor = selected
        ? _primary
        : isFull
            ? Colors.grey.shade100
            : isAlmostFull
                ? _warning.withValues(alpha: 0.08)
                : _success.withValues(alpha: 0.06);

    final labelColor = selected
        ? Colors.white
        : isFull
            ? Colors.grey.shade400
            : Colors.black87;

    final badgeColor = isFull
        ? _danger
        : isAlmostFull
            ? _warning
            : _success;

    final badgeText = isFull
        ? 'Hết chỗ'
        : isAlmostFull
            ? 'Còn ${slot.remaining}'
            : '${slot.remaining}/${slot.capacity}';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _primary : borderColor,
            width: selected ? 2 : 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : badgeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Doctor Summary Card ──────────────────────────────────────────────────────

class _DoctorSummary extends StatelessWidget {
  const _DoctorSummary({required this.doctor});
  final DoctorProfile doctor;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(doctor.name,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${doctor.specialty}\n${doctor.location}'),
          isThreeLine: true,
          trailing: Text(
            '${doctor.price ~/ 1000}.000đ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
}

// ── Card Section ─────────────────────────────────────────────────────────────

class _CardSection extends StatelessWidget {
  const _CardSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      );
}

import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../state/medical_store.dart';

const _kPrimary = Color(0xFF0D6EFD);
const _kSuccess = Color(0xFF10B981);
const _kWarning = Color(0xFFF59E0B);
const _kDanger = Color(0xFFEF4444);

/// Trang Admin quản lý slot đặt khám.
/// Truy cập qua Settings → Quản lý Slot → nhập mật khẩu admin.
class AdminSlotPage extends StatefulWidget {
  const AdminSlotPage({super.key});

  @override
  State<AdminSlotPage> createState() => _AdminSlotPageState();
}

class _AdminSlotPageState extends State<AdminSlotPage> {
  static const _adminPassword = 'admin123';
  bool _authenticated = false;

  int _selectedDoctorIndex = 0;
  int _selectedDateIndex = 0;

  final _pwCtrl = TextEditingController();
  bool _pwVisible = false;

  @override
  void dispose() {
    _pwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin — Quản lý Slot Khám'),
        backgroundColor: const Color(0xFF0D2657),
        foregroundColor: Colors.white,
        actions: [
          if (_authenticated)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                avatar: const Icon(Icons.admin_panel_settings,
                    size: 16, color: Colors.white),
                label: const Text('Admin',
                    style: TextStyle(color: Colors.white, fontSize: 11)),
                backgroundColor: Colors.white.withValues(alpha: 0.15),
              ),
            ),
        ],
      ),
      body: _authenticated ? _buildPanel() : _buildLoginScreen(),
    );
  }

  // ── Màn hình đăng nhập admin ───────────────────────────────────────────────

  Widget _buildLoginScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.admin_panel_settings,
                  size: 48, color: _kPrimary),
            ),
            const SizedBox(height: 20),
            const Text('Admin Panel',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Nhập mật khẩu quản trị để tiếp tục',
                style:
                    TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 32),
            TextField(
              controller: _pwCtrl,
              obscureText: !_pwVisible,
              keyboardType: TextInputType.visiblePassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu Admin',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_pwVisible
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _pwVisible = !_pwVisible),
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _login,
                icon: const Icon(Icons.login),
                label: const Text('Đăng nhập',
                    style: TextStyle(fontSize: 15)),
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Mật khẩu demo: admin123',
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  void _login() {
    if (_pwCtrl.text.trim() == _adminPassword) {
      setState(() => _authenticated = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu không đúng!'),
          backgroundColor: _kDanger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Admin Panel ────────────────────────────────────────────────────────────

  Widget _buildPanel() {
    final store = MedicalScope.of(context);
    final doctors = store.doctors;
    final dates = List.generate(
        7, (i) => DateTime.now().add(Duration(days: i + 1)));
    final selectedDoctor = doctors[_selectedDoctorIndex];
    final selectedDate = dates[_selectedDateIndex];
    final dateStr = _dateKey(selectedDate);
    final slots = store.getSlotsForDoctorDate(selectedDoctor.id, dateStr);

    // Thống kê
    final totalCapacity = slots.fold(0, (s, sl) => s + sl.capacity);
    final totalBooked = slots.fold(0, (s, sl) => s + sl.booked);
    final fillRate = totalCapacity > 0
        ? (totalBooked / totalCapacity * 100).round()
        : 0;

    return Column(
      children: [
        // Stats banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFF0D2657),
          child: Row(
            children: [
              _statChip('Tổng chỗ', '$totalCapacity', Icons.event_seat),
              const SizedBox(width: 12),
              _statChip('Đã đặt', '$totalBooked', Icons.person_pin),
              const SizedBox(width: 12),
              _statChip('Lấp đầy', '$fillRate%', Icons.pie_chart_outline),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Chọn bác sĩ
              _sectionTitle('Chọn bác sĩ'),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: doctors.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final doc = doctors[i];
                    final selected = _selectedDoctorIndex == i;
                    return FilterChip(
                      label: Text(
                        doc.name.split(' ').last,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: selected ? Colors.white : Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _selectedDoctorIndex = i),
                      selectedColor: _kPrimary,
                      checkmarkColor: Colors.white,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Chọn ngày
              _sectionTitle('Chọn ngày'),
              const SizedBox(height: 8),
              SizedBox(
                height: 62,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: dates.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final dt = dates[i];
                    final selected = _selectedDateIndex == i;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDateIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 60,
                        decoration: BoxDecoration(
                          color:
                              selected ? _kPrimary : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? _kPrimary
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _weekday(dt),
                              style: TextStyle(
                                fontSize: 11,
                                color: selected
                                    ? Colors.white70
                                    : Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '${dt.day}/${dt.month}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: selected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Slot list
              _sectionTitle(
                  'Cấu hình slot — ${selectedDoctor.name.split('.').last.trim()}  •  ${selectedDate.day}/${selectedDate.month}'),
              const SizedBox(height: 10),
              ...slots.map((slot) => _SlotAdminCard(
                    slot: slot,
                    onCapacityChanged: (newCap) {
                      store.setSlotCapacity(
                          selectedDoctor.id, dateStr, slot.time, newCap);
                    },
                  )),

              const SizedBox(height: 24),
              // Bulk reset
              OutlinedButton.icon(
                onPressed: () => _bulkSetCapacity(store, selectedDoctor, dateStr, slots),
                icon: const Icon(Icons.settings_backup_restore),
                label: const Text('Đặt lại toàn bộ slot ngày này'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statChip(String label, String value, IconData icon) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white70, size: 16),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 10)),
            ],
          ),
        ),
      );

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
            letterSpacing: 0.3),
      );

  void _bulkSetCapacity(
    MedicalStore store,
    DoctorProfile doctor,
    String dateStr,
    List<SlotConfig> slots,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        var cap = 5;
        return StatefulBuilder(
          builder: (ctx2, setSt) => AlertDialog(
            title: const Text('Đặt lại capacity'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'Tất cả slot ngày ${slots.first.date} của bác sĩ này sẽ được đặt về cùng một mức.',
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: cap > 1 ? () => setSt(() => cap--) : null,
                    ),
                    Text('$cap chỗ',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: cap < 50 ? () => setSt(() => cap++) : null,
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy')),
              FilledButton(
                onPressed: () {
                  for (final s in slots) {
                    store.setSlotCapacity(
                        doctor.id, dateStr, s.time, cap);
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Đã cập nhật tất cả slot về $cap chỗ.'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: _kSuccess,
                    ),
                  );
                },
                child: const Text('Áp dụng'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _weekday(DateTime value) =>
      const ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'][value.weekday % 7];
}

// ── Thẻ slot riêng lẻ ───────────────────────────────────────────────────────

class _SlotAdminCard extends StatelessWidget {
  const _SlotAdminCard({
    required this.slot,
    required this.onCapacityChanged,
  });

  final SlotConfig slot;
  final ValueChanged<int> onCapacityChanged;

  @override
  Widget build(BuildContext context) {
    final fillPercent =
        slot.capacity > 0 ? slot.booked / slot.capacity : 0.0;
    final isFull = slot.isFull;
    final isAlmost = !isFull && slot.remaining <= 2;

    final statusColor = isFull
        ? _kDanger
        : isAlmost
            ? _kWarning
            : _kSuccess;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                // Giờ
                Container(
                  width: 64,
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(slot.time,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: _kPrimary)),
                      Text(int.parse(slot.time.split(':')[0]) < 12 ? 'Sáng' : 'Chiều',
                          style: const TextStyle(
                              fontSize: 10, color: _kPrimary)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Thông tin + progress
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${slot.booked}/${slot.capacity} chỗ đã đặt',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isFull
                                  ? 'Hết chỗ'
                                  : isAlmost
                                      ? 'Sắp đầy'
                                      : 'Còn ${slot.remaining}',
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fillPercent.clamp(0.0, 1.0),
                          minHeight: 7,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              statusColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Điều chỉnh capacity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Giới hạn chỗ:',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade600),
                ),
                Row(
                  children: [
                    _CapBtn(
                      icon: Icons.remove,
                      onTap: slot.capacity > slot.booked
                          ? () => onCapacityChanged(slot.capacity - 1)
                          : null,
                    ),
                    Container(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${slot.capacity}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                    _CapBtn(
                      icon: Icons.add,
                      onTap: slot.capacity < 50
                          ? () => onCapacityChanged(slot.capacity + 1)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CapBtn extends StatelessWidget {
  const _CapBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: enabled
              ? _kPrimary.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled
                ? _kPrimary.withValues(alpha: 0.3)
                : Colors.grey.shade300,
          ),
        ),
        child: Icon(icon,
            size: 18,
            color: enabled ? _kPrimary : Colors.grey.shade400),
      ),
    );
  }
}

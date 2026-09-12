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
    if (!_authenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin & Bác sĩ — Đăng nhập'),
          backgroundColor: const Color(0xFF0D2657),
          foregroundColor: Colors.white,
        ),
        body: _buildLoginScreen(),
      );
    }

    final store = MedicalScope.of(context);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cổng Quản trị MedCare Hospital',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              Text('Phân hệ Quản trị viện phí, Bác sĩ & Giám sát An ninh',
                  style: TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
          backgroundColor: const Color(0xFF0D2657),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(icon: Icon(Icons.event_seat, size: 18), text: 'Quản lý Slot'),
              Tab(icon: Icon(Icons.medical_services, size: 18), text: 'Bàn Bác sĩ'),
              Tab(icon: Icon(Icons.insights, size: 18), text: 'Doanh thu & KPI'),
              Tab(icon: Icon(Icons.shield, size: 18), text: 'Giám sát An ninh'),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                avatar: const Icon(Icons.admin_panel_settings,
                    size: 16, color: Colors.white),
                label: const Text('Admin & Doctor',
                    style: TextStyle(color: Colors.white, fontSize: 11)),
                backgroundColor: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildSlotPanel(),
            _buildDoctorWorkspace(),
            _buildHospitalKpiDashboard(),
            _buildSecurityAuditPanel(store),
          ],
        ),
      ),
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

  // ── Tab 1: Cấu hình Slot Panel ───────────────────────────────────────────

  Widget _buildSlotPanel() {
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

  // ── Tab 2: Bàn làm việc Bác sĩ (Doctor Clinic Workspace) ──────────────────

  Widget _buildDoctorWorkspace() {
    final store = MedicalScope.of(context);
    final queue = store.queueInfo;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Clinic room status
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D2657),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.meeting_room_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '${queue.room} • ${queue.department}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Bác sĩ phụ trách: ${queue.doctorName}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Current Active Patient
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('BỆNH NHÂN ĐANG KHÁM TRONG PHÒNG',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _kPrimary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _kSuccess.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Đang thăm khám',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _kSuccess)),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: _kPrimary.withValues(alpha: 0.1),
                      child: Text(
                        '#${queue.currentNumber}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: _kPrimary, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bệnh nhân: Nguyễn Hoàng Vũ',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('Mã BN: MC-89241 • Nam • 24 tuổi • BHYT: Đúng tuyến (80%)',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Text(
                    'Lý do khám: Đau quặn thượng vị sau ăn 2 tuần, kèm ợ chua nhiều. Nghi ngờ viêm loét dạ dày tá tràng Hp (+).',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          store.doctorFinishConsultation(queue.doctorName, queue.department);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã hoàn tất ca khám, tự động tạo lịch hẹn tái khám sau 14 ngày & gửi phiếu khảo sát đánh giá!'),
                              backgroundColor: _kSuccess,
                            ),
                          );
                        },
                        icon: const Icon(Icons.assignment_turned_in_outlined, size: 16),
                        label: const Text('Khám xong / Kê đơn', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          store.doctorCallNextPatient(queue.room);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Loa phát thanh & chuông gọi số đã gọi bệnh nhân số #${queue.currentNumber + 1}!'),
                              backgroundColor: _kSuccess,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.campaign_rounded, size: 18),
                        label: const Text('Gọi số kế tiếp', style: TextStyle(fontSize: 12)),
                        style: FilledButton.styleFrom(backgroundColor: _kPrimary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Waiting Queue List
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('HÀNG ĐỢI ĐANG CHỜ TẠI SẢNH',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _kPrimary)),
            Text('Còn ${queue.waitCount} người chờ', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 10),

        ...List.generate(3, (i) {
          final patientNum = queue.currentNumber + i + 1;
          final names = ['Trần Văn Hưng', 'Lê Thị Thu Thảo', 'Hoàng Minh Quân'];
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                child: Text('#$patientNum',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
              ),
              title: Text(names[i % names.length], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text('Thời gian chờ dự kiến: ${(i + 1) * 6} phút', style: const TextStyle(fontSize: 11)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Chờ khám', style: TextStyle(fontSize: 10, color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Tab 3: Báo cáo Doanh thu & Thống kê KPI Bệnh viện ─────────────────────

  Widget _buildHospitalKpiDashboard() {
    final store = MedicalScope.of(context);
    final kpi = store.hospitalKpi;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // KPI Summary Cards
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                title: 'Tổng lượt khám hôm nay',
                value: '${kpi.todayPatients}',
                sub: '+12% so với hôm qua',
                icon: Icons.people_alt_outlined,
                color: const Color(0xFF0057CD),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _kpiCard(
                title: 'Doanh thu viện phí',
                value: '184.5 tr',
                sub: 'Đạt 94% chỉ tiêu ngày',
                icon: Icons.payments_outlined,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                title: 'Thời gian chờ TB',
                value: '${kpi.avgWaitMinutes} phút',
                sub: 'Chuẩn Bộ Y Tế: <30p',
                icon: Icons.timer_outlined,
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _kpiCard(
                title: 'Công suất phòng khám',
                value: '${kpi.occupancyRatePercent}%',
                sub: '${kpi.totalDoctorsOnDuty} bác sĩ đang trực',
                icon: Icons.local_hospital_outlined,
                color: const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Revenue Breakdown Chart Simulation
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cơ cấu Doanh thu Viện phí theo Khoa',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Tỷ lệ BHYT & Thu ngoài danh mục', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 14),

                _departmentBar('Khoa Tim mạch', 0.85, '52.4 triệu', const Color(0xFF0057CD)),
                _departmentBar('Khoa Tiêu hóa & Nội soi', 0.72, '44.8 triệu', const Color(0xFF10B981)),
                _departmentBar('Khoa Xét nghiệm & Sinh hóa', 0.65, '38.2 triệu', const Color(0xFFF59E0B)),
                _departmentBar('Khoa CĐHA (X-Quang/MRI)', 0.54, '31.6 triệu', const Color(0xFF8B5CF6)),
                _departmentBar('Khoa Dược Bệnh viện', 0.42, '17.5 triệu', const Color(0xFFEC4899)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // NPS & Doctor Reviews Card
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Khảo Sát Hài Lòng & NPS Bác Sĩ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text('${kpi.npsSatisfactionScore.toStringAsFixed(1)}% Hài lòng', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Dựa trên ${kpi.totalReviews} lượt đánh giá sau ca khám', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const Divider(height: 20),
                ...store.doctorReviews.take(3).map(
                  (rev) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 14,
                          backgroundColor: Color(0xFFFEF3C7),
                          child: Icon(Icons.star, size: 16, color: Colors.amber),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${rev.patientName} → ${rev.doctorName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(rev.comment, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                            ],
                          ),
                        ),
                        Text('${rev.rating}★', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: color)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _departmentBar(String name, double ratio, String amount, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text(amount, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 4: Giám sát An ninh & Nhật ký Truy vết (Security & Audit) ──────────

  Widget _buildSecurityAuditPanel(MedicalStore store) {
    final auditLogs = store.securityAuditLogs;
    final sessions = store.activeSessions;
    final isLockdown = store.isEmergencyLockdown;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Security Status Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isLockdown
                  ? [const Color(0xFFBA1A1A), const Color(0xFF7A0006)]
                  : [const Color(0xFF0F172A), const Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isLockdown ? Icons.warning_rounded : Icons.verified_user,
                        color: isLockdown ? Colors.amber : const Color(0xFF38BDF8),
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isLockdown ? 'CHẾ ĐỘ KHÓA KHẨN CẤP ĐANG BẬT' : 'TRUNG TÂM AN NINH & GIÁM SÁT HIS',
                        style: TextStyle(
                          color: isLockdown ? Colors.amber : const Color(0xFF38BDF8),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLockdown ? Colors.red.shade900 : const Color(0xFF064E3B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isLockdown ? 'DEFCON 1' : '100% SECURE',
                      style: TextStyle(
                        color: isLockdown ? Colors.amber : const Color(0xFF34D399),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                isLockdown
                    ? 'Toàn bộ quyền ghi dữ liệu bệnh án và đặt slot đã bị tạm khóa để ngăn ngừa thất thoát dữ liệu.'
                    : 'Hệ thống tuân thủ nghiêm ngặt HIPAA & Nghị định 13/2023/NĐ-CP về Bảo vệ Dữ liệu Cá nhân Y tế.',
                style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _securityTag('Mã hóa: AES-256 GCM'),
                  const SizedBox(width: 8),
                  _securityTag('TLS 1.3 End-to-End'),
                  const SizedBox(width: 8),
                  _securityTag('WAF: Active (0 breach)'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => store.toggleEmergencyLockdown(),
                  style: FilledButton.styleFrom(
                    backgroundColor: isLockdown ? Colors.white : const Color(0xFFEF4444),
                    foregroundColor: isLockdown ? Colors.red : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: Icon(isLockdown ? Icons.lock_open : Icons.lock),
                  label: Text(
                    isLockdown ? 'MỞ KHÓA HỆ THỐNG TRỞ LẠI' : 'KÍCH HOẠT KHÓA TOÀN BỘ KHẨN CẤP (LOCKDOWN)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Active Sessions Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'THIẾT BỊ & PHIÊN ĐĂNG NHẬP (ACTIVE SESSIONS)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D2657)),
            ),
            Text('${sessions.length} thiết bị trực tuyến', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 10),
        ...sessions.map((sess) => _buildSessionCard(store, sess)),
        const SizedBox(height: 20),

        // Real-time Audit Trail Logs
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'NHẬT KÝ TRUY VẾT THỜI GIAN THỰC (AUDIT TRAIL)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D2657)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
              child: const Text('Live Stream', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...auditLogs.map((log) => _buildAuditLogCard(log)),
      ],
    );
  }

  Widget _securityTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildSessionCard(MedicalStore store, ActiveSessionInfo sess) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: sess.isCurrent ? const Color(0xFFD2E4FF) : const Color(0xFFF1F5F9),
          child: Icon(
            sess.clientType.contains('Web')
                ? Icons.laptop
                : sess.clientType.contains('Tablet')
                    ? Icons.tablet_mac
                    : Icons.smartphone,
            color: sess.isCurrent ? const Color(0xFF0057CD) : Colors.grey,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(sess.deviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            if (sess.isCurrent) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(4)),
                child: const Text('Hiện tại', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue)),
              ),
            ],
          ],
        ),
        subtitle: Text('${sess.clientType} • IP: ${sess.ipAddress} • ${sess.lastActive}', style: const TextStyle(fontSize: 11)),
        trailing: sess.isCurrent
            ? null
            : TextButton(
                onPressed: () {
                  store.revokeSession(sess.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã ngắt kết nối phiên ${sess.deviceName}')),
                  );
                },
                child: const Text('Hủy phiên', style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
      ),
    );
  }

  Widget _buildAuditLogCard(SecurityAuditLog log) {
    final color = switch (log.severity) {
      SecuritySeverity.info => Colors.green,
      SecuritySeverity.warning => Colors.amber,
      SecuritySeverity.danger => Colors.red,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(log.action, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
                Text(
                  '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Thực hiện: ${log.actor} • IP: ${log.ipAddress}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 2),
            Text('Đối tượng: ${log.targetResource}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(log.statusDescription, style: TextStyle(fontSize: 11, color: color)),
            ),
          ],
        ),
      ),
    );
  }
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

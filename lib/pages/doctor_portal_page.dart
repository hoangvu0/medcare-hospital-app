import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../routes/app_routes.dart';
import '../state/medical_store.dart';

class DoctorPortalPage extends StatefulWidget {
  const DoctorPortalPage({super.key});

  @override
  State<DoctorPortalPage> createState() => _DoctorPortalPageState();
}

class _DoctorPortalPageState extends State<DoctorPortalPage> {
  final _diagnosisCtrl = TextEditingController(
    text: 'Tăng huyết áp nguyên phát độ 1 (I10) & Rối loạn lipid máu nhẹ',
  );
  final _adviceCtrl = TextEditingController(
    text: 'Ăn giảm mặn (< 5g muối/ngày), đo huyết áp mỗi sáng, tập thể dục nhẹ 30 phút.',
  );
  int _followUpDays = 14;

  final List<String> _selectedMedicines = [
    'Amlodipine 5mg (1 viên/ngày - Sáng sau ăn)',
    'Atorvastatin 10mg (1 viên/ngày - Tối trước ngủ)',
    'Panadol Extra 500mg (1 viên khi đau đầu nhẹ)',
  ];

  @override
  void dispose() {
    _diagnosisCtrl.dispose();
    _adviceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final doctor = store.activeDoctorUser;
    final queue = store.queueInfo;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bàn Làm Việc Bác Sĩ Lâm Sàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Cổng Tiếp Nhận & Điều Trị Bệnh Nhân', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF0F2B5C),
        foregroundColor: Colors.white,
        actions: [
          // Nút chuyển nhanh sang góc nhìn Bệnh nhân
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: () {
                store.switchRole(UserRole.patient);
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
              },
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: const Text('Góc nhìn BN'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00A3FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── HƯỚNG DẪN TEST TƯƠNG TÁC 2 CHIỀU ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: const Color(0xFF0284C7).withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.sync_alt_rounded, color: Color(0xFF0284C7), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ĐANG Ở CHẾ ĐỘ BÁC SĨ (INTERACTIVE MODE)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Thao tác gọi số, kê đơn, hẹn tái khám dưới đây sẽ phản hồi THỜI GIAN THỰC sang tài khoản Bệnh nhân!',
                        style: TextStyle(fontSize: 12, color: Colors.white, height: 1.3),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () {
                          store.switchRole(UserRole.patient);
                          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
                        },
                        child: const Row(
                          children: [
                            Text(
                              '👉 Chạm đây để đổi sang Bệnh nhân kiểm tra kết quả',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, decoration: TextDecoration.underline),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── CARD 1: THÔNG TIN BÁC SĨ ĐANG TRỰC ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF93C5FD)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.medical_services_rounded, color: Color(0xFF0057CD), size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctor.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('${doctor.specialty} • ${doctor.location}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                            child: const Text('🟢 Đang mở phòng khám', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Text('Đã khám: ${store.hospitalKpi.completedConsultations} ca', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── CARD 2: GỌI BỆNH NHÂN VÀO PHÒNG KHÁM ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1. ĐIỀU PHỐI HÀNG ĐỢI KHÁM BỆNH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0057CD))),
                    Icon(Icons.record_voice_over_rounded, color: Color(0xFF0057CD), size: 20),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF93C5FD)),
                      ),
                      child: Column(
                        children: [
                          const Text('STT ĐANG GỌI', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text(
                            '#${queue.currentNumber}',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0057CD)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bệnh nhân kế tiếp đang chờ:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const Text('Nguyễn Hoàng Vũ (Nam • 24 tuổi)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          Text('Mã lượt: ${queue.ticketCode} • Huyết áp: 135/85 mmHg', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      store.doctorCallNextPatient('Phòng 402');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📢 Đã phát loa chuông gọi số A-15 vào Phòng 402! Bệnh nhân đã nhận được thông báo.'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                    icon: const Icon(Icons.campaign_rounded),
                    label: const Text('BẤM CHUÔNG GỌI SỐ TIẾP THEO (A-15)', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0057CD),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── CARD 3: KHÁM & KÊ ĐƠN THUỐC ĐIỆN TỬ ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('2. CHẨN ĐOÁN & KÊ ĐƠN ĐIỆN TỬ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0057CD))),
                    Icon(Icons.medication_rounded, color: Color(0xFF0057CD), size: 20),
                  ],
                ),
                const Divider(height: 20),
                const Text('Chẩn đoán bệnh học lâm sàng:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _diagnosisCtrl,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Danh mục thuốc chỉ định cho bệnh nhân:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                ..._selectedMedicines.map((m) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(m, style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
                const Text('Lời dặn của bác sĩ:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _adviceCtrl,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      store.doctorPrescribeMedication(
                        patientName: 'Nguyễn Hoàng Vũ',
                        diagnosis: _diagnosisCtrl.text.trim(),
                        medicines: _selectedMedicines,
                        advice: _adviceCtrl.text.trim(),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('💊 Đã kê đơn thuốc điện tử! Đơn thuốc đã được đẩy sang tài khoản Bệnh nhân.'),
                          backgroundColor: Colors.teal,
                        ),
                      );
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('LƯU & ĐẨY ĐƠN THUỐC SANG BỆNH NHÂN', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: const BorderSide(color: Colors.teal),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── CARD 4: HOÀN TẤT KHÁM & HẸN TÁI KHÁM ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('3. HOÀN TẤT CA KHÁM & TÁI KHÁM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0057CD))),
                    Icon(Icons.event_repeat_rounded, color: Color(0xFF0057CD), size: 20),
                  ],
                ),
                const Divider(height: 20),
                const Text('Chỉ định thời gian tái khám định kỳ:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [7, 14, 30].map((days) {
                    final selected = _followUpDays == days;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('Sau $days ngày'),
                        selected: selected,
                        onSelected: (val) => setState(() => _followUpDays = days),
                        selectedColor: const Color(0xFF0057CD),
                        labelStyle: TextStyle(color: selected ? Colors.white : null, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      store.doctorFinishConsultation(doctor.name, doctor.specialty);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ Đã hoàn tất ca khám! Đã tự động tạo lịch tái khám sau $_followUpDays ngày & gửi phiếu đánh giá NPS cho bệnh nhân.'),
                          backgroundColor: Colors.green.shade700,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('KẾT THÚC KHÁM & TỰ ĐỘNG HẸN TÁI KHÁM', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00875A),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── CARD 5: KHÁM TỪ XA TELEMEDICINE ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.amber.shade100,
                  child: Icon(Icons.video_call_rounded, color: Colors.amber.shade900, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Khám từ xa Telemedicine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      const Text('Mở phòng gọi video HD trực tuyến để tư vấn bệnh nhân từ xa.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.telemedicine),
                  child: const Text('Vào phòng'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

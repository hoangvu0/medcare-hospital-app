import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../routes/app_routes.dart';
import '../state/medical_store.dart';

class DoctorPortalPage extends StatefulWidget {
  const DoctorPortalPage({super.key});

  @override
  State<DoctorPortalPage> createState() => _DoctorPortalPageState();
}

class _DoctorPortalPageState extends State<DoctorPortalPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers cho phân hệ chẩn đoán & kê đơn
  final _diagnosisCtrl = TextEditingController(
    text: 'Tăng huyết áp nguyên phát độ 1 (I10) & Rối loạn lipid máu nhẹ',
  );
  final _icd10CodeCtrl = TextEditingController(text: 'I10');
  final _icd10NameCtrl = TextEditingController(text: 'Tăng huyết áp vô căn (nguyên phát)');
  final _diffDiagnosisCtrl = TextEditingController(text: 'Theo dõi cơn thiếu máu não cục bộ thoáng qua (TIA)');
  final _physicalExamCtrl = TextEditingController(
    text: 'Tim đều T1, T2 rõ, tần số 78ck/p. Phổi không rale, rì rào phế nang êm dịu. Bụng mềm, gan lách không sờ thấy.',
  );
  final _adviceCtrl = TextEditingController(
    text: 'Ăn giảm mặn (< 5g muối/ngày), đo huyết áp mỗi sáng, không hút thuốc lá, tập thể dục nhẹ 30 phút.',
  );
  final _labSummaryCtrl = TextEditingController(
    text: 'Glucose đói: 5.6 mmol/L, Creatinine: 82 µmol/L (eGFR = 95 mL/phút), ECG: Nhịp xoang đều.',
  );

  // Vitals form
  final _bpSysCtrl = TextEditingController(text: '135');
  final _bpDiaCtrl = TextEditingController(text: '85');
  final _hrCtrl = TextEditingController(text: '76');
  final _spo2Ctrl = TextEditingController(text: '99');
  final _tempCtrl = TextEditingController(text: '36.8');
  final _weightCtrl = TextEditingController(text: '68.5');

  // New med form
  final _medNameCtrl = TextEditingController(text: 'Amlodipine');
  final _medDosageCtrl = TextEditingController(text: '5mg');
  final _medQuantityCtrl = TextEditingController(text: '30 viên');
  final _medInstructionCtrl = TextEditingController(text: 'Uống 1 viên vào mỗi buổi sáng sau khi ăn');

  final int _followUpDays = 14;
  final String _selectedRiskLevel = 'Theo dõi định kỳ';

  final List<MedicineItem> _consultationMedicines = [
    const MedicineItem(
      name: 'Amlodipine',
      category: 'Hạ huyết áp',
      dosage: '5mg',
      quantity: '30 viên',
      instruction: 'Uống 1 viên vào mỗi sáng sau khi ăn',
      warning: 'Không tự ý ngừng thuốc đột ngột',
    ),
    const MedicineItem(
      name: 'Atorvastatin',
      category: 'Hạ mỡ máu',
      dosage: '10mg',
      quantity: '30 viên',
      instruction: 'Uống 1 viên vào mỗi tối trước khi đi ngủ',
      warning: 'Tránh ăn bưởi chùm khi dùng thuốc',
    ),
    const MedicineItem(
      name: 'Panadol Extra',
      category: 'Giảm đau hạ sốt',
      dosage: '500mg',
      quantity: '10 viên',
      instruction: 'Uống 1 viên khi có đau đầu nhẹ (cách ít nhất 6 tiếng)',
      warning: 'Không uống quá 4 viên/ngày',
    ),
  ];

  // Giữ lại list string cho compatibility với widget test cũ
  List<String> get _selectedMedicines =>
      _consultationMedicines.map((m) => '${m.name} ${m.dosage} (${m.instruction})').toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _diagnosisCtrl.dispose();
    _icd10CodeCtrl.dispose();
    _icd10NameCtrl.dispose();
    _diffDiagnosisCtrl.dispose();
    _physicalExamCtrl.dispose();
    _adviceCtrl.dispose();
    _labSummaryCtrl.dispose();
    _bpSysCtrl.dispose();
    _bpDiaCtrl.dispose();
    _hrCtrl.dispose();
    _spo2Ctrl.dispose();
    _tempCtrl.dispose();
    _weightCtrl.dispose();
    _medNameCtrl.dispose();
    _medDosageCtrl.dispose();
    _medQuantityCtrl.dispose();
    _medInstructionCtrl.dispose();
    super.dispose();
  }

  void _showSnack(BuildContext context, String message, {Color color = Colors.green}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trạm Lâm Sàng Bác Sĩ (EMR Workstation)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${doctor.name} • ${doctor.specialty} • 32 Chức Năng Lâm Sàng',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F2B5C),
        foregroundColor: Colors.white,
        actions: [
          // Nút chuyển nhanh sang góc nhìn Bệnh nhân để kiểm tra đồng bộ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton.icon(
              onPressed: () {
                store.switchRole(UserRole.patient);
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
              },
              icon: const Icon(Icons.sync_alt_rounded, color: Color(0xFF38BDF8), size: 16),
              label: const Text('Góc nhìn BN', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          // Nút Đăng xuất độc lập cho Bác sĩ
          IconButton(
            tooltip: 'Đăng xuất tài khoản Bác sĩ',
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () {
              store.logout();
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF38BDF8),
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFF38BDF8),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.people_alt_outlined, size: 18), text: '1. Tiếp Nhận & Vitals'),
            Tab(icon: Icon(Icons.menu_book_outlined, size: 18), text: '2. Khám & ICD-10'),
            Tab(icon: Icon(Icons.biotech_outlined, size: 18), text: '3. Cận Lâm Sàng & Phim'),
            Tab(icon: Icon(Icons.medication_outlined, size: 18), text: '4. Đơn Thuốc & Dược'),
            Tab(icon: Icon(Icons.verified_outlined, size: 18), text: '5. Ký Số & Đồng Bộ EMR'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTab1ReceptionAndVitals(context, store, queue, isDark),
          _buildTab2ClinicalAndIcd10(context, store, isDark),
          _buildTab3LabsAndImaging(context, store, isDark),
          _buildTab4EPrescription(context, store, isDark),
          _buildTab5SignAndFullSync(context, store, doctor, isDark),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 1: TIẾP NHẬN & TIỀN LÂM SÀNG (CHỨC NĂNG 1 - 6)
  // ============================================================================
  Widget _buildTab1ReceptionAndVitals(BuildContext context, MedicalStore store, LiveQueueInfo queue, bool isDark) {
    final patient = store.profile;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSyncNoticeBanner('Phân hệ Tiếp nhận: Điều phối số thứ tự và sinh hiệu gửi thông báo đẩy trực tiếp tới ứng dụng bệnh nhân.'),
        const SizedBox(height: 14),

        // 1. GỌI BỆNH NHÂN THEO SỐ THỨ TỰ (Chức năng 1)
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.campaign_rounded, color: Color(0xFF0057CD)),
                    SizedBox(width: 8),
                    Text('1. ĐIỀU PHỐI HÀNG ĐỢI & GỌI SỐ (QUEUE DISPATCH)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0057CD))),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF93C5FD)),
                      ),
                      child: Column(
                        children: [
                          const Text('ĐANG GỌI', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text('#${queue.currentNumber}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0057CD))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bệnh nhân vào khám: ${patient.name}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          Text('Phòng: ${queue.room} • Mã lượt: ${queue.ticketCode}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text('Thời gian chờ ước tính: ~${queue.estimatedMinutes} phút', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
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
                      _showSnack(context, '📢 Đã phát loa mời bệnh nhân số #${queue.currentNumber + 1} vào Phòng 402!');
                    },
                    icon: const Icon(Icons.campaign_rounded),
                    label: Text('GỌI SỐ KẾ TIẾP (#${queue.currentNumber + 1}) VÀO PHÒNG 402', style: const TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0057CD), padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2. GHI NHẬN SINH HIỆU TẠI TRẠM (Chức năng 2)
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.monitor_heart_rounded, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('2. ĐO VÀ ĐỒNG BỘ SINH HIỆU (VITALS DIRECT SYNC)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildMiniInput('Huyết áp Tâm thu', _bpSysCtrl, 'mmHg')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMiniInput('Huyết áp Tâm trương', _bpDiaCtrl, 'mmHg')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMiniInput('Nhịp tim', _hrCtrl, 'bpm')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildMiniInput('SpO2', _spo2Ctrl, '%')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMiniInput('Nhiệt độ', _tempCtrl, '°C')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMiniInput('Cân nặng', _weightCtrl, 'kg')),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final sys = double.tryParse(_bpSysCtrl.text) ?? 120;
                      final dia = double.tryParse(_bpDiaCtrl.text) ?? 80;
                      final hr = int.tryParse(_hrCtrl.text) ?? 75;
                      final spo2 = double.tryParse(_spo2Ctrl.text) ?? 98;
                      final temp = double.tryParse(_tempCtrl.text) ?? 36.8;
                      final weight = double.tryParse(_weightCtrl.text) ?? 68.0;
                      store.doctorRecordVitals(
                        bpSys: sys,
                        bpDia: dia,
                        heartRate: hr,
                        spo2: spo2,
                        temp: temp,
                        weight: weight,
                      );
                      _showSnack(context, '🩺 Đã truyền dữ liệu sinh hiệu sang Biểu đồ Sức khỏe của Bệnh nhân!');
                    },
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text('LƯU & TRUYỀN SINH HIỆU SANG APP BỆNH NHÂN', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 3 - 6. BỆNH SỬ, TRIAGE, BUỒNG KHÁM & SINH TRẮC HỌC
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TIỆN ÍCH TIỀN LÂM SÀNG MỞ RỘNG (CHỨC NĂNG 3 - 6):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        store.doctorReviewHistory();
                        _showSnack(context, '📋 Đã đối soát tiền sử dị ứng (${patient.allergies}) & ghi nhận audit log!');
                      },
                      icon: const Icon(Icons.history_edu_rounded, size: 16),
                      label: const Text('3. Xem Bệnh sử & Dị ứng'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        store.doctorUpdateTriageRisk('Mức độ 2: Cần theo dõi sát');
                        _showSnack(context, '⚠️ Đã cập nhật Triage: Cần theo dõi sát tim mạch.');
                      },
                      icon: const Icon(Icons.crisis_alert_rounded, size: 16),
                      label: const Text('4. Phân tầng Nguy cơ (Triage)'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        store.doctorAssignRoom('Phòng 204 - Điện cơ & Siêu âm');
                        _showSnack(context, '📍 Đã điều hướng bệnh nhân về Phòng 204 làm thăm dò chức năng.');
                      },
                      icon: const Icon(Icons.meeting_room_rounded, size: 16),
                      label: const Text('5. Điều hướng Buồng khám'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        store.doctorBiometricVerification();
                        _showSnack(context, '🛡️ Xác thực thẻ BHYT sinh trắc học ${patient.insuranceNumber} thành công!');
                      },
                      icon: const Icon(Icons.fingerprint_rounded, size: 16),
                      label: const Text('6. Xác thực Thẻ BHYT'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // TAB 2: KHÁM LÂM SÀNG & CHẨN ĐOÁN ICD-10 (CHỨC NĂNG 7 - 12)
  // ============================================================================
  Widget _buildTab2ClinicalAndIcd10(BuildContext context, MedicalStore store, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSyncNoticeBanner('Phân hệ Chẩn đoán: Nhập khám thực thể, chuẩn hóa mã ICD-10 và đánh giá điểm lâm sàng để truyền vào Hồ sơ Bệnh án.'),
        const SizedBox(height: 14),

        // 7. KHÁM THỰC THỂ CÁC CƠ QUAN (Chức năng 7)
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_hospital_outlined, color: Color(0xFF0057CD)),
                    SizedBox(width: 8),
                    Text('7. KHÁM THỰC THỂ CÁC CƠ QUAN (PHYSICAL EXAMINATION)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0057CD))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _physicalExamCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      store.doctorRecordPhysicalExam(_physicalExamCtrl.text.trim());
                      _showSnack(context, '✅ Đã lưu kết quả khám thực thể.');
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Lưu ghi nhận khám thực thể'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 8 & 9. MÃ ICD-10 CHÍNH THỨC & CHẨN ĐOÁN PHÂN BIỆT (Chức năng 8, 9)
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.format_list_numbered_rounded, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text('8 & 9. CHẨN ĐOÁN XÁC ĐỊNH ICD-10 & PHÂN BIỆT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(width: 100, child: _buildMiniInput('Mã ICD-10', _icd10CodeCtrl, '')),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMiniInput('Tên chẩn đoán ICD-10', _icd10NameCtrl, '')),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Chọn nhanh bệnh lý thường gặp:', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    ActionChip(label: const Text('I10 - Tăng huyết áp'), onPressed: () {
                      _icd10CodeCtrl.text = 'I10';
                      _icd10NameCtrl.text = 'Tăng huyết áp vô căn (nguyên phát)';
                      _diagnosisCtrl.text = 'Tăng huyết áp nguyên phát độ 1 (I10)';
                      setState(() {});
                    }),
                    ActionChip(label: const Text('E11.9 - Đái tháo đường Type 2'), onPressed: () {
                      _icd10CodeCtrl.text = 'E11.9';
                      _icd10NameCtrl.text = 'Đái tháo đường typ 2 không có biến chứng';
                      _diagnosisCtrl.text = 'Đái tháo đường typ 2 (E11.9)';
                      setState(() {});
                    }),
                    ActionChip(label: const Text('I20.9 - Cơn đau thắt ngực'), onPressed: () {
                      _icd10CodeCtrl.text = 'I20.9';
                      _icd10NameCtrl.text = 'Cơn đau thắt ngực không đặc hiệu';
                      _diagnosisCtrl.text = 'Thiếu máu cơ tim / Đau thắt ngực (I20.9)';
                      setState(() {});
                    }),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Chẩn đoán phân biệt chuyên sâu (Chức năng 9):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _diffDiagnosisCtrl,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 10 - 12: BỆNH KÈM THEO, THANG ĐIỂM & TÓM TẮT DIỄN TIẾN (Chức năng 10, 11, 12)
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ĐÁNH GIÁ CHUYÊN SÂU (CHỨC NĂNG 10, 11, 12):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.analytics_outlined, color: Color(0xFF0057CD))),
                  title: const Text('10. Đánh giá bệnh lý kèm theo (Comorbidities)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Đái tháo đường Type 2, Rối loạn chuyển hóa Lipid máu', style: TextStyle(fontSize: 12)),
                  trailing: TextButton(
                    onPressed: () {
                      store.doctorAssessComorbidities(['Đái tháo đường Type 2', 'Rối loạn lipid máu']);
                      _showSnack(context, 'Đã ghi nhận bệnh lý kèm theo vào bilan điều trị.');
                    },
                    child: const Text('Xác nhận'),
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(backgroundColor: Color(0xFFFEF3C7), child: Icon(Icons.calculate_outlined, color: Colors.amber)),
                  title: const Text('11. Thang điểm lâm sàng CHA2DS2-VASc', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Điểm số: 2 điểm (Nguy cơ huyết khối trung bình - cần chống đông)', style: TextStyle(fontSize: 12)),
                  trailing: TextButton(
                    onPressed: () {
                      store.doctorEvaluateClinicalScore('CHA2DS2-VASc', 2, 'Nguy cơ thuyên tắc mạch trung bình');
                      _showSnack(context, 'Đã lưu thang điểm lâm sàng vào EMR.');
                    },
                    child: const Text('Lưu điểm'),
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(backgroundColor: Color(0xFFF0FDF4), child: Icon(Icons.notes_rounded, color: Colors.green)),
                  title: const Text('12. Tóm tắt diễn tiến bệnh cảnh lâm sàng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Bệnh nhân đáp ứng tốt, huyết áp xu hướng giảm từ 150 -> 135 mmHg.', style: TextStyle(fontSize: 12)),
                  trailing: TextButton(
                    onPressed: () {
                      store.doctorRecordCourseSummary('Đáp ứng phác đồ điều trị ban đầu tốt');
                      _showSnack(context, 'Đã cập nhật tóm tắt diễn tiến.');
                    },
                    child: const Text('Cập nhật'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // TAB 3: CHỈ ĐỊNH CẬN LÂM SÀNG & CHẨN ĐOÁN HÌNH ẢNH (CHỨC NĂNG 13 - 20)
  // ============================================================================
  Widget _buildTab3LabsAndImaging(BuildContext context, MedicalStore store, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSyncNoticeBanner('Phân hệ Cận Lâm Sàng: Ra y lệnh xét nghiệm, chỉ định chẩn đoán hình ảnh và trả kết quả phim X-Quang/siêu âm thẳng về ứng dụng bệnh nhân.'),
        const SizedBox(height: 14),

        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.biotech, color: Colors.teal),
                    SizedBox(width: 8),
                    Text('CHỈ ĐỊNH XÉT NGHIỆM VÀ TRẢ KẾT QUẢ VỀ BỆNH NHÂN (13, 14, 15)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          store.doctorOrderCBC();
                          _showSnack(context, '🩸 Đã ra y lệnh & trả kết quả Tổng phân tích tế bào máu CBC về app Bệnh nhân!');
                        },
                        icon: const Icon(Icons.bloodtype_outlined, size: 16),
                        label: const Text('14. Chỉ định CBC (Máu)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          store.doctorOrderBloodBiochemistry();
                          _showSnack(context, '🧪 Đã chỉ định & cập nhật Sinh hóa máu (Glucose, Creatinine) vào hồ sơ!');
                        },
                        icon: const Icon(Icons.science_outlined, size: 16),
                        label: const Text('15. Sinh Hóa Máu'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      store.doctorOrderLabTest(
                        name: 'Điện giải đồ Na+/K+/Cl-',
                        value: 'Na: 138, K: 4.1, Cl: 102',
                        unit: 'mmol/L',
                        normalRange: '135 - 145 mmol/L',
                        isAbnormal: false,
                        note: 'Điện giải trong giới hạn bình thường',
                      );
                      _showSnack(context, '⚡ Đã thêm kết quả Điện giải đồ vào danh sách xét nghiệm của Bệnh nhân!');
                    },
                    icon: const Icon(Icons.add_task_rounded, size: 16),
                    label: const Text('13. Trả Kết Quả Xét Nghiệm Tự Do Sang Bệnh Nhân'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.image_search_rounded, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Text('CHẨN ĐOÁN HÌNH ẢNH & THĂM DÒ CHỨC NĂNG (16 - 20)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        store.doctorOrderChestXRay();
                        _showSnack(context, '🩻 Đã ra kết luận phim X-Quang Ngực Thẳng đẩy sang hồ sơ!');
                      },
                      icon: const Icon(Icons.camera_alt_outlined, size: 16),
                      label: const Text('16. X-Quang Phổi Thẳng'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        store.doctorOrderAbdominalUltrasound();
                        _showSnack(context, '📷 Đã gửi kết quả Siêu âm ổ bụng tổng quát sang app Bệnh nhân!');
                      },
                      icon: const Icon(Icons.waves_rounded, size: 16),
                      label: const Text('17. Siêu Âm Ổ Bụng'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        store.doctorOrderECG();
                        _showSnack(context, '📈 Đã ghi nhận kết quả Điện tim đồ ECG 12 chuyển đạo!');
                      },
                      icon: const Icon(Icons.show_chart_rounded, size: 16),
                      label: const Text('18. Điện Tâm Đồ ECG'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        store.doctorOrderEcho();
                        _showSnack(context, '❤️ Đã hoàn thành Siêu âm tim Doppler màu (EF = 65%)!');
                      },
                      icon: const Icon(Icons.favorite_rounded, size: 16),
                      label: const Text('19. Siêu Âm Tim Doppler'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      store.doctorPushImagingResult(
                        modality: 'Chụp CT Sọ Não 128 lát cắt',
                        findings: 'Không thấy hình ảnh ổ nhồi máu hay xuất huyết não nội sọ.',
                        imageUrl: 'https://images.unsplash.com/photo-1516549655169-df83a0774514?w=800',
                      );
                      _showSnack(context, '🖼️ Đã số hóa và lưu ảnh phim CT/X-Quang vào Hồ sơ EMR bệnh nhân!');
                    },
                    icon: const Icon(Icons.cloud_done_rounded, size: 16),
                    label: const Text('20. Đẩy Ảnh Phim Y Khoa Số Hóa Vào Hồ Sơ EMR'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // TAB 4: KÊ ĐƠN ĐIỆN TỬ & DƯỢC LÂM SÀNG (CHỨC NĂNG 21 - 26)
  // ============================================================================
  Widget _buildTab4EPrescription(BuildContext context, MedicalStore store, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSyncNoticeBanner('Phân hệ Đơn Thuốc: Kê đơn thuốc chuẩn quốc gia, kiểm tra tương tác thuốc, tự động sinh lịch uống thuốc kèm nhắc nhở cho bệnh nhân.'),
        const SizedBox(height: 14),

        // DANH MỤC THUỐC ĐÃ CHỈ ĐỊNH
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('DANH MỤC THUỐC KÊ ĐƠN (CHỨC NĂNG 21):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
                    Text('${_consultationMedicines.length} loại thuốc', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 16),
                ..._consultationMedicines.map((med) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 18, color: Colors.teal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${med.name} ${med.dosage} (${med.quantity})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('${med.instruction} • ${med.warning ?? "Đúng chỉ định"}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddMedicineDialog(context, store),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Thêm Thuốc Mới'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          store.doctorPrescribeMedication(
                            patientName: store.profile.name,
                            diagnosis: _diagnosisCtrl.text.trim(),
                            medicines: _selectedMedicines,
                            advice: _adviceCtrl.text.trim(),
                          );
                          _showSnack(context, '💊 Đã lưu đơn thuốc và đẩy sang app Bệnh nhân!');
                        },
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('Lưu Đơn Thuốc'),
                        style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // TIỆN ÍCH DƯỢC LÂM SÀNG (22 - 26)
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TIỆN ÍCH DƯỢC LÂM SÀNG & AN TOÀN DÙNG THUỐC (22 - 26):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        final res = store.doctorCheckDrugInteraction('Amlodipine', 'Atorvastatin');
                        _showSnack(context, '🔍 $res', color: Colors.teal);
                      },
                      icon: const Icon(Icons.sync_problem_rounded, size: 16),
                      label: const Text('22. Kiểm Tra Tương Tác Thuốc'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        final isAllergic = store.doctorCheckAllergyRisk('Penicillin');
                        _showSnack(
                          context,
                          isAllergic ? '⚠️ BỆNH NHÂN DỊ ỨNG PENICILLIN! Tuyệt đối không kê kháng sinh nhóm Beta-lactam.' : 'An toàn dị ứng.',
                          color: isAllergic ? Colors.redAccent : Colors.green,
                        );
                      },
                      icon: const Icon(Icons.warning_amber_rounded, size: 16),
                      label: const Text('23. Cảnh Báo Dị Ứng Bệnh Nhân'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        final doseInfo = store.doctorCalculateRenalDose(68.0, 95.0);
                        _showSnack(context, '📊 $doseInfo');
                      },
                      icon: const Icon(Icons.calculate_outlined, size: 16),
                      label: const Text('24. Tính Liều Theo Thận eGFR'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        store.doctorGenerateAutoSchedule(
                          medicineName: 'Amlodipine 5mg',
                          timeOfDay: '08:00',
                          dosage: '1 viên sau khi ăn sáng',
                        );
                        _showSnack(context, '⏰ Đã tự động tạo Lịch Uống Thuốc vào app Bệnh nhân kèm nhắc nhở!');
                      },
                      icon: const Icon(Icons.alarm_add_rounded, size: 16),
                      label: const Text('25. Lập Lịch Uống Thuốc Cho BN'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        store.doctorSubmitNationalPrescriptionPortal('DT-VN-2026-9921');
                        _showSnack(context, '🏛️ Đã đồng bộ đơn thuốc thành công lên Cổng Đơn Thuốc Quốc Gia Bộ Y Tế!');
                      },
                      icon: const Icon(Icons.send_and_archive_rounded, size: 16),
                      label: const Text('26. Đẩy Lên Cổng Đơn Thuốc QG'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // TAB 5: KÝ SỐ EMR & ĐỒNG BỘ TOÀN DIỆN SANG BỆNH NHÂN (CHỨC NĂNG 27 - 32)
  // ============================================================================
  Widget _buildTab5SignAndFullSync(BuildContext context, MedicalStore store, DoctorProfile doctor, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // BANNER SIÊU HÀNH ĐỘNG
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: const Color(0xFF0D9488).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ĐỒNG BỘ DỮ LIỆU KHÁM BỆNH VỀ TÀI KHOẢN BỆNH NHÂN',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Toàn bộ kết quả chẩn đoán ICD-10, sinh hiệu, đơn thuốc, lịch uống thuốc và lời dặn sẽ được đóng gói thành Hồ sơ Bệnh án Điện tử (EMR) có mã ký số bảo mật chuẩn SHA-256 và truyền ngay lập tức sang ứng dụng của bệnh nhân.',
                style: TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 14),
              // NÚT SIÊU HÀNH ĐỘNG SỐ 32
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () => _executeMasterSync(context, store, doctor),
                  icon: const Icon(Icons.flash_on_rounded, color: Colors.amberAccent),
                  label: const Text(
                    '🔥 32. KÝ SỐ EMR & TRUYỀN DỮ LIỆU ĐỒNG BỘ SANG BỆNH NHÂN',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.3),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF042F2E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // CÁC CHỨC NĂNG 27 - 31 RIÊNG LẺ
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('THAO TÁC LÂM SÀNG BỔ TRỢ (CHỨC NĂNG 27 - 31):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.fingerprint_rounded, color: Color(0xFF0057CD))),
                  title: const Text('27. Ký số EMR điện tử (Digital Signature SHA-256)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Tạo mã Hash bảo mật không thể giả mạo theo chuẩn y tế.', style: TextStyle(fontSize: 11)),
                  trailing: TextButton(
                    onPressed: () {
                      final token = store.doctorDigitalSignEmr(signer: doctor.name, certKey: 'CERT-VN-MEDCARE');
                      _showSnack(context, '🔏 Đã ký số bệnh án: $token');
                    },
                    child: const Text('Ký số EMR'),
                  ),
                ),
                const Divider(),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(backgroundColor: Color(0xFFFEF3C7), child: Icon(Icons.event_repeat_rounded, color: Colors.amber)),
                  title: const Text('28. Đặt lịch tái khám định kỳ (Follow-up Reminder)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text('Hẹn tái khám sau $_followUpDays ngày kèm thông báo tự động.', style: const TextStyle(fontSize: 11)),
                  trailing: TextButton(
                    onPressed: () {
                      final targetDate = DateTime.now().add(Duration(days: _followUpDays));
                      final dateStr = '${targetDate.day}/${targetDate.month}/${targetDate.year}';
                      store.doctorScheduleFollowUp(
                        date: dateStr,
                        notes: 'Tái khám đánh giá đáp ứng hạ áp và làm lại bilan lipid máu.',
                        doctorName: doctor.name,
                      );
                      _showSnack(context, '📅 Đã lên lịch hẹn tái khám ngày $dateStr cho bệnh nhân!');
                    },
                    child: const Text('Hẹn khám'),
                  ),
                ),
                const Divider(),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(backgroundColor: Color(0xFFF0FDF4), child: Icon(Icons.groups_rounded, color: Colors.green)),
                  title: const Text('29. Yêu cầu hội chẩn chuyên khoa (Consultation)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Gửi hồ sơ hội chẩn liên chuyên khoa Tim Mạch - Nội Tiết.', style: TextStyle(fontSize: 11)),
                  trailing: TextButton(
                    onPressed: () {
                      store.doctorRequestSpecialtyConsultation('Nội tiết & Chuyển hóa', 'Kiểm soát đường huyết phối hợp');
                      _showSnack(context, '🤝 Đã gửi phiếu yêu cầu hội chẩn chuyên khoa!');
                    },
                    child: const Text('Hội chẩn'),
                  ),
                ),
                const Divider(),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(backgroundColor: Color(0xFFFEE2E2), child: Icon(Icons.local_hospital_rounded, color: Colors.redAccent)),
                  title: const Text('30. Ra y lệnh điều trị (Hospitalization Order)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Cho về điều trị ngoại trú theo đơn thuốc hướng dẫn.', style: TextStyle(fontSize: 11)),
                  trailing: TextButton(
                    onPressed: () {
                      store.doctorIssueHospitalizationOrder(false, 'Cho về điều trị ngoại trú, theo dõi huyết áp hàng ngày tại nhà.');
                      _showSnack(context, '📝 Đã ban hành y lệnh điều trị ngoại trú.');
                    },
                    child: const Text('Ra y lệnh'),
                  ),
                ),
                const Divider(),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(backgroundColor: Color(0xFFFAF5FF), child: Icon(Icons.chat_bubble_outline_rounded, color: Colors.purple)),
                  title: const Text('31. Gửi lời dặn dò y khoa trực tiếp', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Đẩy lời dặn của Bác sĩ vào chuông thông báo điện thoại bệnh nhân.', style: TextStyle(fontSize: 11)),
                  trailing: TextButton(
                    onPressed: () {
                      store.doctorSendDirectAdvice(_adviceCtrl.text.trim());
                      _showSnack(context, '💬 Đã gửi lời dặn dò trực tiếp đến bệnh nhân!');
                    },
                    child: const Text('Gửi lời dặn'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // HÀM THỰC THI SIÊU ĐỒNG BỘ LÂM SÀNG (CHỨC NĂNG 32)
  // ============================================================================
  void _executeMasterSync(BuildContext context, MedicalStore store, DoctorProfile doctor) {
    final targetDate = DateTime.now().add(Duration(days: _followUpDays));
    final dateStr = '${targetDate.day.toString().padLeft(2, '0')}/${targetDate.month.toString().padLeft(2, '0')}/${targetDate.year}';

    store.doctorExecuteFullConsultationSync(
      diagnosis: _diagnosisCtrl.text.trim(),
      icd10Code: _icd10CodeCtrl.text.trim(),
      icd10Name: _icd10NameCtrl.text.trim(),
      symptoms: 'Đau đầu âm ỉ vùng chẩm, hoa mắt nhẹ khi thay đổi tư thế, hồi hộp trống ngực.',
      physicalExam: _physicalExamCtrl.text.trim(),
      labNotes: _labSummaryCtrl.text.trim(),
      doctorAdvice: _adviceCtrl.text.trim(),
      followUpDate: dateStr,
      prescribedMedicines: _consultationMedicines,
      riskLevel: _selectedRiskLevel,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Expanded(child: Text('Đồng Bộ Dữ Liệu Thành Công!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Toàn bộ dữ liệu khám bệnh đã được ký số và truyền trực tiếp về tài khoản Bệnh nhân:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            _buildCheckItem('Hồ sơ bệnh án điện tử (EMR) chuẩn ICD-10 (${_icd10CodeCtrl.text})'),
            _buildCheckItem('Đơn thuốc điện tử (${_consultationMedicines.length} loại thuốc)'),
            _buildCheckItem('Lịch nhắc uống thuốc buổi sáng/tối tự động'),
            _buildCheckItem('Chữ ký số SHA-256 xác thực bác sĩ'),
            _buildCheckItem('Lộ trình khám đã tự động hoàn thành các bước'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ở lại Trạm Bác sĩ'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              store.switchRole(UserRole.patient);
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.records, (_) => false);
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('Xem Hồ Sơ Bệnh Nhân Ngay'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0057CD)),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.teal, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildSyncNoticeBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0284C7).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sensors_rounded, color: Color(0xFF0284C7), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Color(0xFF0369A1), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniInput(String label, TextEditingController ctrl, String suffix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(
            isDense: true,
            suffixText: suffix.isNotEmpty ? suffix : null,
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ],
    );
  }

  void _showAddMedicineDialog(BuildContext context, MedicalStore store) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm Thuốc Chỉ Định', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _medNameCtrl, decoration: const InputDecoration(labelText: 'Tên thuốc (Biệt dược/Hoạt chất)')),
            TextField(controller: _medDosageCtrl, decoration: const InputDecoration(labelText: 'Hàm lượng (ví dụ: 10mg, 500mg)')),
            TextField(controller: _medQuantityCtrl, decoration: const InputDecoration(labelText: 'Số lượng (ví dụ: 30 viên, 1 chai)')),
            TextField(controller: _medInstructionCtrl, decoration: const InputDecoration(labelText: 'Hướng dẫn uống')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              final newMed = MedicineItem(
                name: _medNameCtrl.text.trim(),
                category: 'Thuốc điều trị',
                dosage: _medDosageCtrl.text.trim(),
                quantity: _medQuantityCtrl.text.trim(),
                instruction: _medInstructionCtrl.text.trim(),
              );
              setState(() => _consultationMedicines.add(newMed));
              store.doctorPrescribeMedicine(
                name: newMed.name,
                category: newMed.category,
                dosage: newMed.dosage,
                instruction: newMed.instruction,
                quantity: newMed.quantity,
              );
              Navigator.pop(ctx);
              _showSnack(context, 'Đã thêm ${newMed.name} vào đơn thuốc!');
            },
            child: const Text('Thêm vào đơn'),
          ),
        ],
      ),
    );
  }
}



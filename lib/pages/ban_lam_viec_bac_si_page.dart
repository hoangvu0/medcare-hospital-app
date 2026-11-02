// Dialog forms are opened from the active doctor workstation; callbacks stay
// on this mounted State while the modal is visible.
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../routes/app_routes.dart';
import '../state/medical_store.dart';

class DoctorPortalPage extends StatefulWidget {
  const DoctorPortalPage({super.key});

  @override
  State<DoctorPortalPage> createState() => _DoctorPortalPageState();
}

class _DoctorPortalPageState extends State<DoctorPortalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MedicalStore? _queueStore;

  // Controllers cho phân hệ chẩn đoán & kê đơn
  final _diagnosisCtrl = TextEditingController();
  final _icd10CodeCtrl = TextEditingController();
  final _icd10NameCtrl = TextEditingController();
  final _symptomsCtrl = TextEditingController();
  final _diffDiagnosisCtrl = TextEditingController();
  final _physicalExamCtrl = TextEditingController();
  final _adviceCtrl = TextEditingController();
  final _labSummaryCtrl = TextEditingController();

  // Vitals form
  final _bpSysCtrl = TextEditingController();
  final _bpDiaCtrl = TextEditingController();
  final _hrCtrl = TextEditingController();
  final _spo2Ctrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _glucoseCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  // New med form
  final _medNameCtrl = TextEditingController();
  final _medDosageCtrl = TextEditingController();
  final _medQuantityCtrl = TextEditingController();
  final _medInstructionCtrl = TextEditingController();
  final _medPriceCtrl = TextEditingController();
  final _specialtyField1Ctrl = TextEditingController();
  final _specialtyField2Ctrl = TextEditingController();
  final _specialtyField3Ctrl = TextEditingController();

  final int _followUpDays = 14;
  final String _selectedRiskLevel = 'Theo dõi định kỳ';

  final List<MedicineItem> _consultationMedicines = [];

  String _formatCurrency(int value) {
    final text = value.toString();
    final groups = <String>[];
    for (var end = text.length; end > 0; end -= 3) {
      final start = (end - 3).clamp(0, end);
      groups.insert(0, text.substring(start, end));
    }
    return '${groups.join('.')}đ';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final store = MedicalScope.of(context);
      _queueStore = store;
      if (!store.isDoctorRole || !store.hasBackendSession) return;
      try {
        await store.refreshAppointmentsFromBackend();
        await store.refreshQueueTicketsFromBackend();
        await store.connectQueueRealtime();
      } catch (_) {
        // The screen remains usable, but clinical writes require a real
        // appointment selected from the backend.
      }
    });
  }

  @override
  void dispose() {
    _queueStore?.disconnectQueueRealtime();
    _tabController.dispose();
    _diagnosisCtrl.dispose();
    _icd10CodeCtrl.dispose();
    _icd10NameCtrl.dispose();
    _symptomsCtrl.dispose();
    _diffDiagnosisCtrl.dispose();
    _physicalExamCtrl.dispose();
    _adviceCtrl.dispose();
    _labSummaryCtrl.dispose();
    _medPriceCtrl.dispose();
    _bpSysCtrl.dispose();
    _bpDiaCtrl.dispose();
    _hrCtrl.dispose();
    _spo2Ctrl.dispose();
    _tempCtrl.dispose();
    _weightCtrl.dispose();
    _glucoseCtrl.dispose();
    _heightCtrl.dispose();
    _medNameCtrl.dispose();
    _medDosageCtrl.dispose();
    _medQuantityCtrl.dispose();
    _medInstructionCtrl.dispose();
    _specialtyField1Ctrl.dispose();
    _specialtyField2Ctrl.dispose();
    _specialtyField3Ctrl.dispose();
    super.dispose();
  }

  void _showSnack(
    BuildContext context,
    String message, {
    Color color = Colors.green,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<Map<String, String>?> _showDetailForm(
    BuildContext context, {
    required String title,
    required List<String> fields,
    Map<String, String> initial = const {},
  }) async {
    final controllers = <String, TextEditingController>{
      for (final field in fields)
        field: TextEditingController(text: initial[field] ?? ''),
    };
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < fields.length; index++) ...[
                  TextField(
                    controller: controllers[fields[index]],
                    minLines:
                        fields[index].toLowerCase().contains('ghi chú') ||
                            fields[index].toLowerCase().contains('lý do') ||
                            fields[index].toLowerCase().contains('mô tả')
                        ? 3
                        : 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: fields[index],
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (index < fields.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            onPressed: () {
              final values = <String, String>{
                for (final field in fields)
                  field: controllers[field]!.text.trim(),
              };
              if (values.values.any((value) => value.isEmpty)) return;
              Navigator.pop(dialogContext, values);
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Lưu phiếu'),
          ),
        ],
      ),
    );
    for (final controller in controllers.values) {
      controller.dispose();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final doctor = store.activeDoctorUser;
    final queue = store.queueInfo;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B1120)
          : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trạm lâm sàng (EMR Workstation)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${doctor.name} • ${doctor.specialty}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F2B5C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Đổi sang tài khoản bệnh nhân',
            icon: const Icon(
              Icons.personal_injury_outlined,
              color: Color(0xFF38BDF8),
            ),
            onPressed: () {
              store.logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (_) => false,
              );
            },
          ),
          IconButton(
            tooltip: 'Đăng xuất tài khoản bác sĩ',
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () {
              store.logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (_) => false,
              );
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
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.people_alt_outlined, size: 18),
              text: '1. Tiếp Nhận & Vitals',
            ),
            Tab(
              icon: Icon(Icons.menu_book_outlined, size: 18),
              text: '2. Khám & ICD-10',
            ),
            Tab(
              icon: Icon(Icons.biotech_outlined, size: 18),
              text: '3. Cận Lâm Sàng & Phim',
            ),
            Tab(
              icon: Icon(Icons.medication_outlined, size: 18),
              text: '4. Đơn Thuốc & Dược',
            ),
            Tab(
              icon: Icon(Icons.verified_outlined, size: 18),
              text: '5. Ký Số & Đồng Bộ EMR',
            ),
            Tab(
              icon: Icon(Icons.local_hospital_outlined, size: 18),
              text: '6. Theo Khoa',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildClinicalPatientSelector(context, store),
          _buildWorkflowOverview(context, store),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTab1ReceptionAndVitals(context, store, queue, isDark),
                _buildTab2ClinicalAndIcd10(context, store, isDark),
                _buildTab3LabsAndImaging(context, store, isDark),
                _buildTab4EPrescription(context, store, isDark),
                _buildTab5SignAndFullSync(context, store, doctor, isDark),
                _buildSpecialtyTab(context, store, doctor, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowOverview(BuildContext context, MedicalStore store) {
    final selected = store.appointments.cast<Appointment?>().firstWhere(
      (item) => item?.id == store.activeClinicalAppointmentId,
      orElse: () => null,
    );
    final hasPatient = selected != null;
    final stages = [
      ('Tiếp nhận', Icons.how_to_reg_outlined),
      ('Sinh hiệu', Icons.monitor_heart_outlined),
      ('Khám & ICD', Icons.medical_services_outlined),
      ('Cận lâm sàng', Icons.biotech_outlined),
      ('Đơn thuốc', Icons.medication_outlined),
      ('Ký & gửi BN', Icons.verified_outlined),
    ];
    return Container(
      width: double.infinity,
      color: hasPatient ? const Color(0xFFF8FAFC) : const Color(0xFFFFF7ED),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasPatient
                    ? Icons.assignment_turned_in_outlined
                    : Icons.warning_amber_outlined,
                size: 18,
                color: hasPatient
                    ? const Color(0xFF006C49)
                    : Colors.orange.shade800,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasPatient
                      ? 'Ca khám đang xử lý: ${selected.patientName} • ${selected.reason}'
                      : 'Chưa chọn ca khám. Hãy chọn lịch hẹn backend trước khi ghi dữ liệu.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (hasPatient)
                Text(
                  selected.status.name,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF006C49),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var index = 0; index < stages.length; index++) ...[
                  _workflowStage(
                    index + 1,
                    stages[index].$1,
                    stages[index].$2,
                    hasPatient,
                  ),
                  if (index < stages.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _workflowStage(
    int number,
    String label,
    IconData icon,
    bool enabled,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: enabled ? const Color(0xFFE0F2FE) : Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: enabled ? const Color(0xFF7DD3FC) : const Color(0xFFE2E8F0),
      ),
    ),
    child: Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: enabled ? const Color(0xFF0057CD) : Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          '$number. $label',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: enabled ? const Color(0xFF0F2B5C) : Colors.grey,
          ),
        ),
      ],
    ),
  );

  List<String> _specialtyFields(String specialty) {
    final normalized = specialty.toLowerCase();
    if (normalized.contains('tim')) {
      return [
        'Huyết áp / nhịp tim',
        'ECG và triệu chứng tim mạch',
        'Đánh giá nguy cơ tim mạch',
      ];
    }
    if (normalized.contains('nhi')) {
      return [
        'Cân nặng / chiều cao',
        'Biểu đồ tăng trưởng',
        'Tiêm chủng và liều thuốc theo cân nặng',
      ];
    }
    if (normalized.contains('sản') || normalized.contains('phụ')) {
      return [
        'Tuổi thai / ngày dự sinh',
        'Kết quả siêu âm',
        'Lịch khám thai và cảnh báo',
      ];
    }
    if (normalized.contains('da')) {
      return [
        'Vị trí tổn thương da',
        'Mô tả tổn thương và ảnh tham chiếu',
        'Phác đồ và lịch theo dõi trước/sau điều trị',
      ];
    }
    if (normalized.contains('nội tiết')) {
      return [
        'Đường huyết / HbA1c',
        'Insulin và mục tiêu điều trị',
        'Chế độ ăn và kế hoạch theo dõi',
      ];
    }
    if (normalized.contains('xương')) {
      return [
        'Vị trí và mức độ đau',
        'Khả năng vận động',
        'X-quang/MRI và kế hoạch vật lý trị liệu',
      ];
    }
    if (normalized.contains('tai') || normalized.contains('mũi')) {
      return [
        'Tai / mũi / họng',
        'Nội soi và thính lực',
        'Điều trị và lịch tái khám',
      ];
    }
    if (normalized.contains('tiêu hóa')) {
      return [
        'Đau bụng và triệu chứng tiêu hóa',
        'Nội soi / xét nghiệm Hp',
        'Chế độ ăn và hướng xử trí',
      ];
    }
    if (normalized.contains('hô hấp') || normalized.contains('phổi')) {
      return [
        'SpO₂ / nhịp thở',
        'X-quang phổi và nghe phổi',
        'Kế hoạch theo dõi hô hấp',
      ];
    }
    if (normalized.contains('cấp cứu')) {
      return [
        'Mức độ cấp cứu',
        'Dấu hiệu sinh tồn',
        'Xử trí ban đầu và hướng chuyển viện',
      ];
    }
    if (normalized.contains('xét nghiệm')) {
      return [
        'Mã chỉ định',
        'Kết quả và đơn vị đo',
        'Khoảng tham chiếu / bất thường',
      ];
    }
    if (normalized.contains('hình ảnh')) {
      return ['Loại thăm dò', 'Mô tả hình ảnh', 'Kết luận và khuyến nghị'];
    }
    return [
      'Triệu chứng chính',
      'Khám chuyên khoa',
      'Kết luận và hướng điều trị',
    ];
  }

  Widget _buildSpecialtyTab(
    BuildContext context,
    MedicalStore store,
    DoctorProfile doctor,
    bool isDark,
  ) {
    final fields = _specialtyFields(doctor.specialty);
    final controllers = [
      _specialtyField1Ctrl,
      _specialtyField2Ctrl,
      _specialtyField3Ctrl,
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSyncNoticeBanner(
          'Biểu mẫu ${doctor.specialty}: dữ liệu bác sĩ nhập sẽ được lưu vào hồ sơ bệnh nhân và audit backend.',
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${doctor.specialty} • Phiếu đánh giá chuyên khoa',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Không dùng kết quả mẫu. Bác sĩ phải nhập dữ liệu thực tế của bệnh nhân trước khi lưu.',
                ),
                const SizedBox(height: 16),
                for (var index = 0; index < fields.length; index++) ...[
                  TextField(
                    controller: controllers[index],
                    minLines: index == 1 ? 2 : 1,
                    maxLines: index == 1 ? 4 : 2,
                    decoration: InputDecoration(
                      labelText: fields[index],
                      prefixIcon: Icon(
                        index == 0
                            ? Icons.monitor_heart_outlined
                            : index == 1
                            ? Icons.notes_outlined
                            : Icons.assignment_turned_in_outlined,
                      ),
                    ),
                  ),
                  if (index < fields.length - 1) const SizedBox(height: 12),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (controllers.any(
                        (controller) => controller.text.trim().isEmpty,
                      )) {
                        _showSnack(
                          context,
                          'Vui lòng nhập đủ thông tin chuyên khoa.',
                          color: Colors.orange,
                        );
                        return;
                      }
                      store.doctorSaveSpecialtyAssessment(
                        specialty: doctor.specialty,
                        fields: {
                          fields[0]: controllers[0].text.trim(),
                          fields[1]: controllers[1].text.trim(),
                          fields[2]: controllers[2].text.trim(),
                        },
                      );
                      _showSnack(
                        context,
                        'Đã lưu phiếu ${doctor.specialty} vào hồ sơ bệnh nhân.',
                      );
                    },
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text('Lưu và gửi vào hồ sơ bệnh nhân'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClinicalPatientSelector(
    BuildContext context,
    MedicalStore store,
  ) {
    final docId = store.activeDoctorUser.id;
    final docName = store.activeDoctorUser.name;
    final appointments = store.appointments
        .where(
          (item) =>
              item.status != AppointmentStatus.cancelled &&
              (item.doctorId == docId ||
                  item.doctorName == docName ||
                  item.doctorId == store.backendUserId ||
                  !store.appointments.any(
                    (a) =>
                        a.status != AppointmentStatus.cancelled &&
                        (a.doctorId == docId || a.doctorName == docName),
                  )),
        )
        .toList(growable: false);
    final activeId = store.activeClinicalAppointmentId;
    final selectedId =
        (activeId != null && appointments.any((item) => item.id == activeId))
        ? activeId
        : (appointments.isNotEmpty ? appointments.first.id : null);
    final hasSelected = selectedId != null;

    if (store.activeClinicalAppointmentId == null && appointments.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (store.activeClinicalAppointmentId == null) {
          store.selectClinicalAppointment(appointments.first);
        }
      });
    }

    return Material(
      color: const Color(0xFFEFF6FF),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            const Icon(Icons.person_search_outlined, color: Color(0xFF0057CD)),
            const SizedBox(width: 10),
            Expanded(
              child: appointments.isEmpty
                  ? const Text(
                      'Chưa có lịch hẹn bệnh nhân từ backend. Hãy để bệnh nhân đặt lịch trước.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF334155)),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: hasSelected ? selectedId : null,
                        hint: const Text('Chọn bệnh nhân đang khám'),
                        items: appointments
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item.id,
                                child: Text(
                                  '${item.patientName} (${item.ticketNumber ?? item.id}) • ${item.reason}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (id) {
                          if (id == null) return;
                          final appointment = appointments.firstWhere(
                            (item) => item.id == id,
                          );
                          store.selectClinicalAppointment(appointment);
                        },
                      ),
                    ),
            ),
            IconButton(
              tooltip: 'Tải lại lịch hẹn từ server',
              onPressed: () => store.refreshAppointmentsFromBackend(),
              icon: const Icon(Icons.refresh, color: Color(0xFF0057CD)),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // TAB 1: TIẾP NHẬN & TIỀN LÂM SÀNG (CHỨC NĂNG 1 - 6)
  // ============================================================================
  Widget _buildTab1ReceptionAndVitals(
    BuildContext context,
    MedicalStore store,
    LiveQueueInfo queue,
    bool isDark,
  ) {
    final selectedAppt =
        store.activeClinicalAppointment ??
        (store.appointments.isNotEmpty ? store.appointments.first : null);
    if (store.hasBackendSession &&
        store.activeClinicalAppointmentId == null &&
        selectedAppt == null) {
      return _buildNoClinicalCase(context, store);
    }
    final patient = store.profile;
    final patientName = selectedAppt?.patientName ?? patient.name;
    Map<String, Object?>? selectedQueueTicket;
    if (selectedAppt != null) {
      for (final item in store.queueTickets) {
        final payload = item['payload'];
        if (payload is Map &&
            payload['appointmentId']?.toString() == selectedAppt.id) {
          selectedQueueTicket = Map<String, Object?>.from(payload);
          break;
        }
      }
    }
    final ticketNumber = selectedQueueTicket?['patientNumber'];
    final currentTicket = ticketNumber is num
        ? '#${ticketNumber.toInt()}'
        : queue.ticketCode;
    final currentNumber = queue.currentNumber;
    final currentRoom = (selectedAppt?.location.isNotEmpty == true)
        ? selectedAppt!.location
        : queue.room;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSyncNoticeBanner(
          'Phân hệ Tiếp nhận: Điều phối số thứ tự và sinh hiệu gửi thông báo đẩy trực tiếp tới ứng dụng bệnh nhân.',
        ),
        const SizedBox(height: 14),

        // 1. GỌI BỆNH NHÂN THEO SỐ THỨ TỰ (Chức năng 1)
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.campaign_rounded, color: Color(0xFF0057CD)),
                    SizedBox(width: 8),
                    Text(
                      '1. ĐIỀU PHỐI HÀNG ĐỢI & GỌI SỐ (QUEUE DISPATCH)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0057CD),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF93C5FD)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'ĐANG GỌI',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '#$currentNumber',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0057CD),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bệnh nhân vào khám: $patientName',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Phòng: $currentRoom • Mã lượt: $currentTicket',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            'Thời gian chờ ước tính: ~${queue.estimatedMinutes} phút',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      try {
                        await store.doctorCallNextPatientOnlineFirst(
                          'Phòng 402',
                        );
                      } catch (error) {
                        if (!context.mounted) return;
                        _showSnack(
                          context,
                          'Không thể gọi bệnh nhân: $error',
                          color: Colors.redAccent,
                        );
                        return;
                      }
                      if (!context.mounted) return;
                      _showSnack(
                        context,
                        '📢 Đã phát loa mời bệnh nhân số #${queue.currentNumber + 1} vào Phòng 402!',
                      );
                    },
                    icon: const Icon(Icons.campaign_rounded),
                    label: Text(
                      'GỌI SỐ KẾ TIẾP (#${queue.currentNumber + 1}) VÀO PHÒNG 402',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0057CD),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.monitor_heart_rounded, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text(
                      '2. ĐO VÀ ĐỒNG BỘ SINH HIỆU (VITALS DIRECT SYNC)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniInput(
                        'Huyết áp Tâm thu',
                        _bpSysCtrl,
                        'mmHg',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMiniInput(
                        'Huyết áp Tâm trương',
                        _bpDiaCtrl,
                        'mmHg',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMiniInput('Nhịp tim', _hrCtrl, 'bpm'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildMiniInput('SpO2', _spo2Ctrl, '%')),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMiniInput('Nhiệt độ', _tempCtrl, '°C'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMiniInput('Cân nặng', _weightCtrl, 'kg'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniInput(
                        'Đường huyết',
                        _glucoseCtrl,
                        'mg/dL',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMiniInput('Chiều cao', _heightCtrl, 'cm'),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(child: SizedBox()),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final sys = double.tryParse(_bpSysCtrl.text);
                      final dia = double.tryParse(_bpDiaCtrl.text);
                      final hr = int.tryParse(_hrCtrl.text);
                      final spo2 = double.tryParse(_spo2Ctrl.text);
                      final temp = double.tryParse(_tempCtrl.text);
                      final weight = double.tryParse(_weightCtrl.text);
                      final glucose = double.tryParse(_glucoseCtrl.text);
                      final height = double.tryParse(_heightCtrl.text);
                      if ([
                        sys,
                        dia,
                        hr,
                        spo2,
                        temp,
                        weight,
                        glucose,
                        height,
                      ].any((value) => value == null)) {
                        _showSnack(
                          context,
                          'Vui lòng nhập đủ 8 chỉ số sinh hiệu trước khi lưu.',
                          color: Colors.orange,
                        );
                        return;
                      }
                      try {
                        await store.doctorRecordVitalsOnlineFirst(
                          bpSys: sys!,
                          bpDia: dia!,
                          heartRate: hr!,
                          spo2: spo2!,
                          temp: temp!,
                          weight: weight!,
                          bloodGlucose: glucose!,
                          heightCm: height!,
                        );
                        if (!context.mounted) return;
                        _showSnack(
                          context,
                          '🩺 Đã lưu sinh hiệu vào EMR và đồng bộ sang app bệnh nhân!',
                        );
                      } catch (error) {
                        if (!context.mounted) return;
                        _showSnack(
                          context,
                          'Không thể lưu EMR: $error',
                          color: Colors.redAccent,
                        );
                      }
                    },
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text(
                      'LƯU & TRUYỀN SINH HIỆU SANG APP BỆNH NHÂN',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                    ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TIỆN ÍCH TIỀN LÂM SÀNG MỞ RỘNG (CHỨC NĂNG 3 - 6):',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final form = await _showDetailForm(
                          context,
                          title: '3. Bệnh sử và dị ứng',
                          fields: const [
                            'Bệnh sử / thuốc đang dùng',
                            'Dị ứng đã xác nhận',
                          ],
                          initial: {
                            'Dị ứng đã xác nhận': store.hasBackendSession
                                ? store.activeClinicalAllergies
                                : patient.allergies,
                          },
                        );
                        if (form == null) return;
                        store.doctorReviewHistory(
                          history: form['Bệnh sử / thuốc đang dùng'],
                          allergyNotes: form['Dị ứng đã xác nhận'],
                        );
                        _showSnack(
                          context,
                          '📋 Đã lưu bệnh sử, dị ứng và ghi nhận audit log.',
                        );
                      },
                      icon: const Icon(Icons.history_edu_rounded, size: 16),
                      label: const Text('3. Xem Bệnh sử & Dị ứng'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final form = await _showDetailForm(
                          context,
                          title: '4. Phân tầng nguy cơ',
                          fields: const [
                            'Mức độ nguy cơ',
                            'Lý do / dấu hiệu cảnh báo',
                          ],
                          initial: const {'Mức độ nguy cơ': 'Mức độ 2'},
                        );
                        if (form == null) return;
                        store.doctorUpdateTriageRisk(
                          form['Mức độ nguy cơ']!,
                          reason: form['Lý do / dấu hiệu cảnh báo']!,
                        );
                        _showSnack(
                          context,
                          '⚠️ Đã lưu phân tầng nguy cơ vào hồ sơ bệnh nhân.',
                        );
                      },
                      icon: const Icon(Icons.crisis_alert_rounded, size: 16),
                      label: const Text('4. Phân tầng Nguy cơ (Triage)'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final form = await _showDetailForm(
                          context,
                          title: '5. Điều hướng buồng khám',
                          fields: const [
                            'Phòng / khu vực tiếp theo',
                            'Ghi chú điều phối',
                          ],
                          initial: const {
                            'Phòng / khu vực tiếp theo': 'Phòng 204',
                          },
                        );
                        if (form == null) return;
                        store.doctorAssignRoom(
                          form['Phòng / khu vực tiếp theo']!,
                          note: form['Ghi chú điều phối']!,
                        );
                        _showSnack(context, '📍 Đã lưu điều phối buồng khám.');
                      },
                      icon: const Icon(Icons.meeting_room_rounded, size: 16),
                      label: const Text('5. Điều hướng Buồng khám'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final form = await _showDetailForm(
                          context,
                          title: '6. Xác thực thẻ BHYT',
                          fields: const [
                            'Số thẻ BHYT',
                            'Mã xác thực / kết quả đối soát',
                          ],
                          initial: {'Số thẻ BHYT': patient.insuranceNumber},
                        );
                        if (form == null) return;
                        store.doctorBiometricVerification(
                          cardNumber: form['Số thẻ BHYT'],
                          verificationCode:
                              form['Mã xác thực / kết quả đối soát'],
                        );
                        _showSnack(
                          context,
                          '🛡️ Đã lưu kết quả đối soát thẻ BHYT.',
                        );
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

  Widget _buildNoClinicalCase(BuildContext context, MedicalStore store) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_busy_outlined,
              size: 64,
              color: Color(0xFF64748B),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có ca khám thật để xử lý',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bệnh nhân cần đặt lịch, thanh toán/xác nhận và check-in trước. Dữ liệu mẫu không được dùng trong phiên backend.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () async {
                await store.refreshAppointmentsFromBackend();
                await store.refreshQueueTicketsFromBackend();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Tải lại ca khám từ backend'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // TAB 2: KHÁM LÂM SÀNG & CHẨN ĐOÁN ICD-10 (CHỨC NĂNG 7 - 12)
  // ============================================================================
  Widget _buildTab2ClinicalAndIcd10(
    BuildContext context,
    MedicalStore store,
    bool isDark,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSyncNoticeBanner(
          'Phân hệ Chẩn đoán: Nhập khám thực thể, chuẩn hóa mã ICD-10 và đánh giá điểm lâm sàng để truyền vào Hồ sơ Bệnh án.',
        ),
        const SizedBox(height: 14),

        // 7. KHÁM THỰC THỂ CÁC CƠ QUAN (Chức năng 7)
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.local_hospital_outlined,
                      color: Color(0xFF0057CD),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '7. KHÁM THỰC THỂ CÁC CƠ QUAN (PHYSICAL EXAMINATION)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0057CD),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _symptomsCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Triệu chứng / lý do đến khám',
                    hintText: 'Ghi theo lời bệnh nhân và thời điểm khởi phát',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _physicalExamCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final form = await _showDetailForm(
                        context,
                        title: '7. Phiếu khám thực thể có cấu trúc',
                        fields: const [
                          'Toàn trạng và tri giác',
                          'Tim mạch',
                          'Hô hấp',
                          'Tiêu hóa',
                          'Thần kinh',
                          'Da và niêm mạc',
                          'Cơ xương khớp',
                          'Nhận định lâm sàng',
                          'Kế hoạch theo dõi / xử trí',
                        ],
                      );
                      if (form == null) return;
                      final findings = <String, String>{
                        'Toàn trạng và tri giác':
                            form['Toàn trạng và tri giác']!,
                        'Tim mạch': form['Tim mạch']!,
                        'Hô hấp': form['Hô hấp']!,
                        'Tiêu hóa': form['Tiêu hóa']!,
                        'Thần kinh': form['Thần kinh']!,
                        'Da và niêm mạc': form['Da và niêm mạc']!,
                        'Cơ xương khớp': form['Cơ xương khớp']!,
                      };
                      final summary = findings.entries
                          .map((entry) => '${entry.key}: ${entry.value}')
                          .join('\n');
                      _physicalExamCtrl.text = summary;
                      store.doctorRecordPhysicalExam(
                        summary,
                        findings: findings,
                        assessment: form['Nhận định lâm sàng']!,
                        plan: form['Kế hoạch theo dõi / xử trí']!,
                      );
                      _showSnack(
                        context,
                        'Đã lưu phiếu khám thực thể có cấu trúc.',
                      );
                    },
                    icon: const Icon(Icons.fact_check_outlined, size: 18),
                    label: const Text('Mở phiếu khám có cấu trúc'),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      store.doctorRecordPhysicalExam(
                        _physicalExamCtrl.text.trim(),
                      );
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.format_list_numbered_rounded,
                      color: Colors.indigo,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '8 & 9. CHẨN ĐOÁN XÁC ĐỊNH ICD-10 & PHÂN BIỆT',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: _buildMiniInput('Mã ICD-10', _icd10CodeCtrl, ''),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMiniInput(
                        'Tên chẩn đoán ICD-10',
                        _icd10NameCtrl,
                        '',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Chọn nhanh bệnh lý thường gặp:',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('I10 - Tăng huyết áp'),
                      onPressed: () {
                        _icd10CodeCtrl.text = 'I10';
                        _icd10NameCtrl.text =
                            'Tăng huyết áp vô căn (nguyên phát)';
                        _diagnosisCtrl.text =
                            'Tăng huyết áp nguyên phát độ 1 (I10)';
                        setState(() {});
                      },
                    ),
                    ActionChip(
                      label: const Text('E11.9 - Đái tháo đường Type 2'),
                      onPressed: () {
                        _icd10CodeCtrl.text = 'E11.9';
                        _icd10NameCtrl.text =
                            'Đái tháo đường typ 2 không có biến chứng';
                        _diagnosisCtrl.text = 'Đái tháo đường typ 2 (E11.9)';
                        setState(() {});
                      },
                    ),
                    ActionChip(
                      label: const Text('I20.9 - Cơn đau thắt ngực'),
                      onPressed: () {
                        _icd10CodeCtrl.text = 'I20.9';
                        _icd10NameCtrl.text =
                            'Cơn đau thắt ngực không đặc hiệu';
                        _diagnosisCtrl.text =
                            'Thiếu máu cơ tim / Đau thắt ngực (I20.9)';
                        setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Chẩn đoán phân biệt chuyên sâu (Chức năng 9):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _diffDiagnosisCtrl,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final form = await _showDetailForm(
                        context,
                        title: '8–9. Chẩn đoán và biện luận',
                        fields: const [
                          'Mã ICD-10 xác định',
                          'Tên chẩn đoán xác định',
                          'Mức độ chắc chắn',
                          'Căn cứ lâm sàng / cận lâm sàng',
                          'Mức độ bệnh và biến chứng',
                          'Chẩn đoán phân biệt',
                          'Lý do cần loại trừ',
                          'Kế hoạch xét nghiệm / theo dõi để loại trừ',
                        ],
                        initial: {
                          'Mã ICD-10 xác định': _icd10CodeCtrl.text,
                          'Tên chẩn đoán xác định': _icd10NameCtrl.text,
                          'Chẩn đoán phân biệt': _diffDiagnosisCtrl.text,
                        },
                      );
                      if (form == null) return;
                      _icd10CodeCtrl.text = form['Mã ICD-10 xác định']!;
                      _icd10NameCtrl.text = form['Tên chẩn đoán xác định']!;
                      _diagnosisCtrl.text = form['Tên chẩn đoán xác định']!;
                      _diffDiagnosisCtrl.text = form['Chẩn đoán phân biệt']!;
                      store.doctorSetIcd10Diagnosis(
                        form['Mã ICD-10 xác định']!,
                        form['Tên chẩn đoán xác định']!,
                        certainty: form['Mức độ chắc chắn']!,
                        rationale: form['Căn cứ lâm sàng / cận lâm sàng']!,
                        severity: form['Mức độ bệnh và biến chứng']!,
                      );
                      store.doctorAddDifferentialDiagnosis(
                        form['Chẩn đoán phân biệt']!,
                        rationale: form['Lý do cần loại trừ']!,
                        exclusionPlan:
                            form['Kế hoạch xét nghiệm / theo dõi để loại trừ']!,
                      );
                      _showSnack(
                        context,
                        'Đã lưu chẩn đoán và biện luận vào EMR.',
                      );
                    },
                    icon: const Icon(Icons.rule_folder_outlined, size: 18),
                    label: const Text('Lưu chẩn đoán & biện luận'),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ĐÁNH GIÁ CHUYÊN SÂU (CHỨC NĂNG 10, 11, 12):',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEFF6FF),
                    child: Icon(
                      Icons.analytics_outlined,
                      color: Color(0xFF0057CD),
                    ),
                  ),
                  title: const Text(
                    '10. Đánh giá bệnh lý kèm theo (Comorbidities)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Chọn bệnh kèm theo, mức độ, tình trạng kiểm soát và kế hoạch xử trí.',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final form = await _showDetailForm(
                        context,
                        title: '10. Đánh giá bệnh kèm theo',
                        fields: const [
                          'Danh sách bệnh kèm theo',
                          'Mức độ / nguy cơ',
                          'Tình trạng kiểm soát',
                          'Ghi chú xử trí',
                        ],
                        initial: const {
                          'Mức độ / nguy cơ': 'Ổn định',
                          'Tình trạng kiểm soát': 'Đang theo dõi',
                        },
                      );
                      if (form == null) return;
                      store.doctorAssessComorbidities(
                        form['Danh sách bệnh kèm theo']!
                            .split(',')
                            .map((item) => item.trim())
                            .where((item) => item.isNotEmpty)
                            .toList(growable: false),
                        severity: form['Mức độ / nguy cơ']!,
                        controlStatus: form['Tình trạng kiểm soát']!,
                        note: form['Ghi chú xử trí']!,
                      );
                      _showSnack(
                        context,
                        'Đã ghi nhận bệnh lý kèm theo vào bilan điều trị.',
                      );
                    },
                    child: const Text('Xác nhận'),
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFEF3C7),
                    child: Icon(Icons.calculate_outlined, color: Colors.amber),
                  ),
                  title: const Text(
                    '11. Thang điểm lâm sàng CHA2DS2-VASc',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Tính từ tuổi, bệnh nền, tiền sử đột quỵ và bệnh mạch máu; lưu tham số audit.',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final form = await _showDetailForm(
                        context,
                        title: '11. Tính thang điểm CHA₂DS₂-VASc',
                        fields: const [
                          'Tuổi',
                          'Suy tim (có/không)',
                          'Tăng huyết áp (có/không)',
                          'Đái tháo đường (có/không)',
                          'Đột quỵ/TIA trước đây (có/không)',
                          'Bệnh mạch máu (có/không)',
                          'Giới tính',
                        ],
                      );
                      if (form == null) return;
                      final age = int.tryParse(form['Tuổi']!) ?? 0;
                      int score = age >= 75
                          ? 2
                          : age >= 65
                          ? 1
                          : 0;
                      bool yes(String key) =>
                          form[key]!.toLowerCase().startsWith('c');
                      if (yes('Suy tim (có/không)')) score++;
                      if (yes('Tăng huyết áp (có/không)')) score++;
                      if (yes('Đái tháo đường (có/không)')) score++;
                      if (yes('Đột quỵ/TIA trước đây (có/không)')) score += 2;
                      if (yes('Bệnh mạch máu (có/không)')) score++;
                      if (form['Giới tính']!.toLowerCase().startsWith('nữ')) {
                        score++;
                      }
                      store.doctorEvaluateClinicalScore(
                        'CHA2DS2-VASc',
                        score,
                        score >= 2
                            ? 'Nguy cơ cao, cần đánh giá chỉ định chống đông.'
                            : 'Nguy cơ thấp đến trung bình, tiếp tục theo dõi.',
                        parameters: Map<String, Object?>.from(form),
                      );
                      _showSnack(
                        context,
                        'Đã lưu thang điểm lâm sàng vào EMR.',
                      );
                    },
                    child: const Text('Lưu điểm'),
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF0FDF4),
                    child: Icon(Icons.notes_rounded, color: Colors.green),
                  ),
                  title: const Text(
                    '12. Tóm tắt diễn tiến bệnh cảnh lâm sàng',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Ghi diễn tiến theo mốc, đáp ứng điều trị, kế hoạch tiếp theo và dấu hiệu cảnh báo.',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final form = await _showDetailForm(
                        context,
                        title: '12. Tóm tắt diễn tiến bệnh cảnh',
                        fields: const [
                          'Diễn tiến theo mốc thời gian',
                          'Đáp ứng với điều trị',
                          'Kế hoạch tiếp theo',
                          'Dấu hiệu cảnh báo cần quay lại viện',
                        ],
                      );
                      if (form == null) return;
                      store.doctorRecordCourseSummary(
                        form['Diễn tiến theo mốc thời gian']!,
                        responseToTreatment: form['Đáp ứng với điều trị']!,
                        nextPlan: form['Kế hoạch tiếp theo']!,
                        warningSigns:
                            form['Dấu hiệu cảnh báo cần quay lại viện']!,
                      );
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
  Widget _buildTab3LabsAndImaging(
    BuildContext context,
    MedicalStore store,
    bool isDark,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSyncNoticeBanner(
          'Phân hệ Cận Lâm Sàng: Ra y lệnh xét nghiệm, chỉ định chẩn đoán hình ảnh và trả kết quả phim X-Quang/siêu âm thẳng về ứng dụng bệnh nhân.',
        ),
        const SizedBox(height: 14),

        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.biotech, color: Colors.teal),
                    SizedBox(width: 8),
                    Text(
                      'CHỈ ĐỊNH XÉT NGHIỆM VÀ TRẢ KẾT QUẢ VỀ BỆNH NHÂN (13, 14, 15)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final form = await _showDetailForm(
                            context,
                            title: '14. Chỉ định CBC',
                            fields: const [
                              'Chỉ định bổ sung',
                              'Mức độ ưu tiên',
                            ],
                            initial: const {'Mức độ ưu tiên': 'Bình thường'},
                          );
                          if (form == null) return;
                          store.doctorCreateClinicalOrder(
                            orderType: 'LAB_CBC',
                            title: 'Tổng phân tích tế bào máu CBC',
                            details: {
                              'requestedBy': 'doctor',
                              'note': form['Chỉ định bổ sung']!,
                              'priority': form['Mức độ ưu tiên']!,
                            },
                          );
                          _showSnack(
                            context,
                            '🩸 Đã gửi y lệnh CBC đến khoa xét nghiệm.',
                          );
                        },
                        icon: const Icon(Icons.bloodtype_outlined, size: 16),
                        label: const Text('14. Chỉ định CBC (Máu)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final form = await _showDetailForm(
                            context,
                            title: '15. Chỉ định sinh hóa máu',
                            fields: const [
                              'Mục tiêu theo dõi',
                              'Mức độ ưu tiên',
                            ],
                            initial: const {'Mức độ ưu tiên': 'Bình thường'},
                          );
                          if (form == null) return;
                          store.doctorCreateClinicalOrder(
                            orderType: 'LAB_BIOCHEMISTRY',
                            title: 'Sinh hóa máu',
                            details: {
                              'tests': 'Glucose, Creatinine, eGFR',
                              'requestedBy': 'doctor',
                              'purpose': form['Mục tiêu theo dõi']!,
                              'priority': form['Mức độ ưu tiên']!,
                            },
                          );
                          _showSnack(
                            context,
                            '🧪 Đã gửi y lệnh sinh hóa đến khoa xét nghiệm.',
                          );
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
                    onPressed: () async {
                      final form = await _showDetailForm(
                        context,
                        title: '13. Tạo y lệnh xét nghiệm',
                        fields: const [
                          'Tên xét nghiệm',
                          'Mục tiêu / lý do chỉ định',
                        ],
                      );
                      if (form == null) return;
                      store.doctorCreateClinicalOrder(
                        orderType: 'LAB_CUSTOM',
                        title: form['Tên xét nghiệm']!,
                        details: {
                          'tests': form['Tên xét nghiệm']!,
                          'purpose': form['Mục tiêu / lý do chỉ định']!,
                          'requestedBy': 'doctor',
                        },
                      );
                      _showSnack(
                        context,
                        '⚡ Đã gửi y lệnh điện giải đồ đến khoa xét nghiệm.',
                      );
                    },
                    icon: const Icon(Icons.add_task_rounded, size: 16),
                    label: const Text('13. Tạo Y Lệnh Xét Nghiệm Tự Do'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final form = await _showDetailForm(
                context,
                title: 'Trả kết quả xét nghiệm về bệnh nhân',
                fields: const [
                  'Tên xét nghiệm / chỉ số',
                  'Kết quả',
                  'Đơn vị',
                  'Khoảng tham chiếu',
                  'Nhận xét bác sĩ',
                ],
              );
              if (form == null) return;
              final value = form['Kết quả']!.trim();
              final normalRange = form['Khoảng tham chiếu']!.trim();
              store.doctorOrderLabTest(
                name: form['Tên xét nghiệm / chỉ số']!.trim(),
                value: value,
                unit: form['Đơn vị']!.trim(),
                normalRange: normalRange,
                isAbnormal: form['Nhận xét bác sĩ']!.toLowerCase().contains(
                  'bất thường',
                ),
                note: form['Nhận xét bác sĩ']!.trim(),
              );
              _showSnack(
                context,
                '🧪 Đã lưu và gửi kết quả xét nghiệm cho bệnh nhân.',
              );
            },
            icon: const Icon(Icons.assignment_turned_in_outlined),
            label: const Text('Trả kết quả xét nghiệm thủ công'),
          ),
        ),
        const SizedBox(height: 16),

        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.image_search_rounded, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Text(
                      'CHẨN ĐOÁN HÌNH ẢNH & THĂM DÒ CHỨC NĂNG (16 - 20)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final form = await _showDetailForm(
                          context,
                          title: '16. Chỉ định X-Quang',
                          fields: const ['Lý do chỉ định', 'Mức độ ưu tiên'],
                          initial: const {'Mức độ ưu tiên': 'Bình thường'},
                        );
                        if (form == null) return;
                        store.doctorCreateClinicalOrder(
                          orderType: 'IMAGING_XRAY',
                          title: 'X-Quang ngực thẳng',
                          details: {
                            'requestedBy': 'doctor',
                            'reason': form['Lý do chỉ định']!,
                            'priority': form['Mức độ ưu tiên']!,
                          },
                        );
                        _showSnack(
                          context,
                          '🩻 Đã gửi chỉ định X-Quang đến khoa chẩn đoán hình ảnh.',
                        );
                      },
                      icon: const Icon(Icons.camera_alt_outlined, size: 16),
                      label: const Text('16. X-Quang Phổi Thẳng'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final form = await _showDetailForm(
                          context,
                          title: '17. Chỉ định siêu âm ổ bụng',
                          fields: const ['Lý do chỉ định', 'Mức độ ưu tiên'],
                          initial: const {'Mức độ ưu tiên': 'Bình thường'},
                        );
                        if (form == null) return;
                        store.doctorCreateClinicalOrder(
                          orderType: 'IMAGING_ULTRASOUND',
                          title: 'Siêu âm ổ bụng',
                          details: {
                            'requestedBy': 'doctor',
                            'reason': form['Lý do chỉ định']!,
                            'priority': form['Mức độ ưu tiên']!,
                          },
                        );
                        _showSnack(
                          context,
                          '📷 Đã gửi chỉ định siêu âm đến khoa chẩn đoán hình ảnh.',
                        );
                      },
                      icon: const Icon(Icons.waves_rounded, size: 16),
                      label: const Text('17. Siêu Âm Ổ Bụng'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final form = await _showDetailForm(
                          context,
                          title: '18. Chỉ định ECG',
                          fields: const [
                            'Triệu chứng / lý do chỉ định',
                            'Mức độ ưu tiên',
                          ],
                          initial: const {'Mức độ ưu tiên': 'Bình thường'},
                        );
                        if (form == null) return;
                        store.doctorCreateClinicalOrder(
                          orderType: 'IMAGING_ECG',
                          title: 'Điện tâm đồ ECG 12 chuyển đạo',
                          details: {
                            'requestedBy': 'doctor',
                            'reason': form['Triệu chứng / lý do chỉ định']!,
                            'priority': form['Mức độ ưu tiên']!,
                          },
                        );
                        _showSnack(
                          context,
                          '📈 Đã gửi chỉ định ECG đến bộ phận thăm dò chức năng.',
                        );
                      },
                      icon: const Icon(Icons.show_chart_rounded, size: 16),
                      label: const Text('18. Điện Tâm Đồ ECG'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final form = await _showDetailForm(
                          context,
                          title: '19. Chỉ định siêu âm tim Doppler',
                          fields: const ['Lý do chỉ định', 'Mức độ ưu tiên'],
                          initial: const {'Mức độ ưu tiên': 'Bình thường'},
                        );
                        if (form == null) return;
                        store.doctorCreateClinicalOrder(
                          orderType: 'IMAGING_ECHO',
                          title: 'Siêu âm tim Doppler',
                          details: {
                            'requestedBy': 'doctor',
                            'reason': form['Lý do chỉ định']!,
                            'priority': form['Mức độ ưu tiên']!,
                          },
                        );
                        _showSnack(
                          context,
                          '❤️ Đã gửi chỉ định siêu âm tim đến khoa thăm dò.',
                        );
                      },
                      icon: const Icon(Icons.favorite_rounded, size: 16),
                      label: const Text('19. Siêu Âm Tim Doppler'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final form = await _showDetailForm(
                          context,
                          title: '20. Chỉ định nội soi dạ dày / tiêu hóa',
                          fields: const [
                            'Loại nội soi (Dạ dày / Đại tràng)',
                            'Mức độ ưu tiên',
                          ],
                          initial: const {
                            'Loại nội soi (Dạ dày / Đại tràng)': 'Nội soi thực quản - dạ dày - tá tràng gây mê (không đau)',
                            'Mức độ ưu tiên': 'Bình thường',
                          },
                        );
                        if (form == null) return;
                        store.doctorCreateClinicalOrder(
                          orderType: 'IMAGING_ENDOSCOPY',
                          title: form['Loại nội soi (Dạ dày / Đại tràng)']!,
                          details: {
                            'requestedBy': 'doctor',
                            'priority': form['Mức độ ưu tiên']!,
                          },
                        );
                        _showSnack(
                          context,
                          '🔬 Đã gửi chỉ định nội soi tiêu hóa và cập nhật kết quả EMR.',
                        );
                      },
                      icon: const Icon(Icons.biotech_outlined, size: 16),
                      label: const Text('20. Nội Soi Dạ Dày / Tiêu Hóa'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final form = await _showDetailForm(
                        context,
                        title: '21. Tải ảnh phim và kết luận vào EMR',
                        fields: const [
                          'Loại thăm dò / vùng chụp',
                          'Kết luận của bác sĩ chẩn đoán hình ảnh',
                        ],
                      );
                      if (form == null) return;
                      try {
                        final uploaded = await store
                            .doctorPickAndPushImagingResult(
                              modality: form['Loại thăm dò / vùng chụp']!,
                              findings:
                                  form['Kết luận của bác sĩ chẩn đoán hình ảnh']!,
                            );
                        if (uploaded) {
                          _showSnack(
                            context,
                            '🖼️ Đã tải ảnh và kết luận vào EMR, bệnh nhân sẽ nhận thông báo.',
                          );
                        }
                      } catch (error) {
                        _showSnack(context, 'Không thể tải ảnh: $error');
                      }
                    },
                    icon: const Icon(Icons.cloud_done_rounded, size: 16),
                    label: const Text(
                      '20. Đẩy Ảnh Phim Y Khoa Số Hóa Vào Hồ Sơ EMR',
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

  // ============================================================================
  // TAB 4: KÊ ĐƠN ĐIỆN TỬ & DƯỢC LÂM SÀNG (CHỨC NĂNG 21 - 26)
  // ============================================================================
  Widget _buildTab4EPrescription(
    BuildContext context,
    MedicalStore store,
    bool isDark,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSyncNoticeBanner(
          'Phân hệ Đơn Thuốc: Kê đơn thuốc chuẩn quốc gia, kiểm tra tương tác thuốc, tự động sinh lịch uống thuốc kèm nhắc nhở cho bệnh nhân.',
        ),
        const SizedBox(height: 14),

        // DANH MỤC THUỐC ĐÃ CHỈ ĐỊNH
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'DANH MỤC THUỐC KÊ ĐƠN (CHỨC NĂNG 21):',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    Text(
                      '${_consultationMedicines.length} loại thuốc',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                ..._consultationMedicines.map(
                  (med) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 18,
                          color: Colors.teal,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${med.name} ${med.dosage} (${med.quantity})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${med.instruction} • ${med.warning ?? "Đúng chỉ định"}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              if (med.price > 0)
                                Text(
                                  'Đơn giá: ${_formatCurrency(med.price)} • Thành tiền: ${_formatCurrency(_medicineTotal(med))}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.indigo,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_consultationMedicines.any((item) => item.price > 0))
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Tổng tiền thuốc: ${_formatCurrency(_consultationMedicines.fold<int>(0, (sum, item) => sum + _medicineTotal(item)))}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(height: 8),
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
                        onPressed: () async {
                          try {
                            await store.doctorPrescribeMedicationOnlineFirst(
                              patientName:
                                  store
                                      .activeClinicalAppointment
                                      ?.patientName ??
                                  store.profile.name,
                              diagnosis: _diagnosisCtrl.text.trim(),
                              medicines: _consultationMedicines,
                              advice: _adviceCtrl.text.trim(),
                            );
                            if (!context.mounted) return;
                            _showSnack(
                              context,
                              '💊 Đã ký/lưu đơn thuốc vào backend và app bệnh nhân!',
                            );
                          } catch (error) {
                            if (!context.mounted) return;
                            _showSnack(
                              context,
                              'Không thể lưu đơn thuốc: $error',
                              color: Colors.redAccent,
                            );
                          }
                        },
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('Lưu Đơn Thuốc'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.teal,
                        ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TIỆN ÍCH DƯỢC LÂM SÀNG & AN TOÀN DÙNG THUỐC (22 - 26):',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final form = await _showDetailForm(
                          context,
                          title: '22. Kiểm tra tương tác thuốc',
                          fields: const ['Thuốc 1', 'Thuốc 2'],
                          initial: const {
                            'Thuốc 1': 'Amlodipine',
                            'Thuốc 2': 'Atorvastatin',
                          },
                        );
                        if (form == null) return;
                        final res = store.doctorCheckDrugInteraction(
                          form['Thuốc 1']!,
                          form['Thuốc 2']!,
                        );
                        _showSnack(context, '🔍 $res', color: Colors.teal);
                      },
                      icon: const Icon(Icons.sync_problem_rounded, size: 16),
                      label: const Text('22. Kiểm Tra Tương Tác Thuốc'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final form = await _showDetailForm(
                          context,
                          title: '23. Kiểm tra dị ứng',
                          fields: const ['Tên thuốc cần kiểm tra'],
                        );
                        if (form == null) return;
                        final drugName = form['Tên thuốc cần kiểm tra']!;
                        if (store.hasBackendSession &&
                            store.activeClinicalAllergies.trim().isEmpty) {
                          _showSnack(
                            context,
                            'Chưa có dữ liệu dị ứng của bệnh nhân đang khám. Hãy cập nhật ở mục 3 trước khi kiểm tra.',
                            color: Colors.orange,
                          );
                          return;
                        }
                        final isAllergic = store.doctorCheckAllergyRisk(
                          drugName,
                        );
                        _showSnack(
                          context,
                          isAllergic
                              ? '⚠️ BỆNH NHÂN DỊ ỨNG PENICILLIN! Tuyệt đối không kê kháng sinh nhóm Beta-lactam.'
                              : 'An toàn dị ứng.',
                          color: isAllergic ? Colors.redAccent : Colors.green,
                        );
                      },
                      icon: const Icon(Icons.warning_amber_rounded, size: 16),
                      label: const Text('23. Cảnh Báo Dị Ứng Bệnh Nhân'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final form = await _showDetailForm(
                          context,
                          title: '24. Tính liều theo eGFR',
                          fields: const [
                            'Tên thuốc / hoạt chất',
                            'Cân nặng (kg)',
                            'eGFR (mL/phút)',
                          ],
                        );
                        if (form == null) return;
                        final doseInfo = store.doctorCalculateRenalDose(
                          double.tryParse(form['Cân nặng (kg)']!) ?? 0,
                          double.tryParse(form['eGFR (mL/phút)']!) ?? 0,
                          medicineName: form['Tên thuốc / hoạt chất']!,
                        );
                        _showSnack(context, '📊 $doseInfo');
                      },
                      icon: const Icon(Icons.calculate_outlined, size: 16),
                      label: const Text('24. Tính Liều Theo Thận eGFR'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final form = await _showDetailForm(
                          context,
                          title: '25. Lập lịch uống thuốc',
                          fields: const [
                            'Tên thuốc / hàm lượng',
                            'Giờ uống',
                            'Liều và hướng dẫn',
                          ],
                        );
                        if (form == null) return;
                        store.doctorGenerateAutoSchedule(
                          medicineName: form['Tên thuốc / hàm lượng']!,
                          timeOfDay: form['Giờ uống']!,
                          dosage: form['Liều và hướng dẫn']!,
                        );
                        _showSnack(
                          context,
                          '⏰ Đã tự động tạo Lịch Uống Thuốc vào app Bệnh nhân kèm nhắc nhở!',
                        );
                      },
                      icon: const Icon(Icons.alarm_add_rounded, size: 16),
                      label: const Text('25. Lập Lịch Uống Thuốc Cho BN'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final form = await _showDetailForm(
                          context,
                          title: '26. Gửi đơn thuốc liên thông',
                          fields: const [
                            'Mã đơn thuốc đã ký',
                            'Trạng thái đối soát',
                          ],
                          initial: const {
                            'Trạng thái đối soát': 'Chờ cổng quốc gia xác nhận',
                          },
                        );
                        if (form == null) return;
                        store.doctorSubmitNationalPrescriptionPortal(
                          form['Mã đơn thuốc đã ký']!,
                        );
                        _showSnack(
                          context,
                          '🏛️ Đã gửi đơn thuốc lên cổng liên thông, đang chờ xác nhận.',
                        );
                      },
                      icon: const Icon(
                        Icons.send_and_archive_rounded,
                        size: 16,
                      ),
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
  Widget _buildTab5SignAndFullSync(
    BuildContext context,
    MedicalStore store,
    DoctorProfile doctor,
    bool isDark,
  ) {
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
              BoxShadow(
                color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ĐỒNG BỘ DỮ LIỆU KHÁM BỆNH VỀ TÀI KHOẢN BỆNH NHÂN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Toàn bộ kết quả chẩn đoán ICD-10, sinh hiệu, đơn thuốc, lịch uống thuốc và lời dặn sẽ được đóng gói thành Hồ sơ Bệnh án Điện tử (EMR) có mã ký số bảo mật chuẩn SHA-256 và truyền ngay lập tức sang ứng dụng của bệnh nhân.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              // NÚT SIÊU HÀNH ĐỘNG SỐ 32
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () => _executeMasterSync(context, store, doctor),
                  icon: const Icon(
                    Icons.flash_on_rounded,
                    color: Colors.amberAccent,
                  ),
                  label: const Text(
                    '🔥 32. KÝ SỐ EMR & TRUYỀN DỮ LIỆU ĐỒNG BỘ SANG BỆNH NHÂN',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF042F2E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: store.activeClinicalAppointmentId == null
                      ? null
                      : () => _closeConsultation(context, store),
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text(
                    'KẾT THÚC CA KHÁM / CHỐT HỒ SƠ',
                    style: TextStyle(fontWeight: FontWeight.w800),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'THAO TÁC LÂM SÀNG BỔ TRỢ (CHỨC NĂNG 27 - 31):',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEFF6FF),
                    child: Icon(
                      Icons.fingerprint_rounded,
                      color: Color(0xFF0057CD),
                    ),
                  ),
                  title: const Text(
                    '27. Ký số EMR điện tử (Digital Signature SHA-256)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Tạo mã Hash bảo mật không thể giả mạo theo chuẩn y tế.',
                    style: TextStyle(fontSize: 11),
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final form = await _showDetailForm(
                        context,
                        title: '27. Ký số EMR',
                        fields: const [
                          'Khóa chứng thư / mã xác thực',
                          'Xác nhận nội dung ký',
                          'Lý do ký và phạm vi phát hành',
                        ],
                        initial: const {
                          'Khóa chứng thư / mã xác thực': 'CERT-VN-MEDCARE',
                          'Xác nhận nội dung ký': 'Đã kiểm tra bệnh án, đơn thuốc và kết quả cận lâm sàng',
                          'Lý do ký và phạm vi phát hành': 'Phát hành EMR cho bệnh nhân và các khoa liên quan',
                        },
                      );
                      if (form == null) return;
                      try {
                        final signature = await store
                            .doctorDigitalSignEmrOnlineFirst(
                              signer: doctor.name,
                              certKey: form['Khóa chứng thư / mã xác thực']!,
                              confirmation: form['Xác nhận nội dung ký']!,
                              signingReason:
                                  form['Lý do ký và phạm vi phát hành']!,
                            );
                        if (!context.mounted) return;
                        _showSnack(
                          context,
                          '🔏 Máy chủ đã ký EMR HMAC-SHA256: ${signature.substring(0, 16)}…',
                        );
                      } catch (error) {
                        if (!context.mounted) return;
                        _showSnack(
                          context,
                          'Không thể ký EMR: $error',
                          color: Colors.redAccent,
                        );
                      }
                    },
                    child: const Text('Ký số EMR'),
                  ),
                ),
                const Divider(),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFEF3C7),
                    child: Icon(
                      Icons.event_repeat_rounded,
                      color: Colors.amber,
                    ),
                  ),
                  title: const Text(
                    '28. Đặt lịch tái khám định kỳ (Follow-up Reminder)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Hẹn tái khám sau $_followUpDays ngày kèm thông báo tự động.',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final targetDate = DateTime.now().add(
                        const Duration(days: 14),
                      );
                      final form = await _showDetailForm(
                        context,
                        title: '28. Đặt lịch tái khám',
                        fields: const [
                          'Ngày tái khám (dd/MM/yyyy)',
                          'Mục tiêu tái khám / hướng dẫn',
                          'Loại lần hẹn',
                          'Kênh nhắc bệnh nhân',
                          'Chu kỳ',
                        ],
                        initial: {
                          'Ngày tái khám (dd/MM/yyyy)':
                              '${targetDate.day.toString().padLeft(2, '0')}/${targetDate.month.toString().padLeft(2, '0')}/${targetDate.year}',
                          'Loại lần hẹn': 'Tái khám định kỳ',
                          'Kênh nhắc bệnh nhân': 'Thông báo ứng dụng',
                          'Chu kỳ': 'Một lần',
                        },
                      );
                      if (form == null) return;
                      final dateParts = form['Ngày tái khám (dd/MM/yyyy)']!
                          .split('/');
                      final followUpDate = dateParts.length == 3
                          ? DateTime.tryParse(
                              '${dateParts[2]}-${dateParts[1].padLeft(2, '0')}-${dateParts[0].padLeft(2, '0')}T09:00:00',
                            )
                          : null;
                      if (followUpDate == null) {
                        _showSnack(
                          context,
                          'Ngày tái khám không hợp lệ.',
                          color: Colors.orange,
                        );
                        return;
                      }
                      try {
                        await store.doctorScheduleFollowUpOnlineFirst(
                          dateTime: followUpDate,
                          notes: form['Mục tiêu tái khám / hướng dẫn']!,
                          doctorName: doctor.name,
                          specialty: doctor.specialty,
                          visitType: form['Loại lần hẹn']!,
                        );
                        if (!context.mounted) return;
                        _showSnack(
                          context,
                          '📅 Đã tạo lịch tái khám trên backend.',
                        );
                      } catch (error) {
                        if (!context.mounted) return;
                        _showSnack(
                          context,
                          'Không thể tạo lịch tái khám: $error',
                          color: Colors.redAccent,
                        );
                      }
                    },
                    child: const Text('Hẹn khám'),
                  ),
                ),
                const Divider(),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF0FDF4),
                    child: Icon(Icons.groups_rounded, color: Colors.green),
                  ),
                  title: const Text(
                    '29. Yêu cầu hội chẩn chuyên khoa (Consultation)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Gửi câu hỏi lâm sàng, SLA phản hồi và tài liệu liên quan cho khoa hội chẩn.',
                    style: TextStyle(fontSize: 11),
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final form = await _showDetailForm(
                        context,
                        title: '29. Yêu cầu hội chẩn',
                        fields: const [
                          'Chuyên khoa hội chẩn',
                          'Câu hỏi / lý do gửi hội chẩn',
                          'Mức độ ưu tiên / SLA phản hồi',
                          'Tài liệu gửi kèm',
                        ],
                        initial: const {
                          'Chuyên khoa hội chẩn': 'Nội tiết & Chuyển hóa',
                        },
                      );
                      if (form == null) return;
                      store.doctorRequestSpecialtyConsultation(
                        form['Chuyên khoa hội chẩn']!,
                        form['Câu hỏi / lý do gửi hội chẩn']!,
                        urgency: form['Mức độ ưu tiên / SLA phản hồi']!,
                        clinicalQuestion: form['Câu hỏi / lý do gửi hội chẩn']!,
                        attachments: form['Tài liệu gửi kèm']!,
                      );
                      _showSnack(
                        context,
                        '🤝 Đã gửi phiếu yêu cầu hội chẩn chuyên khoa!',
                      );
                    },
                    child: const Text('Hội chẩn'),
                  ),
                ),
                const Divider(),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFEE2E2),
                    child: Icon(
                      Icons.local_hospital_rounded,
                      color: Colors.redAccent,
                    ),
                  ),
                  title: const Text(
                    '30. Ra y lệnh điều trị (Hospitalization Order)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Chọn nội trú/ngoại trú, nơi tiếp nhận, mức chăm sóc, vận chuyển và xác nhận giải thích.',
                    style: TextStyle(fontSize: 11),
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final form = await _showDetailForm(
                        context,
                        title: '30. Ra y lệnh điều trị',
                        fields: const [
                          'Hình thức điều trị (nội trú/ngoại trú)',
                          'Y lệnh và theo dõi',
                          'Khoa / nơi tiếp nhận',
                          'Loại giường / mức chăm sóc',
                          'Phương án vận chuyển',
                          'Xác nhận giải thích cho bệnh nhân',
                        ],
                        initial: const {
                          'Hình thức điều trị (nội trú/ngoại trú)': 'Ngoại trú',
                        },
                      );
                      if (form == null) return;
                      store.doctorIssueHospitalizationOrder(
                        form['Hình thức điều trị (nội trú/ngoại trú)']!
                            .toLowerCase()
                            .contains('nội trú'),
                        form['Y lệnh và theo dõi']!,
                        destination: form['Khoa / nơi tiếp nhận']!,
                        bedType: form['Loại giường / mức chăm sóc']!,
                        transport: form['Phương án vận chuyển']!,
                        consent: form['Xác nhận giải thích cho bệnh nhân']!,
                      );
                      _showSnack(
                        context,
                        '📝 Đã ban hành y lệnh điều trị ngoại trú.',
                      );
                    },
                    child: const Text('Ra y lệnh'),
                  ),
                ),
                const Divider(),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFAF5FF),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Colors.purple,
                    ),
                  ),
                  title: const Text(
                    '31. Gửi lời dặn dò y khoa trực tiếp',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Đẩy lời dặn của Bác sĩ vào chuông thông báo điện thoại bệnh nhân.',
                    style: TextStyle(fontSize: 11),
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final form = await _showDetailForm(
                        context,
                        title: '31. Gửi lời dặn dò y khoa',
                        fields: const [
                          'Lời dặn gửi cho bệnh nhân',
                          'Nhóm lời dặn',
                          'Kênh gửi',
                          'Dấu hiệu cần cấp cứu / quay lại viện',
                        ],
                        initial: {
                          'Lời dặn gửi cho bệnh nhân': _adviceCtrl.text,
                          'Nhóm lời dặn': 'Dùng thuốc và theo dõi tại nhà',
                          'Kênh gửi': 'Ứng dụng bệnh nhân',
                          'Dấu hiệu cần cấp cứu / quay lại viện': 'Đau ngực, khó thở, ngất hoặc triệu chứng nặng lên',
                        },
                      );
                      if (form == null) return;
                      store.doctorSendDirectAdvice(
                        form['Lời dặn gửi cho bệnh nhân']!,
                        category: form['Nhóm lời dặn']!,
                        channel: form['Kênh gửi']!,
                        emergencyInstruction:
                            form['Dấu hiệu cần cấp cứu / quay lại viện']!,
                      );
                      _adviceCtrl.text = form['Lời dặn gửi cho bệnh nhân']!;
                      _showSnack(
                        context,
                        '💬 Đã gửi lời dặn dò trực tiếp đến bệnh nhân!',
                      );
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
  Future<void> _executeMasterSync(
    BuildContext context,
    MedicalStore store,
    DoctorProfile doctor,
  ) async {
    final requiredFields = <String, String>{
      'triệu chứng': _symptomsCtrl.text.trim(),
      'chẩn đoán': _diagnosisCtrl.text.trim(),
      'mã ICD-10': _icd10CodeCtrl.text.trim(),
      'tên ICD-10': _icd10NameCtrl.text.trim(),
      'khám thực thể': _physicalExamCtrl.text.trim(),
      'lời dặn': _adviceCtrl.text.trim(),
    };
    final missing = requiredFields.entries
        .where((entry) => entry.value.isEmpty)
        .map((entry) => entry.key)
        .toList(growable: false);
    if (missing.isNotEmpty) {
      _showSnack(
        context,
        'Chưa thể ký EMR. Cần nhập: ${missing.join(', ')}.',
        color: Colors.orange,
      );
      return;
    }
    if (_consultationMedicines.isEmpty) {
      _showSnack(
        context,
        'Chưa có thuốc trong đơn. Hãy thêm thuốc hoặc xác nhận không kê đơn trước khi ký.',
        color: Colors.orange,
      );
      return;
    }
    final targetDate = DateTime.now().add(Duration(days: _followUpDays));
    final dateStr =
        '${targetDate.day.toString().padLeft(2, '0')}/${targetDate.month.toString().padLeft(2, '0')}/${targetDate.year}';

    try {
      await store.doctorExecuteFullConsultationOnlineFirst(
        diagnosis: _diagnosisCtrl.text.trim(),
        icd10Code: _icd10CodeCtrl.text.trim(),
        icd10Name: _icd10NameCtrl.text.trim(),
        symptoms: _symptomsCtrl.text.trim(),
        physicalExam: _physicalExamCtrl.text.trim(),
        labNotes: _labSummaryCtrl.text.trim(),
        doctorAdvice: _adviceCtrl.text.trim(),
        followUpDate: dateStr,
        prescribedMedicines: _consultationMedicines,
        riskLevel: _selectedRiskLevel,
      );
    } on StateError catch (error) {
      if (!context.mounted) return;
      _showSnack(context, error.message);
      return;
    } catch (error) {
      if (!context.mounted) return;
      _showSnack(context, 'Không thể đồng bộ EMR lên backend: $error');
      return;
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Đồng Bộ Dữ Liệu Thành Công!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
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
            _buildCheckItem(
              'Hồ sơ bệnh án điện tử (EMR) chuẩn ICD-10 (${_icd10CodeCtrl.text})',
            ),
            _buildCheckItem(
              'Đơn thuốc điện tử (${_consultationMedicines.length} loại thuốc)',
            ),
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
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('Hoàn tất'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0057CD),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _closeConsultation(
    BuildContext context,
    MedicalStore store,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kết thúc ca khám?'),
        content: const Text(
          'Sau khi chốt, ca khám sẽ chuyển sang Đã hoàn thành, hàng đợi được đóng và bệnh nhân nhận thông báo. Bạn vẫn có thể xem lại hồ sơ nhưng không sửa trực tiếp ca này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kết thúc ca'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await store.closeCurrentConsultationOnlineFirst();
      if (!context.mounted) return;
      _showSnack(
        context,
        '✅ Đã chốt và kết thúc ca khám. Bệnh nhân đã nhận thông báo.',
      );
    } catch (error) {
      if (!context.mounted) return;
      _showSnack(
        context,
        'Không thể kết thúc ca khám: $error',
        color: Colors.redAccent,
      );
    }
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.teal, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
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
        border: Border.all(
          color: const Color(0xFF0284C7).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.sensors_rounded, color: Color(0xFF0284C7), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF0369A1),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniInput(
    String label,
    TextEditingController ctrl,
    String suffix,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(
            isDense: true,
            suffixText: suffix.isNotEmpty ? suffix : null,
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF0F172A)
                : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddMedicineDialog(BuildContext context, MedicalStore store) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Thêm Thuốc Chỉ Định',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _medNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên thuốc (Biệt dược/Hoạt chất)',
              ),
            ),
            TextField(
              controller: _medDosageCtrl,
              decoration: const InputDecoration(
                labelText: 'Hàm lượng (ví dụ: 10mg, 500mg)',
              ),
            ),
            TextField(
              controller: _medQuantityCtrl,
              decoration: const InputDecoration(
                labelText: 'Số lượng (ví dụ: 30 viên, 1 chai)',
              ),
            ),
            TextField(
              controller: _medInstructionCtrl,
              decoration: const InputDecoration(labelText: 'Hướng dẫn uống'),
            ),
            TextField(
              controller: _medPriceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Giá thuốc (đồng)',
                hintText: 'Ví dụ: 35000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final price = int.tryParse(_medPriceCtrl.text.trim()) ?? 0;
              if (_medNameCtrl.text.trim().isEmpty ||
                  _medQuantityCtrl.text.trim().isEmpty ||
                  price <= 0) {
                _showSnack(
                  context,
                  'Vui lòng nhập tên thuốc, số lượng và đơn giá lớn hơn 0.',
                  color: Colors.orange,
                );
                return;
              }
              final newMed = MedicineItem(
                name: _medNameCtrl.text.trim(),
                category: 'Thuốc điều trị',
                dosage: _medDosageCtrl.text.trim(),
                quantity: _medQuantityCtrl.text.trim(),
                instruction: _medInstructionCtrl.text.trim(),
                price: price,
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
              _showSnack(context, 'Đã thêm ${newMed.name} vào đơn thuốc nháp.');
            },
            child: const Text('Thêm vào đơn'),
          ),
        ],
      ),
    );
  }

  int _medicineTotal(MedicineItem medicine) {
    final quantity =
        int.tryParse(
          RegExp(r'\d+').firstMatch(medicine.quantity)?.group(0) ?? '',
        ) ??
        1;
    return medicine.price * quantity;
  }
}

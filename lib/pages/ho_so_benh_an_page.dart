import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../routes/app_routes.dart';
import '../state/app_settings_store.dart';
import '../state/medical_store.dart';

class PatientRecordsPage extends StatefulWidget {
  const PatientRecordsPage({super.key});

  @override
  State<PatientRecordsPage> createState() => _PatientRecordsPageState();
}

class _PatientRecordsPageState extends State<PatientRecordsPage> {
  int selectedTab = 0;
  List<Map<String, Object?>> _clinicalActions = const [];
  bool _clinicalActionsLoading = false;
  final tabs = const [
    'Lịch sử khám',
    'Xét nghiệm gần nhất',
    'Xu hướng Xét nghiệm (Trends)',
    'X-Quang / Nội soi',
    'Đơn thuốc',
    'Dữ liệu bác sĩ',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MedicalScope.of(context).refreshClinicalDataFromBackend();
      _loadClinicalActions();
    });
  }

  Future<void> _loadClinicalActions() async {
    final store = MedicalScope.of(context);
    if (!store.hasBackendSession) return;
    setState(() => _clinicalActionsLoading = true);
    try {
      final actions = await store.fetchClinicalActionsOnline();
      if (!mounted) return;
      setState(() => _clinicalActions = actions);
    } catch (_) {
      // Bệnh nhân vẫn xem được EMR nếu endpoint thao tác lâm sàng tạm thời lỗi.
    } finally {
      if (mounted) setState(() => _clinicalActionsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final settings = AppSettingsScope.of(context);
    final activeMember = store.activeFamilyMember;
    final isSelf =
        activeMember.relation == FamilyRelation.self ||
        activeMember.id == store.profile.id;
    final profile = isSelf
        ? store.profile
        : PatientProfile(
            id: activeMember.id,
            name: activeMember.name,
            gender: activeMember.gender,
            dateOfBirth: activeMember.dateOfBirth,
            phone: activeMember.phone.isNotEmpty
                ? activeMember.phone
                : store.profile.phone,
            email: store.profile.email,
            address: store.profile.address,
            insuranceNumber: activeMember.insuranceNumber,
            bloodType: activeMember.bloodType,
            allergies: activeMember.allergies,
          );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Hồ sơ bệnh án điện tử (EMR)'),
        actions: [
          IconButton(
            tooltip: 'Lịch sử khám',
            icon: const Icon(Icons.history_edu_outlined),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.visitHistory),
          ),
          IconButton(
            tooltip: 'Xuất PDF có chữ ký số',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => _showPdfExportDialog(context, profile),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
        children: [
          _patientHeader(profile, settings),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) => ChoiceChip(
                label: Text(tabs[index]),
                selected: selectedTab == index,
                onSelected: (_) {
                  if (index == 4) {
                    Navigator.pushNamed(context, AppRoutes.prescription);
                  } else {
                    setState(() => selectedTab = index);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (selectedTab == 0)
            _history(
              store.medicalRecords.where((r) {
                if (isSelf) {
                  return r.patientId == null ||
                      r.patientId == store.profile.id ||
                      r.patientId == activeMember.id;
                }
                return r.patientId == activeMember.id;
              }).toList(),
            )
          else if (selectedTab == 1)
            _labResults(store.labTests)
          else if (selectedTab == 2)
            _labTrendsSection(store.labTrends)
          else if (selectedTab == 3)
            _imagingResults(store.imagingResults)
          else if (selectedTab == 5)
            _clinicalActionsView(),
          const SizedBox(height: 16),
          _securityBanner(),
          const SizedBox(height: 12),
          _aiSummaryBanner(),
        ],
      ),
    );
  }

  Widget _clinicalActionsView() {
    if (_clinicalActionsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_clinicalActions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Chưa có chỉ định hoặc ghi chú chuyên khoa mới từ bác sĩ.',
          ),
        ),
      );
    }
    return Column(
      children: _clinicalActions
          .map((item) {
            final payload = item['payload'];
            final payloadText = payload is Map
                ? payload.entries
                      .map((entry) => '${entry.key}: ${entry.value}')
                      .join('\n')
                : payload?.toString() ?? '';
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2FE),
                  child: Icon(
                    Icons.medical_information_outlined,
                    color: Color(0xFF0057CD),
                  ),
                ),
                title: Text(
                  item['action']?.toString() ?? 'Thao tác bác sĩ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('$payloadText\n${item['createdAt'] ?? ''}'),
                isThreeLine: true,
                trailing: Text(item['status']?.toString() ?? 'completed'),
              ),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _patientHeader(
    PatientProfile profile,
    AppSettingsStore settings,
  ) => Card(
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFFDAE2FF),
                child: Icon(Icons.person, size: 30, color: Color(0xFF0057CD)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: Color(0xFF006C49),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mã BN: ${profile.id} • ${profile.gender}${_formatAge(profile.dateOfBirth)}',
                      style: const TextStyle(
                        color: Color(0xFF0057CD),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      profile.address,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showPatientQrDialog(profile),
                tooltip: 'Mã QR tiếp đón',
                icon: const Icon(
                  Icons.qr_code_2,
                  size: 28,
                  color: Color(0xFF0057CD),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _highlight(
                  'Nhóm máu',
                  profile.bloodType,
                  Icons.bloodtype,
                  const Color(0xFFFFEBEE),
                  const Color(0xFFC62828),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _highlight(
                  'Thẻ BHYT',
                  settings.maskText(
                    profile.insuranceNumber,
                    visiblePrefix: 4,
                    visibleSuffix: 3,
                  ),
                  Icons.verified_user,
                  const Color(0xFFE8F5E9),
                  const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _highlight(
                  'Dị ứng',
                  profile.allergies,
                  Icons.warning_amber,
                  const Color(0xFFFFF3E0),
                  const Color(0xFFE65100),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _highlight(
    String label,
    String value,
    IconData icon,
    Color color,
    Color textColor,
  ) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: textColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _history(List<MedicalRecord> records) {
    final groups = <String, List<MedicalRecord>>{};
    for (final record in records) {
      final key = record.appointmentId?.isNotEmpty == true
          ? record.appointmentId!
          : record.date.length >= 10
          ? record.date.substring(0, 10)
          : record.date;
      groups.putIfAbsent(key, () => <MedicalRecord>[]).add(record);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'Các đợt khám bệnh gần đây',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Chip(
              label: Text('${records.length} đợt khám'),
              backgroundColor: const Color(0xFFE2E7FF),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (records.isEmpty)
          _emptyRecordsState()
        else ...[
          for (final group in groups.entries) ...[
            _visitGroupHeader(group.value.first),
            ...group.value.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _recordCard(item),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _visitGroupHeader(MedicalRecord record) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 8),
    child: Row(
      children: [
        const Icon(
          Icons.event_note_outlined,
          size: 18,
          color: Color(0xFF0057CD),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'CA KHÁM • ${_displayDate(record.date)}',
            style: const TextStyle(
              color: Color(0xFF0057CD),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        if (record.appointmentId != null)
          Text(
            record.appointmentId!,
            style: const TextStyle(fontSize: 10, color: Colors.black45),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    ),
  );

  Widget _emptyRecordsState() => Card(
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.folder_open_outlined,
            size: 44,
            color: Color(0xFF64748B),
          ),
          const SizedBox(height: 10),
          const Text(
            'Chưa có hồ sơ bệnh án',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Hồ sơ chỉ được tạo sau khi bạn có lịch hẹn, bác sĩ hoàn tất ca khám và ký số EMR.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.appointments),
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Đặt lịch khám'),
          ),
        ],
      ),
    ),
  );

  Widget _recordCard(MedicalRecord record) => Card(
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.department.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF0057CD),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.diagnosis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ngày khám: ${_displayDate(record.date)} • Mã: ${record.id}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Chip(
                label: Text('Đã hoàn thành', style: TextStyle(fontSize: 11)),
                backgroundColor: Color(0xFFE8F5E9),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              const Icon(
                Icons.person_pin_circle_outlined,
                size: 18,
                color: Color(0xFF0057CD),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bác sĩ điều trị: ${record.doctorName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  'ICD-10: ${record.diagnosisCode}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• Bệnh học ICD-10: ${record.icd10Name}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Triệu chứng: ${record.symptoms}',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Khám thực thể: ${record.physicalExamNotes}',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                if (record.differentialDiagnosis != null &&
                    record.differentialDiagnosis!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '• Chẩn đoán phân biệt: ${record.differentialDiagnosis}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4338CA),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (record.labSummary != null &&
                    record.labSummary!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '• Xét nghiệm / Cận lâm sàng: ${record.labSummary}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7E22CE),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (record.xrayFindings != null &&
                    record.xrayFindings!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '• Chẩn đoán hình ảnh: ${record.xrayFindings}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFC2410C),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (record.prescribedMedicinesSummary != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '• Thuốc kê đơn: ${record.prescribedMedicinesSummary}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.teal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '• Lời dặn Bác sĩ: ${record.doctorInstructions}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF0369A1),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Tái khám: ${record.followUpDate} • Mã toa: ${record.prescriptionCode}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0057CD),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Huy hiệu ký số SHA-256 EMR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ký số EMR: ${record.digitalSignatureToken}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.prescriptionDetail,
                    arguments: record.appointmentId,
                  ),
                  icon: const Icon(Icons.medication_outlined, size: 16),
                  label: const Text(
                    'Xem đơn thuốc',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => selectedTab = 1),
                  icon: const Icon(Icons.science_outlined, size: 16),
                  label: const Text(
                    'Xem xét nghiệm',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _labResults(List<LabTestItem> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              'Chỉ số sinh hóa máu & Xét nghiệm',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            items.isEmpty ? 'Chưa có kết quả' : 'Kết quả mới nhất',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (items.isEmpty)
        _emptyClinicalDataCard(
          icon: Icons.science_outlined,
          title: 'Chưa có kết quả xét nghiệm',
          message: 'Kết quả xét nghiệm chỉ xuất hiện sau khi bác sĩ chỉ định và phòng xét nghiệm trả kết quả.',
        )
      else
        Card(
          elevation: 1,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: const Color(0xFFF1F5F9),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        'TÊN CHỈ SỐ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'KẾT QUẢ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'THAM CHIẾU',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              for (final test in items) ...[
                InkWell(
                  onTap: () => _showLabDetail(context, test),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            test.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: test.isAbnormal
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: test.isAbnormal
                                  ? Colors.red
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Text(
                                test.value,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: test.isAbnormal
                                      ? Colors.red
                                      : const Color(0xFF006C49),
                                ),
                              ),
                              if (test.isAbnormal) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_upward,
                                  size: 14,
                                  color: Colors.red,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '${test.normalRange} ${test.unit}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
              ],
            ],
          ),
        ),
    ],
  );

  Widget _imagingResults(List<Map<String, Object?>> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Chẩn đoán hình ảnh & Thăm dò chức năng',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      if (items.isEmpty)
        _emptyClinicalDataCard(
          icon: Icons.image_search_outlined,
          title: 'Chưa có kết quả chẩn đoán hình ảnh',
          message: 'Ảnh X-quang, siêu âm, nội soi hoặc PACS chỉ hiển thị sau khi bác sĩ chỉ định và khoa cận lâm sàng trả kết quả.',
        )
      else
        ...items.map((item) {
          final encoded = item['imageBase64']?.toString() ?? '';
          Widget leading = const CircleAvatar(
            backgroundColor: Color(0xFFE0F2FE),
            child: Icon(Icons.image_search_outlined, color: Color(0xFF0369A1)),
          );
          if (encoded.isNotEmpty) {
            try {
              leading = ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  base64Decode(encoded),
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                ),
              );
            } catch (_) {
              // Giữ biểu tượng mặc định nếu tệp cũ không còn hợp lệ.
            }
          }
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              onTap: () => _showImagingDetail(context, item),
              leading: leading,
              title: Text(
                item['modality']?.toString() ?? 'Chẩn đoán hình ảnh',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                '${item['status'] ?? ''}\n${item['findings'] ?? ''}',
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              isThreeLine: true,
            ),
          );
        }),
    ],
  );

  void _showLabDetail(BuildContext context, LabTestItem test) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.science_outlined, color: Color(0xFF0369A1)),
            const SizedBox(width: 8),
            Expanded(child: Text(test.name)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Kết quả', '${test.value} ${test.unit}'),
              _detailRow('Khoảng tham chiếu', test.normalRange),
              _detailRow(
                'Đánh giá',
                test.isAbnormal
                    ? 'Bất thường – cần bác sĩ theo dõi'
                    : 'Trong giới hạn bình thường',
              ),
              if (test.note != null && test.note!.trim().isNotEmpty)
                _detailRow('Nhận xét bác sĩ/xét nghiệm', test.note!),
              const SizedBox(height: 8),
              const Text(
                'Dữ liệu được chuyển từ kết quả cận lâm sàng của ca khám. Không tự thay đổi thuốc hoặc chẩn đoán nếu chưa trao đổi với bác sĩ.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showImagingDetail(BuildContext context, Map<String, Object?> item) {
    final encoded = item['imageBase64']?.toString() ?? '';
    Widget? image;
    if (encoded.isNotEmpty) {
      try {
        image = Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(base64Decode(encoded), fit: BoxFit.contain),
          ),
        );
      } catch (_) {}
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item['modality']?.toString() ?? 'Kết quả cận lâm sàng'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (image != null) image,
              _detailRow('Trạng thái', item['status']?.toString() ?? ''),
              _detailRow(
                'Kết luận/nhận xét',
                item['findings']?.toString() ?? '',
              ),
              if ((item['fileName']?.toString() ?? '').isNotEmpty)
                _detailRow('Tệp đính kèm', item['fileName']!.toString()),
              if (item['createdAt'] is DateTime)
                _detailRow(
                  'Thời gian',
                  _formatDateTime(item['createdAt'] as DateTime),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? 'Chưa có dữ liệu' : value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  String _displayDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final value = parsed.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} ${two(value.hour)}:${two(value.minute)}';
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }

  Widget _emptyClinicalDataCard({
    required IconData icon,
    required String title,
    required String message,
  }) => Card(
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(icon, size: 42, color: const Color(0xFF64748B)),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _labTrendsSection(List<LabTrendPoint> points) {
    final glucose = points.where((p) => p.bloodGlucose > 0).toList();
    final alt = points.where((p) => p.alt > 0).toList();
    final cholesterol = points.where((p) => p.cholesterolTotal > 0).toList();
    if (glucose.length < 2 && alt.length < 2 && cholesterol.length < 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Xu hướng Chỉ số Xét nghiệm',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _emptyClinicalDataCard(
            icon: Icons.trending_up_outlined,
            title: 'Chưa đủ dữ liệu xu hướng',
            message: 'Biểu đồ xu hướng cần ít nhất 2 lần xét nghiệm hợp lệ sau các đợt khám.',
          ),
        ],
      );
    }

    final cards = <Widget>[];
    if (glucose.length >= 2) {
      cards.add(
        _trendMetricCard(
          title: 'Đường huyết đói (Glucose)',
          unit: 'mg/dL',
          normalRange: '70 - 99 mg/dL',
          currentVal: glucose.last.bloodGlucose,
          initialVal: glucose.first.bloodGlucose,
          points: glucose.map((p) => p.bloodGlucose).toList(),
          dates: glucose.map((p) => p.dateStr).toList(),
          color: const Color(0xFF0057CD),
          isImproving: true,
          statusNote: 'Theo dõi diễn biến qua các kết quả đã có.',
        ),
      );
    }
    if (alt.length >= 2) {
      cards.add(
        _trendMetricCard(
          title: 'Men gan (ALT / SGPT)',
          unit: 'U/L',
          normalRange: '< 40 U/L',
          currentVal: alt.last.alt,
          initialVal: alt.first.alt,
          points: alt.map((p) => p.alt).toList(),
          dates: alt.map((p) => p.dateStr).toList(),
          color: const Color(0xFF10B981),
          isImproving: true,
          statusNote: 'Theo dõi diễn biến qua các kết quả đã có.',
        ),
      );
    }
    if (cholesterol.length >= 2) {
      cards.add(
        _trendMetricCard(
          title: 'Cholesterol toàn phần',
          unit: 'mmol/L',
          normalRange: '< 5.2 mmol/L',
          currentVal: cholesterol.last.cholesterolTotal,
          initialVal: cholesterol.first.cholesterolTotal,
          points: cholesterol.map((p) => p.cholesterolTotal).toList(),
          dates: cholesterol.map((p) => p.dateStr).toList(),
          color: const Color(0xFFF59E0B),
          isImproving: true,
          statusNote: 'Theo dõi diễn biến qua các kết quả đã có.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Xu hướng Chỉ số Xét nghiệm (${points.length} lần ghi nhận)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Chuẩn ADA & EASL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...cards.expand((card) => [card, const SizedBox(height: 14)]),
      ],
    );
  }

  Widget _trendMetricCard({
    required String title,
    required String unit,
    required String normalRange,
    required double currentVal,
    required double initialVal,
    required List<double> points,
    required List<String> dates,
    required Color color,
    required bool isImproving,
    required String statusNote,
  }) {
    return Card(
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Ngưỡng an toàn: $normalRange',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      isImproving
                          ? Icons.trending_down_rounded
                          : Icons.trending_up_rounded,
                      color: isImproving
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$currentVal $unit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 18),

            // Visual Timeline Points Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(points.length, (i) {
                final isLast = i == points.length - 1;
                return Column(
                  children: [
                    Text(
                      '${points[i]}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isLast
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isLast ? color : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: isLast ? 14 : 10,
                      height: isLast ? 14 : 10,
                      decoration: BoxDecoration(
                        color: isLast ? color : color.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: isLast
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dates[i],
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      statusNote,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPdfExportDialog(BuildContext context, PatientProfile profile) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.picture_as_pdf, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Trích sao Bệnh án Điện tử'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hồ sơ bệnh nhân: ${profile.name} • Mã ${profile.id}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tổ chức cấp: Bệnh viện Đa khoa Quốc tế MedCare\nChuẩn định dạng: HL7 CDA Release 2 / Bộ Y Tế',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0057CD).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    color: Color(0xFF0057CD),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tài liệu đính kèm chữ ký số điện tử PKI & Mã QR xác thực 30 ngày.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF0057CD),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Đã tải xuống file: Benh_an_MedCare_${profile.id}.pdf',
                  ),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Tải file PDF'),
          ),
        ],
      ),
    );
  }

  Widget _securityBanner() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFE2E7FF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      children: [
        Icon(Icons.shield_outlined, color: Color(0xFF0057CD)),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Hồ sơ bệnh án được bảo mật 2 lớp theo tiêu chuẩn HIPAA & Nghị định 13/2023/NĐ-CP của Bộ Y Tế.',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF0057CD),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _aiSummaryBanner() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF3E8FF),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFD8B4FE)),
    ),
    child: const Row(
      children: [
        Icon(Icons.auto_awesome, color: Color(0xFF9333EA)),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Tóm tắt thông minh AI: Tình trạng dạ dày đang đáp ứng tốt với phác đồ Hp. Bạn nhớ uống thuốc đúng giờ và kiêng đồ cay nóng.',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF6B21A8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  void _showPatientQrDialog(PatientProfile profile) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mã QR Bệnh nhân'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: const Icon(
                Icons.qr_code_2,
                size: 140,
                color: Color(0xFF0057CD),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              profile.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text('Mã BN: ${profile.id} • BHYT: ${profile.insuranceNumber}'),
            const SizedBox(height: 6),
            const Text(
              'Xuất trình mã này tại Kiosk hoặc Quầy tiếp đón để lấy số thứ tự tự động.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  static String _formatAge(String dob) {
    if (dob.isEmpty) return '';
    final parts = dob.split('/');
    if (parts.length == 3) {
      final y = int.tryParse(parts[2]);
      if (y != null && y > 1900 && y <= DateTime.now().year) {
        return ' • ${DateTime.now().year - y} tuổi';
      }
    }
    final dashParts = dob.split('-');
    if (dashParts.length == 3) {
      final y = int.tryParse(dashParts[0]);
      if (y != null && y > 1900 && y <= DateTime.now().year) {
        return ' • ${DateTime.now().year - y} tuổi';
      }
    }
    return '';
  }
}

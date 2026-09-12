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
  final tabs = const [
    'Lịch sử khám',
    'Xét nghiệm gần nhất',
    'Xu hướng Xét nghiệm (Trends)',
    'X-Quang / Nội soi',
    'Đơn thuốc',
  ];

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final settings = AppSettingsScope.of(context);
    final profile = store.profile;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Hồ sơ bệnh án điện tử (EMR)'),
        actions: [
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
            _history(store.medicalRecords)
          else if (selectedTab == 1)
            _labResults(store.labTests)
          else if (selectedTab == 2)
            _labTrendsSection(store.labTrends)
          else if (selectedTab == 3)
            _imagingResults(),
          const SizedBox(height: 16),
          _securityBanner(),
          const SizedBox(height: 12),
          _aiSummaryBanner(),
        ],
      ),
    );
  }

  Widget _patientHeader(PatientProfile profile, AppSettingsStore settings) => Card(
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
                        Text(
                          profile.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, size: 16, color: Color(0xFF006C49)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mã BN: ${profile.id} • ${profile.gender} • 24 tuổi',
                      style: const TextStyle(color: Color(0xFF0057CD), fontSize: 12, fontWeight: FontWeight.w600),
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
                icon: const Icon(Icons.qr_code_2, size: 28, color: Color(0xFF0057CD)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _highlight('Nhóm máu', profile.bloodType, Icons.bloodtype, const Color(0xFFFFEBEE), const Color(0xFFC62828))),
              const SizedBox(width: 8),
              Expanded(
                child: _highlight(
                  'Thẻ BHYT',
                  settings.maskText(profile.insuranceNumber, visiblePrefix: 4, visibleSuffix: 3),
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

  Widget _history(List<MedicalRecord> records) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
      for (final item in records) ...[
        _recordCard(item),
        const SizedBox(height: 14),
      ],
    ],
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
                      'Ngày khám: ${record.date} • Mã: ${record.id}',
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
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
              const Icon(Icons.person_pin_circle_outlined, size: 18, color: Color(0xFF0057CD)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bác sĩ điều trị: ${record.doctorName}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• Triệu chứng: ${record.symptoms}',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Hướng điều trị: ${record.treatmentPlan}',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Tái khám: ${record.followUpDate} • Mã toa: ${record.prescriptionCode}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0057CD)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.prescription),
                  icon: const Icon(Icons.medication_outlined, size: 16),
                  label: const Text('Xem đơn thuốc', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => selectedTab = 1),
                  icon: const Icon(Icons.science_outlined, size: 16),
                  label: const Text('Xem xét nghiệm', style: TextStyle(fontSize: 12)),
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
          const Text(
            'Chỉ số sinh hóa máu & Xét nghiệm',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          Text(
            'Lần đo: 10/02/2026',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Card(
        elevation: 1,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFF1F5F9),
              child: const Row(
                children: [
                  Expanded(flex: 4, child: Text('TÊN CHỈ SỐ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  Expanded(flex: 3, child: Text('KẾT QUẢ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  Expanded(flex: 3, child: Text('THAM CHIẾU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                ],
              ),
            ),
            for (final test in items) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        test.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: test.isAbnormal ? FontWeight.bold : FontWeight.normal,
                          color: test.isAbnormal ? Colors.red : Colors.black87,
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
                              color: test.isAbnormal ? Colors.red : const Color(0xFF006C49),
                            ),
                          ),
                          if (test.isAbnormal) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_upward, size: 14, color: Colors.red),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${test.normalRange} ${test.unit}',
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
          ],
        ),
      ),
    ],
  );

  Widget _imagingResults() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Chẩn đoán hình ảnh & Thăm dò chức năng',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.monitor_heart_outlined, color: Color(0xFF0057CD)),
                  SizedBox(width: 8),
                  Text('Nội soi Dạ dày - Tá tràng không đau', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Thời gian thực hiện: 10/02/2026 09:15 • BS. Nguyễn Văn An'),
              const Divider(height: 20),
              const Text(
                '• Niêm mạc thực quản bình thường, không trào ngược độ nặng.\n• Niêm mạc hang vị dạ dày phù nề, sung huyết lan tỏa, có vài trợt nông đáy sạch.\n• Môn vị tròn đều, co bóp tốt.\n• Hành tá tràng và tá tràng bình thường.\n• Test vi khuẩn Helicobacter Pylori (CLO-Test): DƯƠNG TÍNH (+).',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.camera_alt_outlined, color: Color(0xFF0057CD)),
                  SizedBox(width: 8),
                  Text('X-Quang Tim Phổi thẳng (Kỹ thuật số)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Thời gian thực hiện: 10/02/2026 08:30 • Khoa CĐHA'),
              const SizedBox(height: 12),

              // Interactive DICOM Viewer simulation
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.broken_image_rounded, size: 70, color: Colors.white30),
                    Positioned(
                      top: 8,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('DICOM 1024×1024 • 12-bit Greyscale', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 10,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                            child: const Row(
                              children: [
                                Icon(Icons.zoom_in, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text('Zoom 1.5x', style: TextStyle(color: Colors.white, fontSize: 11)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                            child: const Row(
                              children: [
                                Icon(Icons.contrast, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text('Âm bản', style: TextStyle(color: Colors.white, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 20),
              const Text(
                '• Trường phổi hai bên sáng đều, không thấy tổn thương khu trú dạng thâm nhiễm hay nốt mờ.\n• Rốn phổi hai bên bình thường.\n• Chỉ số tim ngực trong giới hạn bình thường (< 0.5).\n• Góc tâm hoành và sườn hoành hai bên sáng nhọn.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _labTrendsSection(List<LabTrendPoint> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Xu hướng Chỉ số Xét nghiệm (5 lần khám)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Chuẩn ADA & EASL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Đường huyết Glucose
        _trendMetricCard(
          title: 'Đường huyết đói (Glucose)',
          unit: 'mg/dL',
          normalRange: '70 - 99 mg/dL',
          currentVal: points.last.bloodGlucose,
          initialVal: points.first.bloodGlucose,
          points: points.map((p) => p.bloodGlucose).toList(),
          dates: points.map((p) => p.dateStr).toList(),
          color: const Color(0xFF0057CD),
          isImproving: true,
          statusNote: 'Đã giảm từ 118 xuống 94 mg/dL (Trở về mức bình thường tối ưu).',
        ),
        const SizedBox(height: 14),

        // Men gan ALT
        _trendMetricCard(
          title: 'Men gan (ALT / SGPT)',
          unit: 'U/L',
          normalRange: '< 40 U/L',
          currentVal: points.last.alt,
          initialVal: points.first.alt,
          points: points.map((p) => p.alt).toList(),
          dates: points.map((p) => p.dateStr).toList(),
          color: const Color(0xFF10B981),
          isImproving: true,
          statusNote: 'Hạ từ 48 U/L xuống 28 U/L, tế bào gan hồi phục tốt.',
        ),
        const SizedBox(height: 14),

        // Cholesterol
        _trendMetricCard(
          title: 'Cholesterol toàn phần',
          unit: 'mmol/L',
          normalRange: '< 5.2 mmol/L',
          currentVal: points.last.cholesterolTotal,
          initialVal: points.first.cholesterolTotal,
          points: points.map((p) => p.cholesterolTotal).toList(),
          dates: points.map((p) => p.dateStr).toList(),
          color: const Color(0xFFF59E0B),
          isImproving: true,
          statusNote: 'Giảm từ 5.8 xuống 4.6 mmol/L, mỡ máu an toàn.',
        ),
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
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('Ngưỡng an toàn: $normalRange', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      isImproving ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                      color: isImproving ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$currentVal $unit',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
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
                        fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
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
                        border: isLast ? Border.all(color: Colors.white, width: 2) : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(dates[i], style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
                  const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      statusNote,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF065F46)),
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
            Text('Hồ sơ bệnh nhân: ${profile.name} • Mã ${profile.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Tổ chức cấp: Bệnh viện Đa khoa Quốc tế MedCare\nChuẩn định dạng: HL7 CDA Release 2 / Bộ Y Tế'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0057CD).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: Color(0xFF0057CD), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tài liệu đính kèm chữ ký số điện tử PKI & Mã QR xác thực 30 ngày.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF0057CD)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã tải xuống file: Benh_an_MedCare_MC-89241.pdf'),
                  backgroundColor: Color(0xFF10B981),
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
            style: TextStyle(fontSize: 11, color: Color(0xFF0057CD), fontWeight: FontWeight.w600),
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
            style: TextStyle(fontSize: 11, color: Color(0xFF6B21A8), fontWeight: FontWeight.w600),
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
              child: const Icon(Icons.qr_code_2, size: 140, color: Color(0xFF0057CD)),
            ),
            const SizedBox(height: 12),
            Text(profile.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
}

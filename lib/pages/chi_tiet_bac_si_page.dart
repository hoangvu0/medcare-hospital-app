import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../routes/app_routes.dart';
import '../state/medical_store.dart';
import '../widgets/doctor_avatar.dart';
import '../widgets/medcare_brand_title.dart';

class DoctorInfo {
  const DoctorInfo({
    required this.name,
    required this.specialty,
    required this.experience,
    required this.rating,
    required this.price,
  });

  final String name;
  final String specialty;
  final String experience;
  final String rating;
  final String price;
}

class DoctorDetailPage extends StatelessWidget {
  const DoctorDetailPage({super.key, this.doctor, this.legacyDoctor});

  final DoctorProfile? doctor;
  final DoctorInfo? legacyDoctor;

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final routeDoctor = ModalRoute.of(context)?.settings.arguments;

    DoctorProfile effectiveDoctor;
    if (doctor != null) {
      effectiveDoctor = doctor!;
    } else if (routeDoctor is DoctorProfile) {
      effectiveDoctor = routeDoctor;
    } else if (legacyDoctor != null) {
      effectiveDoctor = DoctorProfile(
        id: legacyDoctor!.name,
        name: legacyDoctor!.name,
        specialty: legacyDoctor!.specialty,
        experience: legacyDoctor!.experience,
        rating: double.tryParse(legacyDoctor!.rating) ?? 4.9,
        price:
            int.tryParse(
              legacyDoctor!.price.replaceAll(RegExp(r'[^0-9]'), ''),
            ) ??
            350000,
        location: 'Tòa nhà Khám bệnh Kỹ thuật cao',
        availability: 'Đang tiếp nhận lịch hẹn',
      );
    } else {
      effectiveDoctor = store.doctors.first;
    }

    final doc = effectiveDoctor;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        title: const MedCareBrandTitle(pageTitle: 'Hồ sơ bác sĩ'),
        actions: [
          IconButton(
            tooltip: 'Chia sẻ thông tin',
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã sao chép liên kết thông tin ${doc.name}'),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  DoctorAvatar(doctor: doc, size: 84, borderRadius: 24),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E7FF),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'Khoa ${doc.specialty}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0057CD),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    doc.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doc.education,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 18,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceAround,
                    children: [
                      _MetricItem(
                        icon: Icons.star,
                        iconColor: const Color(0xFFFFA000),
                        title: doc.rating.toStringAsFixed(1),
                        subtitle: 'Đánh giá',
                      ),
                      _MetricItem(
                        icon: Icons.people_outline,
                        iconColor: const Color(0xFF006C49),
                        title: doc.totalPatients,
                        subtitle: 'Lượt khám',
                      ),
                      const _MetricItem(
                        icon: Icons.verified_outlined,
                        iconColor: Color(0xFF0057CD),
                        title: 'Chính quy',
                        subtitle: 'Chứng chỉ',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin phòng khám & Giờ làm việc',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Địa điểm',
                    value: doc.location,
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Lịch khám',
                    value: doc.workingDays,
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon: Icons.access_time_outlined,
                    label: 'Tình trạng',
                    value: doc.availability,
                    valueColor: const Color(0xFF006C49),
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon: Icons.payments_outlined,
                    label: 'Phí tư vấn',
                    value: '${doc.price ~/ 1000}.000đ (Áp dụng BHYT)',
                    valueColor: const Color(0xFF0057CD),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quá trình công tác & Đào tạo',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '• ${doc.experience}\n• ${doc.education}\n• Giảng viên kiêm nhiệm tại các trường Đại học Y khoa.\n• Bác sĩ chủ trì nhiều phác đồ điều trị kỹ thuật cao.',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Giá khám niêm yết',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  Text(
                    '${doc.price ~/ 1000}.000đ',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0057CD),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.appointments,
                    arguments: doc,
                  ),
                  icon: const Icon(Icons.calendar_month),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Đặt lịch khám ngay'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      const SizedBox(height: 2),
      Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: Colors.black54),
      ),
    ],
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: const Color(0xFF0057CD)),
      const SizedBox(width: 10),
      SizedBox(
        width: 80,
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
      ),
      Expanded(
        child: Text(
          value,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ),
    ],
  );
}

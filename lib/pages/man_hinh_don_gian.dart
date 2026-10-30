import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../routes/app_routes.dart';
import '../state/medical_store.dart';

class SpecialtyPage extends StatelessWidget {
  const SpecialtyPage({super.key, required this.specialty});
  final String specialty;

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final doctors = store.doctors
        .where((doctor) => doctor.specialty == specialty)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text('Chuyên khoa $specialty')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  specialty,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0057CD),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  doctors.isEmpty
                      ? 'Chưa có bác sĩ đang nhận lịch ở chuyên khoa này.'
                      : '${doctors.length} bác sĩ đang nhận lịch, có học vị và kinh nghiệm rõ ràng.',
                  style: const TextStyle(fontSize: 13, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bác sĩ & thành tích',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (doctors.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Vui lòng chọn chuyên khoa khác hoặc quay lại sau.',
                ),
              ),
            )
          else
            ...doctors.map((doctor) => _SpecialtyDoctorCard(doctor: doctor)),
        ],
      ),
    );
  }
}

class _SpecialtyDoctorCard extends StatelessWidget {
  const _SpecialtyDoctorCard({required this.doctor});

  final DoctorProfile doctor;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.doctorDetail,
        arguments: doctor,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE7F0FF),
                  child: Icon(Icons.person, color: Color(0xFF0057CD)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        doctor.education,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0057CD),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              doctor.experience,
              style: const TextStyle(fontSize: 12.5, height: 1.35),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Badge(
                  icon: Icons.star_rounded,
                  text: '${doctor.rating.toStringAsFixed(1)} đánh giá',
                ),
                _Badge(
                  icon: Icons.groups_outlined,
                  text: '${doctor.totalPatients} lượt khám',
                ),
                _Badge(icon: Icons.place_outlined, text: doctor.location),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${doctor.price ~/ 1000}.000đ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0057CD),
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.appointments,
                    arguments: doctor,
                  ),
                  icon: const Icon(Icons.calendar_month, size: 16),
                  label: const Text('Đặt lịch'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF0057CD)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11)),
      ],
    ),
  );
}

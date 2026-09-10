import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../routes/app_routes.dart';

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
  const DoctorDetailPage({super.key, required this.doctor});

  final DoctorInfo doctor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin bác sĩ')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 42,
              backgroundColor: Color(0xFFE0E9FF),
              child: Icon(Icons.person, size: 48, color: Color(0xFF0057CD)),
            ),
            const SizedBox(height: 18),
            Text(
              doctor.name,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              doctor.specialty,
              style: const TextStyle(color: Color(0xFF0057CD), fontSize: 16),
            ),
            const SizedBox(height: 18),
            _InfoRow(label: 'Kinh nghiệm', value: doctor.experience),
            _InfoRow(label: 'Đánh giá', value: '${doctor.rating} / 5.0'),
            _InfoRow(label: 'Phí tư vấn', value: doctor.price),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.appointments,
                  arguments: DoctorProfile(
                    id: doctor.name,
                    name: doctor.name,
                    specialty: doctor.specialty,
                    experience: doctor.experience,
                    rating: double.tryParse(doctor.rating) ?? 0,
                    price:
                        int.tryParse(
                          doctor.price.replaceAll(RegExp(r'[^0-9]'), ''),
                        ) ??
                        0,
                    location: 'Phòng khám MedCare',
                    availability: 'Đang cập nhật',
                  ),
                ),
                icon: const Icon(Icons.calendar_month),
                label: const Text('Đặt lịch với bác sĩ này'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

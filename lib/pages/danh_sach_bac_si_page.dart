import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../routes/app_routes.dart';
import '../state/medical_store.dart';
import '../widgets/doctor_avatar.dart';
import '../widgets/medcare_brand_title.dart';

class DoctorsPage extends StatefulWidget {
  const DoctorsPage({super.key});

  @override
  State<DoctorsPage> createState() => _DoctorsPageState();
}

class _DoctorsPageState extends State<DoctorsPage> {
  int selectedCategory = 0;
  int selectedRank = 0;
  String query = '';

  final categories = const [
    'Tất cả',
    'Tiêu hóa',
    'Tim mạch',
    'Nhi khoa',
    'Cơ xương khớp',
    'Da liễu',
    'Mắt',
    'Tai Mũi Họng',
    'Thần kinh',
    'Sản phụ khoa',
    'Răng Hàm Mặt',
    'Ung bướu & Xạ trị',
    'Hô hấp & Phổi',
  ];

  final rankFilters = const [
    'Tất cả học vị',
    'Giáo sư (GS)',
    'Phó Giáo sư (PGS)',
    'Tiến sĩ (TS)',
    'BSCKII',
    'Thạc sĩ (ThS)',
  ];

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final doctors = store.doctors;
    final selected = categories[selectedCategory];
    final selectedRankName = rankFilters[selectedRank];

    final visible = doctors.where((doctor) {
      final matchCategory =
          selected == 'Tất cả' ||
          doctor.specialty.toLowerCase().contains(selected.toLowerCase()) ||
          selected.toLowerCase().contains(doctor.specialty.toLowerCase());

      final matchRank =
          selectedRankName == 'Tất cả học vị' ||
          (selectedRankName.contains('GS') && doctor.name.startsWith('GS')) ||
          (selectedRankName.contains('PGS') && doctor.name.startsWith('PGS')) ||
          (selectedRankName.contains('TS') &&
              (doctor.name.startsWith('TS') ||
                  doctor.education.contains('Tiến sĩ'))) ||
          (selectedRankName.contains('BSCKII') &&
              (doctor.name.contains('BSCKII') ||
                  doctor.education.contains('Chuyên khoa II'))) ||
          (selectedRankName.contains('ThS') &&
              (doctor.name.startsWith('ThS') ||
                  doctor.education.contains('Thạc sĩ')));

      final matchQuery =
          doctor.name.toLowerCase().contains(query.toLowerCase()) ||
          doctor.specialty.toLowerCase().contains(query.toLowerCase()) ||
          doctor.experience.toLowerCase().contains(query.toLowerCase());

      return matchCategory && matchRank && matchQuery;
    }).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        titleSpacing: 16,
        title: const MedCareBrandTitle(pageTitle: 'MedCare Hospital'),
        actions: const [MedCareHeaderActions()],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => query = value),
                  decoration: const InputDecoration(
                    hintText: 'Tìm tên bác sĩ, chuyên khoa hoặc học vị...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.verified, size: 14, color: Color(0xFF006C49)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Hơn 120+ chuyên gia đầu ngành & giáo sư y khoa',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => ChoiceChip(
                label: Text(categories[index]),
                selected: selectedCategory == index,
                onSelected: (_) => setState(() => selectedCategory = index),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: rankFilters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) => FilterChip(
                label: Text(
                  rankFilters[index],
                  style: const TextStyle(fontSize: 11),
                ),
                selected: selectedRank == index,
                selectedColor: const Color(0xFFD2E4FF),
                onSelected: (_) => setState(() => selectedRank = index),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              '${visible.length} bác sĩ phù hợp • Sắp xếp: Đánh giá cao nhất',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          ...visible.map(
            (doctor) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: DoctorCard(doctor: doctor),
            ),
          ),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: Text('Không tìm thấy bác sĩ phù hợp.')),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Card(
              color: const Color(0xFFE2E7FF),
              child: ListTile(
                leading: const Icon(
                  Icons.support_agent,
                  color: Color(0xFF0057CD),
                ),
                title: const Text('Chưa rõ triệu chứng?'),
                subtitle: const Text(
                  'Để y tá phân luồng hướng dẫn bác sĩ phù hợp.',
                ),
                trailing: const Text('Tư vấn'),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0057CD),
        unselectedItemColor: const Color(0xFF424655),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            activeIcon: Icon(Icons.medical_services_rounded),
            label: 'Bác sĩ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month_rounded),
            label: 'Lịch hẹn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description_rounded),
            label: 'Bệnh án',
          ),
        ],
        onTap: (index) {
          if (index == 1) return;
          final route = switch (index) {
            0 => AppRoutes.home,
            2 => AppRoutes.appointments,
            3 => AppRoutes.records,
            _ => AppRoutes.home,
          };
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
          } else {
            Navigator.pushNamed(context, route);
          }
        },
      ),
    );
  }
}

class DoctorCard extends StatelessWidget {
  const DoctorCard({super.key, required this.doctor});
  final DoctorProfile doctor;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () =>
        Navigator.pushNamed(context, AppRoutes.doctorDetail, arguments: doctor),
    borderRadius: BorderRadius.circular(16),
    child: Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DoctorAvatar(doctor: doctor),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E7FF),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          doctor.specialty,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0057CD),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctor.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        doctor.experience,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.star, size: 15, color: Color(0xFFFFA000)),
                const SizedBox(width: 4),
                Text(
                  doctor.rating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${doctor.totalPatients} lượt khám)',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.location_on_outlined,
                  size: 13,
                  color: Color(0xFF006591),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    doctor.location,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF006C49),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${doctor.availability} • Lịch: ${doctor.workingDays}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006C49),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Giá tư vấn khám',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    Text(
                      '${doctor.price ~/ 1000}.000đ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0057CD),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.appointments,
                    arguments: doctor,
                  ),
                  icon: const Icon(Icons.calendar_month_outlined, size: 15),
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

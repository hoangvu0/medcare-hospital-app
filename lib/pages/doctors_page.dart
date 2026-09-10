import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../routes/app_routes.dart';

class DoctorsPage extends StatefulWidget {
  const DoctorsPage({super.key});

  @override
  State<DoctorsPage> createState() => _DoctorsPageState();
}

class _DoctorsPageState extends State<DoctorsPage> {
  int selectedCategory = 0;
  String query = '';

  final categories = const [
    'Tất cả',
    'Tim mạch',
    'Cơ xương khớp',
    'Nhi khoa',
    'Thần kinh',
    'Tiêu hóa',
  ];
  final doctors = const [
    Doctor(
      name: 'PGS.TS.BS Trần Minh Đức',
      specialty: 'Tim mạch',
      experience: 'Trưởng khoa Tim mạch • 22 năm kinh nghiệm',
      rating: '4.9',
      visits: '1.240 lượt khám',
      location: 'Phòng 402, Tòa A',
      status: 'Đang có lịch hôm nay',
      time: 'Sáng 09:00 - 11:30',
      price: '450.000',
      statusColor: Color(0xFF006C49),
      imageUrl: 'https://www.figma.com/api/mcp/asset/97d2028b-d23e-46f7-b70f-e61ddde015b1.png',
    ),
    Doctor(
      name: 'ThS.BS Lê Thu Trang',
      specialty: 'Nhi khoa',
      experience: 'Chuyên khoa Nhi • 14 năm kinh nghiệm',
      rating: '5.0',
      visits: '890 lượt khám',
      location: 'Khu Nhi, Tòa B',
      status: 'Còn 3 khung giờ',
      time: 'Chiều nay: 14:00, 15:30, 16:15',
      price: '350.000',
      statusColor: Color(0xFF006591),
      imageUrl: 'https://www.figma.com/api/mcp/asset/337addb7-bedf-4d9f-82c2-52831e1e8e9f.png',
    ),
    Doctor(
      name: 'BSCKII Hoàng Quốc Việt',
      specialty: 'Cơ xương khớp',
      experience: 'Chuyên khoa Xương Khớp • 18 năm kinh nghiệm',
      rating: '4.8',
      visits: '650 lượt khám',
      location: 'Phòng 205, Tòa C',
      status: 'Lịch trống chiều nay',
      time: '15:00 - 17:30',
      price: '400.000',
      statusColor: Color(0xFF006C49),
      imageUrl: 'https://www.figma.com/api/mcp/asset/609561a5-fa94-42ba-bb20-838d4c870765.png',
    ),
    Doctor(
      name: 'TS.BS Đỗ Phương Linh',
      specialty: 'Da liễu',
      experience: 'Chuyên khoa Da liễu • 11 năm kinh nghiệm',
      rating: '4.9',
      visits: '920 lượt khám',
      location: 'Tầng 3, Khoa Da Liễu',
      status: 'Khám theo hẹn',
      time: 'Còn chỗ ngày mai',
      price: '350.000',
      statusColor: Color(0xFF006C49),
      imageUrl: 'https://www.figma.com/api/mcp/asset/dea3ae85-5554-4919-b282-2ef3aeb1b85c.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = categories[selectedCategory];
    final visible = doctors
        .where(
          (doctor) =>
              (selected == 'Tất cả' ||
                  doctor.specialty.toLowerCase() == selected.toLowerCase()) &&
              doctor.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(title: const Text('Danh sách Bác sĩ - MedCare')),
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
                    hintText: 'Tìm tên bác sĩ, chuyên khoa hoặc triệu chứng...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.verified, size: 14, color: Color(0xFF006C49)),
                    SizedBox(width: 6),
                    Text(
                      'Hơn 120+ chuyên gia đầu ngành',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 50,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              '${visible.length} bác sĩ phù hợp • Sắp xếp: Phổ biến nhất',
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
    );
  }
}

class Doctor {
  const Doctor({
    required this.name,
    required this.specialty,
    required this.experience,
    required this.rating,
    required this.visits,
    required this.location,
    required this.status,
    required this.time,
    required this.price,
    required this.statusColor,
    required this.imageUrl,
  });
  final String name;
  final String specialty;
  final String experience;
  final String rating;
  final String visits;
  final String location;
  final String status;
  final String time;
  final String price;
  final Color statusColor;
  final String imageUrl;
}

class DoctorCard extends StatelessWidget {
  const DoctorCard({super.key, required this.doctor});
  final Doctor doctor;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E7FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.person,
                  size: 36,
                  color: Color(0xFF0057CD),
                ),
              ),
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
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
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
                doctor.rating,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Text(
                '(${doctor.visits})',
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
                  decoration: BoxDecoration(
                    color: doctor.statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${doctor.status} (${doctor.time})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: doctor.statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Giá tư vấn khám',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  Text(
                    '${doctor.price}đ',
                    style: const TextStyle(
                      fontSize: 20,
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
                    location: doctor.location,
                    availability: doctor.status,
                    imageUrl: doctor.imageUrl,
                  ),
                ),
                icon: const Icon(Icons.calendar_month_outlined, size: 15),
                label: const Text('Đặt lịch'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

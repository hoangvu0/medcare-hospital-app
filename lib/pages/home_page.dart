import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../state/medical_store.dart';
import 'doctor_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  static const primary = Color(0xFF0057CD);
  static const dark = Color(0xFF131B2E);
  static const grey = Color(0xFF424655);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAF8FF),
    body: SafeArea(
      bottom: false,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(top: 80, bottom: 84),
            children: [
              _greeting(),
              _emergency(),
              _appointment(),
              _quickActions(),
              _specialties(),
              _topDoctors(),
              _healthTips(),
            ],
          ),
          _header(),
          _bottomNavigation(),
        ],
      ),
    ),
  );

  Widget _header() => Container(
    height: 80,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .94),
      boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8)],
    ),
    child: Row(
      children: [
        const CircleAvatar(
          backgroundColor: Color(0xFFE2E7FF),
          child: Icon(Icons.local_hospital_rounded, color: primary),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MedCare Hospital',
                style: TextStyle(
                  color: primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Cơ sở 1 - Q. Hoàn Kiếm, Hà Nội',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: grey, fontSize: 11),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.notifications),
          icon: const Icon(Icons.notifications_none_rounded, color: dark),
        ),
        IconButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          icon: const Icon(Icons.person_outline, color: primary),
        ),
      ],
    ),
  );

  Widget _greeting() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xin chào 👋',
                    style: TextStyle(color: grey, fontSize: 13),
                  ),
                  SizedBox(height: 3),
                  Text(
                    MedicalScope.of(context).profile.name,
                    style: TextStyle(
                      color: dark,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E7FF),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified, size: 14, color: Color(0xFF006C49)),
                  SizedBox(width: 5),
                  Text(
                    'BHYT: Đã liên kết',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: () => Navigator.pushNamed(context, AppRoutes.search),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Color(0x0D000000), blurRadius: 3),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.search, size: 19, color: Color(0xFF727787)),
                SizedBox(width: 8),
                Text(
                  'Tìm bác sĩ, chuyên khoa, gói khám...',
                  style: TextStyle(color: Color(0xFF727787), fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _emergency() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDAD6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFBA1A1A),
            child: Icon(Icons.phone, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CẤP CỨU 24/7',
                  style: TextStyle(
                    color: Color(0xFFBA1A1A),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '1900 8899',
                  style: TextStyle(
                    color: Color(0xFF93000A),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => _emergencyDialog(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
            ),
            child: const Text('Gọi ngay'),
          ),
        ],
      ),
    ),
  );

  void _emergencyDialog() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Gọi cấp cứu 24/7'),
      content: const Text('Bạn có muốn gọi MedCare 1900 8899 không?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Gọi ngay'),
        ),
      ],
    ),
  );

  Widget _appointment() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
    child: Column(
      children: [
        _sectionTitle('Lịch hẹn sắp tới', 'Tất cả (2)'),
        const SizedBox(height: 9),
        InkWell(
          onTap: () => Navigator.pushNamed(context, AppRoutes.appointments),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                Row(
                  children: [
                    const Chip(label: Text('Đã xác nhận khám')),
                    const Spacer(),
                    const Text(
                      '#MED-9428',
                      style: TextStyle(color: grey, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFFE2E7FF),
                      child: Icon(Icons.person, color: primary),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CHUYÊN KHOA TIM MẠCH',
                            style: TextStyle(
                              color: primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'BS. CKI Nguyễn Văn An',
                            style: TextStyle(
                              color: dark,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Phòng khám 304 - Tầng 3, Nhà A',
                            style: TextStyle(color: grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 15,
                        color: primary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Ngày mai, 18/10/2024',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '09:30',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _quickActions() {
    const actions = [
      (Icons.calendar_month, 'Đặt khám\nnhanh', AppRoutes.appointments),
      (Icons.medical_services, 'Bác sĩ\nchuyên khoa', AppRoutes.doctors),
      (Icons.description, 'Bệnh án\nđiện tử', AppRoutes.records),
      (Icons.account_balance_wallet, 'Thanh toán\nviện phí', AppRoutes.payment),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: actions
            .map(
              (item) => Expanded(
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, item.$3),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E7FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(item.$1, color: primary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.$2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _specialties() {
    const specialties = [
      ('Tim Mạch', '18 bác sĩ', Icons.favorite),
      ('Nhi Khoa', '24 bác sĩ', Icons.child_care),
      ('Tai Mũi Họng', '15 bác sĩ', Icons.health_and_safety),
      ('Da Liễu', '12 bác sĩ', Icons.face),
      ('Khoa Mắt', '14 bác sĩ', Icons.visibility),
      ('Nội Tiết', '9 bác sĩ', Icons.accessibility_new),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        children: [
          _sectionTitle(
            'Chuyên khoa tiêu biểu',
            'Xem tất cả',
            route: AppRoutes.specialtyList,
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: .95,
            children: specialties
                .map(
                  (item) => InkWell(
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.specialty,
                      arguments: item.$1,
                    ),
                    child: Container(
                      decoration: _cardDecoration(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.$3, color: primary, size: 24),
                          const SizedBox(height: 7),
                          Text(
                            item.$1,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            item.$2,
                            style: const TextStyle(color: grey, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _topDoctors() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
    child: Column(
      children: [
        _sectionTitle(
          'Bác sĩ tiêu biểu tuần này',
          'Danh sách',
          route: AppRoutes.doctors,
        ),
        const SizedBox(height: 12),
        _doctorCard(
          'Khoa Nhi',
          'PGS.TS Lê Thị Mai',
          'Trưởng khoa Nhi • 22 năm kinh nghiệm',
          '350.000đ',
        ),
        const SizedBox(height: 12),
        _doctorCard(
          'Tai Mũi Họng',
          'ThS.BS Trần Quang Huy',
          'Chuyên khoa Cấp cao • 14 năm kinh nghiệm',
          '300.000đ',
        ),
      ],
    ),
  );

  Widget _doctorCard(
    String specialty,
    String name,
    String experience,
    String price,
  ) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(),
    child: Column(
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 32,
              backgroundColor: Color(0xFFE2E7FF),
              child: Icon(Icons.person, color: primary, size: 34),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Chip(label: Text(specialty)),
                  Text(
                    name,
                    style: const TextStyle(
                      color: dark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    experience,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: grey, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phí khám tư vấn',
                  style: TextStyle(color: grey, fontSize: 10),
                ),
                Text(
                  price,
                  style: const TextStyle(
                    color: primary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DoctorDetailPage(
                    doctor: DoctorInfo(
                      name: name,
                      specialty: specialty,
                      experience: experience,
                      rating: '4.9',
                      price: price,
                    ),
                  ),
                ),
              ),
              icon: const Icon(Icons.calendar_month, size: 15),
              label: const Text('Đặt lịch ngay'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _healthTips() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
    child: Column(
      children: [
        _sectionTitle('Cẩm nang sức khỏe', 'Xem thêm'),
        const SizedBox(height: 12),
        ...[
          (
            'Tim mạch',
            '5 phút đọc',
            '5 dấu hiệu cảnh báo sớm bệnh lý mạch vành',
            Icons.favorite,
          ),
          (
            'Nhi khoa',
            '4 phút đọc',
            'Chăm sóc trẻ sốt giao mùa đúng cách',
            Icons.child_care,
          ),
        ].map(
          (article) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E7FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(article.$4, color: primary),
              ),
              title: Text(
                article.$3,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${article.$1} • ${article.$2}'),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _sectionTitle(String title, String action, {String? route}) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: dark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      InkWell(
        onTap: route == null ? null : () => Navigator.pushNamed(context, route),
        child: Row(
          children: [
            Text(
              action,
              style: const TextStyle(
                color: primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.chevron_right, color: primary, size: 16),
          ],
        ),
      ),
    ],
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 2)),
    ],
  );

  Widget _bottomNavigation() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 64,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x120F172A), blurRadius: 12)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomItem(
              icon: Icons.home_outlined,
              title: 'Trang chủ',
              active: selectedIndex == 0,
              onTap: () {},
            ),
            _BottomItem(
              icon: Icons.medical_services_outlined,
              title: 'Bác sĩ',
              active: selectedIndex == 1,
              onTap: () => Navigator.pushNamed(context, AppRoutes.doctors),
            ),
            _BottomItem(
              icon: Icons.calendar_month_outlined,
              title: 'Lịch hẹn',
              active: selectedIndex == 2,
              onTap: () => Navigator.pushNamed(context, AppRoutes.appointments),
            ),
            _BottomItem(
              icon: Icons.description_outlined,
              title: 'Bệnh án',
              active: selectedIndex == 3,
              onTap: () => Navigator.pushNamed(context, AppRoutes.records),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.title,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 19,
            color: active ? const Color(0xFF0057CD) : const Color(0xFF424655),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: active ? const Color(0xFF0057CD) : const Color(0xFF424655),
            ),
          ),
        ],
      ),
    ),
  );
}

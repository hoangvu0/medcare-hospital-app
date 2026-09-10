import 'package:flutter/material.dart';

import '../routes/app_routes.dart';

class PatientRecordsPage extends StatefulWidget {
  const PatientRecordsPage({super.key});

  @override
  State<PatientRecordsPage> createState() => _PatientRecordsPageState();
}

class _PatientRecordsPageState extends State<PatientRecordsPage> {
  int selectedTab = 0;
  final tabs = const [
    'Lịch sử khám',
    'Kết quả xét nghiệm',
    'Đơn thuốc điện tử',
    'X-Quang / MRI',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(title: const Text('Hồ sơ bệnh án - MedCare')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
        children: [
          _patientHeader(),
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
                  if (index == 2) {
                    Navigator.pushNamed(context, AppRoutes.prescription);
                  } else {
                    setState(() => selectedTab = index);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (selectedTab == 0) _history() else _emptyTab(),
          const SizedBox(height: 16),
          _securityBanner(),
          const SizedBox(height: 12),
          _aiBanner(),
        ],
      ),
    );
  }

  Widget _patientHeader() => Card(
    color: const Color(0xFFF2F3FF),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: Color(0xFFDAE2FF),
                child: Icon(Icons.person, color: Color(0xFF0057CD)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trần Hoàng Minh  ✓',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Mã BN: MC-89241',
                      style: TextStyle(color: Color(0xFF0057CD)),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _message('Mã QR y tế của bệnh nhân'),
                icon: const Icon(Icons.qr_code_2, color: Color(0xFF0057CD)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _highlight('Nhóm máu', 'O+', Icons.bloodtype)),
              const SizedBox(width: 8),
              Expanded(
                child: _highlight(
                  'Thẻ BHYT',
                  'Hạn 12/2025',
                  Icons.verified_user,
                  color: const Color(0xFFE4F5EC),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _highlight(
                  'Dị ứng',
                  'Penicillin',
                  Icons.warning_amber,
                  color: const Color(0xFFFFDAD6),
                  textColor: const Color(0xFFBA1A1A),
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
    IconData icon, {
    Color color = Colors.white,
    Color textColor = const Color(0xFF131B2E),
  }) {
    return Container(
      height: 72,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: textColor.withValues(alpha: .75),
            ),
          ),
          const SizedBox(height: 5),
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
                    fontSize: 13,
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

  Widget _history() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Các đợt khám gần đây', style: _heading),
      const SizedBox(height: 12),
      _episode(
        '15/10/2024',
        'Khám định kỳ & Tái khám',
        'Nội Tim Mạch',
        'BS. CKI Nguyễn Văn An',
        'Tăng huyết áp độ 1 - Rối loạn lipid máu nhẹ',
        true,
      ),
      const SizedBox(height: 14),
      _episode(
        '28/07/2024',
        'Khám cấp tính đường hô hấp',
        'Tai Mũi Họng',
        'ThS.BS Phạm Hoài Nam',
        'Viêm xoang dị ứng cấp',
        false,
      ),
    ],
  );

  Widget _episode(
    String date,
    String title,
    String specialty,
    String doctor,
    String diagnosis,
    bool active,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
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
                      specialty,
                      style: const TextStyle(
                        color: Color(0xFF0057CD),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      date,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Chip(label: Text(active ? 'Hoàn thành' : 'Đã khỏi bệnh')),
            ],
          ),
          const Divider(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEAEFFF),
              child: Icon(Icons.person, color: Color(0xFF0057CD)),
            ),
            title: Text(doctor),
            subtitle: Text(diagnosis),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _action('Đơn thuốc', Icons.medication_outlined)),
              const SizedBox(width: 8),
              Expanded(
                child: _action('Kết quả xét nghiệm', Icons.science_outlined),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _fullAction(
            'Tải bản sao Bệnh án điện tử (PDF ký số)',
            Icons.download_outlined,
          ),
        ],
      ),
    ),
  );

  Widget _action(String title, IconData icon) => OutlinedButton.icon(
    onPressed: () => _message('Đang mở $title'),
    icon: Icon(icon, size: 15),
    label: Text(title, overflow: TextOverflow.ellipsis),
  );
  Widget _fullAction(String title, IconData icon) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: () => _message('Đang chuẩn bị file PDF bệnh án'),
      icon: Icon(icon, size: 15),
      label: Text(title),
    ),
  );

  Widget _emptyTab() => Card(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          const Icon(
            Icons.medical_information_outlined,
            size: 48,
            color: Color(0xFF0057CD),
          ),
          const SizedBox(height: 12),
          Text(
            tabs[selectedTab],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Chọn một hồ sơ để xem thông tin y tế chi tiết.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _securityBanner() => const Card(
    color: Color(0xFFE2E7FF),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: Color(0xFF39B8FD),
        child: Icon(Icons.security, color: Colors.white),
      ),
      title: Text(
        'Bảo mật y tế cấp quốc gia',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'Hồ sơ được mã hóa 256-bit. Chỉ người bệnh và bác sĩ được ủy quyền có quyền truy cập.',
      ),
    ),
  );
  Widget _aiBanner() => Card(
    color: const Color(0xFF0057CD),
    child: ListTile(
      leading: const Icon(Icons.smart_toy_outlined, color: Colors.white),
      title: const Text(
        'Hỏi đáp về bệnh án với AI',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      subtitle: const Text(
        'Giải thích chỉ số máu và lưu ý dùng thuốc',
        style: TextStyle(color: Colors.white70),
      ),
      trailing: TextButton(
        onPressed: () => _message('Tính năng hỏi đáp AI đang được mở'),
        child: const Text('Tra cứu', style: TextStyle(color: Colors.white)),
      ),
    ),
  );

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}

const _heading = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);

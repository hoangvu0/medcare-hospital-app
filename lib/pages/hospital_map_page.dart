import 'package:flutter/material.dart';

class HospitalMapPage extends StatefulWidget {
  const HospitalMapPage({super.key});

  @override
  State<HospitalMapPage> createState() => _HospitalMapPageState();
}

class _HospitalMapPageState extends State<HospitalMapPage> {
  String _selectedBuilding = 'A';
  String _startPoint = 'Cổng số 1 (Sảnh chính)';
  String _destPoint = 'Phòng 204: Khám Tiêu hóa (Tầng 2 Tòa A)';
  bool _isNavigating = false;

  Widget _buildIndoorRoutingCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0057CD).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.directions_walk_rounded, color: Color(0xFF0057CD), size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TÌM ĐƯỜNG ĐI TRONG BỆNH VIỆN',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0057CD))),
                    Text('Chỉ dẫn di chuyển từng bước (Indoor Navigation)',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Start Point Dropdown
          DropdownButtonFormField<String>(
            initialValue: _startPoint,
            decoration: const InputDecoration(
              labelText: 'Điểm xuất phát',
              prefixIcon: Icon(Icons.my_location_rounded, color: Color(0xFF0057CD), size: 20),
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Cổng số 1 (Sảnh chính)', child: Text('Cổng số 1 (Sảnh chính)')),
              DropdownMenuItem(value: 'Kiosk lấy số (Tầng 1 Tòa A)', child: Text('Kiosk lấy số (Tầng 1 Tòa A)')),
              DropdownMenuItem(value: 'Nhà xe Bệnh viện', child: Text('Nhà xe Bệnh viện')),
              DropdownMenuItem(value: 'Khoa Cấp cứu 24/7', child: Text('Khoa Cấp cứu 24/7')),
            ],
            onChanged: (v) => setState(() => _startPoint = v ?? _startPoint),
          ),
          const SizedBox(height: 10),

          // Destination Dropdown
          DropdownButtonFormField<String>(
            initialValue: _destPoint,
            decoration: const InputDecoration(
              labelText: 'Điểm đến',
              prefixIcon: Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 20),
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Phòng 204: Khám Tiêu hóa (Tầng 2 Tòa A)',
                child: Text('Phòng 204: Khám Tiêu hóa (Tầng 2 Tòa A)'),
              ),
              DropdownMenuItem(
                value: 'Khoa Xét nghiệm (Tầng 2 Tòa B)',
                child: Text('Khoa Xét nghiệm (Tầng 2 Tòa B)'),
              ),
              DropdownMenuItem(
                value: 'Khoa Chẩn đoán Hình ảnh X-Quang (Tòa C)',
                child: Text('Khoa X-Quang / MRI (Tòa C)'),
              ),
              DropdownMenuItem(
                value: 'Nhà thuốc Bệnh viện (Tầng 1 Tòa A)',
                child: Text('Nhà thuốc Bệnh viện (Tầng 1 Tòa A)'),
              ),
            ],
            onChanged: (v) => setState(() => _destPoint = v ?? _destPoint),
          ),
          const SizedBox(height: 12),

          // Route Guide Steps
          if (_isNavigating) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.route_rounded, color: Color(0xFF10B981), size: 18),
                      SizedBox(width: 8),
                      Text('Khoảng cách: 65 mét • Khoảng 1.5 phút đi bộ',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF065F46))),
                    ],
                  ),
                  Divider(height: 14),
                  Text('• Bước 1: Từ Sảnh chính, đi thẳng 20 mét qua quầy Lễ tân.'),
                  Text('• Bước 2: Rẽ phải vào Khu thang máy A, bấm lên Tầng 2.'),
                  Text('• Bước 3: Ra khỏi thang máy, rẽ trái đi dọc hành lang 15 mét.'),
                  Text('• Bước 4: Phòng 204 nằm ở bên tay phải (cửa màu xanh dương).'),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => setState(() => _isNavigating = !_isNavigating),
              icon: Icon(_isNavigating ? Icons.close : Icons.navigation_rounded),
              label: Text(_isNavigating ? 'Ẩn lộ trình' : 'Bắt đầu chỉ đường chi tiết'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0057CD),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sơ đồ & Chỉ đường Nội viện'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildIndoorRoutingCard(isDark),
          const SizedBox(height: 20),
          // 4-step Clinic Workflow
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.alt_route_rounded, color: Color(0xFF0057CD)),
                    SizedBox(width: 8),
                    Text(
                      'LỘ TRÌNH KHÁM BỆNH NỘI VIỆN (4 BƯỚC)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0057CD)),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _flowStep(
                  number: '1',
                  title: 'Quét QR tại Kiosk Tầng 1 (Tòa A)',
                  desc: 'Mở mã QR trong phiếu khám đặt trước quẹt vào máy lấy số ưu tiên.',
                ),
                _flowStep(
                  number: '2',
                  title: 'Đến phòng khám chuyên khoa',
                  desc: 'Ngồi tại sảnh chờ, theo dõi màn hình TV điện tử đến lượt vào khám.',
                ),
                _flowStep(
                  number: '3',
                  title: 'Làm xét nghiệm / Chụp chiếu',
                  desc: 'Phòng xét nghiệm Tầng 2 Tòa B, Phòng X-Quang Tầng 1 Tòa C.',
                ),
                _flowStep(
                  number: '4',
                  title: 'Nhận thuốc & Hoàn tất viện phí',
                  desc: 'Quầy thuốc Bệnh viện Tầng 1 Tòa A xuất trình mã đơn thuốc.',
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Building selector
          Row(
            children: [
              const Text(
                'DANH MỤC KHU VỰC CÁC TÒA NHÀ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0057CD),
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'A', label: Text('Tòa A')),
                  ButtonSegment(value: 'B', label: Text('Tòa B')),
                  ButtonSegment(value: 'C', label: Text('Tòa C')),
                ],
                selected: {_selectedBuilding},
                onSelectionChanged: (val) {
                  setState(() => _selectedBuilding = val.first);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Building details
          _buildBuildingContent(_selectedBuilding),
        ],
      ),
    );
  }

  Widget _flowStep({
    required String number,
    required String title,
    required String desc,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: const Color(0xFF0057CD),
              child: Text(number, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: const Color(0xFF0057CD).withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBuildingContent(String building) {
    if (building == 'A') {
      return Column(
        children: [
          _locationTile('Tầng 1', 'Kiosk tiếp đón thông minh • Cấp cứu 24/7 • Nhà thuốc Bệnh viện • Thu ngân trung tâm', Icons.local_hospital),
          _locationTile('Tầng 2', 'Khoa Nhi (Phòng 202 - ThS.BS Lê Thu Trang) • Khu vui chơi trẻ em', Icons.child_care),
          _locationTile('Tầng 4', 'Khoa Tim mạch (Phòng 402 - PGS.TS Trần Minh Đức) • Khoa Thần kinh (Phòng 405)', Icons.favorite),
        ],
      );
    } else if (building == 'B') {
      return Column(
        children: [
          _locationTile('Tầng 1', 'Khoa Da liễu (TS.BS Đỗ Phương Linh) • Khu tư vấn dinh dưỡng', Icons.face),
          _locationTile('Tầng 2', 'Trung tâm Xét nghiệm Sinh hóa - Huyết học - Vi sinh • Lấy máu tự động', Icons.biotech),
          _locationTile('Tầng 3', 'Khoa Tiêu hóa (Phòng 305 - PGS.TS Nguyễn Văn An) • Trung tâm Nội soi Olympus EVIS', Icons.medical_services),
          _locationTile('Tầng 5', 'Khoa Mắt (Phòng 208 - BSCKII Vũ Thị Bích Ngọc) • Đo khúc xạ vi tính', Icons.visibility),
        ],
      );
    } else {
      return Column(
        children: [
          _locationTile('Tầng 1', 'Khoa Chẩn đoán Hình ảnh: Máy chụp MRI 3.0 Tesla, CT Scanner 128 lát cắt', Icons.camera_alt),
          _locationTile('Tầng 2', 'Khoa Cơ Xương Khớp (Phòng 205 - BSCKII Hoàng Quốc Việt) • Vật lý trị liệu', Icons.accessibility_new),
          _locationTile('Tầng 3', 'Khoa Sản phụ khoa (Phòng 102 - BSCKII Ngô Kim Oanh) • Khoa Răng Hàm Mặt', Icons.pregnant_woman),
        ],
      );
    }
  }

  Widget _locationTile(String floor, String description, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF0057CD), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(floor, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0057CD))),
                const SizedBox(height: 3),
                Text(description, style: const TextStyle(fontSize: 12, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';

import '../routes/app_routes.dart';

class EPrescriptionPage extends StatefulWidget {
  const EPrescriptionPage({super.key});

  @override
  State<EPrescriptionPage> createState() => _EPrescriptionPageState();
}

class _EPrescriptionPageState extends State<EPrescriptionPage> {
  static const _primary = Color(0xFF0D6EFD);
  static const _success = Color(0xFF10B981);
  bool _reminderEnabled = true;
  final Set<String> _reminderTimes = {'08:00', '18:00'};

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAFC),
    appBar: AppBar(
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HỒ SƠ Y TẾ ĐIỆN TỬ',
            style: TextStyle(fontSize: 10, color: _primary),
          ),
          Text(
            'Đơn thuốc điện tử',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _sharePrescription,
          tooltip: 'Chia sẻ đơn thuốc',
          icon: const Icon(Icons.share_outlined),
        ),
        IconButton(
          onPressed: _showBarcodeDialog,
          tooltip: 'Mở mã xuất thuốc',
          icon: const Icon(Icons.qr_code_2),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        _prescriptionIdentity(),
        const SizedBox(height: 14),
        _dispensingCode(),
        const SizedBox(height: 14),
        _reminderCard(),
        const SizedBox(height: 20),
        const Row(
          children: [
            Text(
              'Danh mục thuốc',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),
            Chip(label: Text('4 loại')),
          ],
        ),
        const SizedBox(height: 8),
        _medicineCard(
          number: '1',
          name: 'Hapacol 250mg',
          category: 'Hạ sốt',
          quantity: '10 gói',
          instruction: 'Uống 1 gói/lần khi sốt từ 38.5°C. Các liều cách nhau tối thiểu 4–6 giờ.',
          note: 'Không dùng quá liều khuyến nghị trong 24 giờ.',
        ),
        _medicineCard(
          number: '2',
          name: 'Augmentin 250mg/31.25mg',
          category: 'Kháng sinh',
          quantity: '1 chai',
          instruction: 'Uống 5 ml lúc 08:00 và 18:00, sau ăn. Dùng đủ 7 ngày theo chỉ định.',
          note: 'Không tự ý ngừng thuốc dù đã giảm triệu chứng.',
          warning: true,
        ),
        _medicineCard(
          number: '3',
          name: 'Siro Prospan 100ml',
          category: 'Trị ho thảo dược',
          quantity: '1 chai',
          instruction: 'Uống 2.5 ml/lần, ngày 3 lần sau bữa ăn.',
        ),
        _medicineCard(
          number: '4',
          name: 'BioGaia Protectis Drops',
          category: 'Men vi sinh',
          quantity: '1 lọ',
          instruction: 'Dùng 5 giọt/ngày vào buổi sáng để cân bằng đường ruột khi sử dụng kháng sinh.',
        ),
        const SizedBox(height: 4),
        _adviceAndFollowUp(),
        const SizedBox(height: 14),
        _costSummary(),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _orderDelivery,
          icon: const Icon(Icons.local_shipping_outlined),
          label: const Text('Đặt mua & Giao thuốc tận nhà (2h)'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _downloadPrescription,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Tải đơn PDF có chữ ký số'),
        ),
      ],
    ),
  );

  Widget _prescriptionIdentity() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: Color(0xFFE7F0FF),
                child: Icon(Icons.child_care, color: _primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trần Minh Quân',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Bé Ben • 28 tháng • Nam • 13.5 kg',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Text(
                '#RX-2024-89241',
                style: TextStyle(color: _primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 28),
          const _DataRow(
            icon: Icons.event_note_outlined,
            title: 'Ngày kê đơn',
            value: '24/10/2024',
          ),
          const SizedBox(height: 10),
          const _DataRow(
            icon: Icons.timer_outlined,
            title: 'Hiệu lực đơn thuốc',
            value: 'Đến hết 31/10/2024',
          ),
          const SizedBox(height: 10),
          const _DataRow(
            icon: Icons.medical_information_outlined,
            title: 'Chẩn đoán',
            value: 'Viêm họng cấp / Sốt siêu vi (J02.9)',
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user_outlined, color: _success),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đã ký số bởi ThS.BS Lê Thu Trang • Khoa Nhi & Sơ sinh',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _dispensingCode() => Card(
    color: const Color(0xFFEFF6FF),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _showBarcodeDialog,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded, size: 42, color: _primary),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mã xuất thuốc tại quầy Dược',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Đưa mã cho dược sĩ tại tầng 1 để nhận thuốc.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_full, size: 18),
          ],
        ),
      ),
    ),
  );

  Widget _reminderCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Nhắc uống thuốc tự động',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _reminderEnabled
                  ? 'Đang nhắc lúc ${_reminderTimes.join(', ')}'
                  : 'Chưa bật nhắc thuốc',
            ),
            value: _reminderEnabled,
            activeThumbColor: _success,
            onChanged: (value) => setState(() => _reminderEnabled = value),
          ),
          if (_reminderEnabled) ...[
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: ['08:00', '13:00', '18:00']
                    .map(
                      (time) => FilterChip(
                        label: Text(time),
                        selected: _reminderTimes.contains(time),
                        onSelected: (selected) => setState(
                          () => selected
                              ? _reminderTimes.add(time)
                              : _reminderTimes.remove(time),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _medicineCard({
    required String number,
    required String name,
    required String category,
    required String quantity,
    required String instruction,
    String? note,
    bool warning = false,
  }) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE7F0FF),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      category,
                      style: const TextStyle(color: _primary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                quantity,
                style: const TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(instruction, style: const TextStyle(height: 1.4)),
          ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                note,
                style: TextStyle(
                  color: warning ? const Color(0xFFDC2626) : Colors.black54,
                  fontSize: 12,
                  fontWeight: warning ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _adviceAndFollowUp() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lời dặn bác sĩ',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Cho bé uống nhiều nước ấm, chia nhỏ cữ uống.\n• Vệ sinh mũi họng bằng nước muối sinh lý.\n• Đưa trẻ đi khám ngay nếu sốt cao kéo dài, khó thở hoặc bỏ ăn.',
            style: TextStyle(height: 1.55),
          ),
          const Divider(height: 28),
          const Row(
            children: [
              Icon(Icons.event_available_outlined, color: _primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tái khám: Thứ Hai, 28/10/2024 (buổi sáng)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.appointments),
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Đặt lịch tái khám 28/10'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _costSummary() => const Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _SummaryRow('Tạm tính thuốc kê đơn (4 mục)', '415.000đ'),
          SizedBox(height: 8),
          _SummaryRow('BHYT / trợ giá viện', '-85.000đ', success: true),
          Divider(height: 22),
          _SummaryRow('Tổng tiền cần thanh toán', '330.000đ', bold: true),
        ],
      ),
    ),
  );

  void _showBarcodeDialog() => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Mã xuất thuốc'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _BarcodeStrip(code: 'RX202489241'),
          SizedBox(height: 12),
          Text(
            '#RX-2024-89241',
            style: TextStyle(color: _primary, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Dược sĩ quét mã để xác nhận xuất thuốc.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
  void _sharePrescription() =>
      _message('Đã chuẩn bị liên kết chia sẻ đơn thuốc an toàn.');
  void _orderDelivery() =>
      _message('Đã tạo yêu cầu giao thuốc. Dược sĩ sẽ xác nhận trong ít phút.');
  void _downloadPrescription() =>
      _message('Đang chuẩn bị bản PDF có chữ ký số.');
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: const Color(0xFF0D6EFD)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(title, style: const TextStyle(color: Colors.black54)),
      ),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    ],
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
    this.label,
    this.value, {
    this.success = false,
    this.bold = false,
  });
  final String label;
  final String value;
  final bool success;
  final bool bold;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          color: success
              ? const Color(0xFF10B981)
              : (bold ? const Color(0xFF0D6EFD) : null),
          fontWeight: bold || success ? FontWeight.bold : FontWeight.normal,
          fontSize: bold ? 17 : 14,
        ),
      ),
    ],
  );
}

class _BarcodeStrip extends StatelessWidget {
  const _BarcodeStrip({required this.code});
  final String code;
  @override
  Widget build(BuildContext context) => Container(
    height: 96,
    width: 250,
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final unit in code.codeUnits) ...[
          Expanded(
            flex: unit.isEven ? 2 : 1,
            child: const ColoredBox(color: Colors.black),
          ),
          const Spacer(),
        ],
      ],
    ),
  );
}

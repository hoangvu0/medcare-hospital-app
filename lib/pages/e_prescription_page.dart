import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../routes/app_routes.dart';
import '../state/medical_store.dart';

class EPrescriptionPage extends StatefulWidget {
  const EPrescriptionPage({super.key});

  @override
  State<EPrescriptionPage> createState() => _EPrescriptionPageState();
}

class _EPrescriptionPageState extends State<EPrescriptionPage> {
  static const _primary = Color(0xFF0D6EFD);
  static const _success = Color(0xFF10B981);
  bool _reminderEnabled = true;
  final Set<String> _reminderTimes = {'07:30', '12:00', '19:00'};

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final profile = store.profile;
    final medicines = store.medicines;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HỒ SƠ DƯỢC LÂM SÀNG',
              style: TextStyle(fontSize: 10, color: _primary, fontWeight: FontWeight.bold),
            ),
            Text(
              'Đơn thuốc điện tử',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
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
            onPressed: () => _showBarcodeDialog(profile.id),
            tooltip: 'Mở mã xuất thuốc',
            icon: const Icon(Icons.qr_code_2),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _prescriptionIdentity(profile),
          const SizedBox(height: 14),
          _dispensingCode(profile.id),
          const SizedBox(height: 14),
          _reminderCard(),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'Danh mục thuốc kê đơn',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Chip(label: Text('${medicines.length} loại')),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < medicines.length; i++) ...[
            _medicineCard(
              number: '${i + 1}',
              name: medicines[i].name,
              category: medicines[i].category,
              quantity: medicines[i].quantity,
              instruction: medicines[i].instruction,
              note: medicines[i].warning,
              warning: medicines[i].warning != null,
            ),
          ],
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
            label: const Text('Tải đơn PDF có chữ ký số Bộ Y Tế'),
          ),
        ],
      ),
    );
  }

  Widget _prescriptionIdentity(PatientProfile profile) => Card(
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: Color(0xFFE7F0FF),
                child: Icon(Icons.person, color: _primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${profile.gender} • 24 tuổi • Mã BN: ${profile.id} • BHYT: ${profile.insuranceNumber}',
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Text(
                '#DT-2026-89241',
                style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const Divider(height: 24),
          const _DataRow(
            icon: Icons.event_note_outlined,
            title: 'Ngày kê đơn',
            value: '10/02/2026',
          ),
          const SizedBox(height: 8),
          const _DataRow(
            icon: Icons.timer_outlined,
            title: 'Hiệu lực đơn thuốc',
            value: 'Đến hết 24/02/2026 (14 ngày)',
          ),
          const SizedBox(height: 8),
          const _DataRow(
            icon: Icons.medical_information_outlined,
            title: 'Chẩn đoán ICD-10',
            value: 'K29.0 - Viêm loét dạ dày tá tràng sung huyết, Hp (+)',
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
                    'Đã ký số bởi PGS.TS.BS Nguyễn Văn An • Chủ nhiệm Khoa Tiêu hóa',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _dispensingCode(String patientId) => Card(
    color: const Color(0xFFEFF6FF),
    elevation: 1,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showBarcodeDialog(patientId),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded, size: 40, color: _primary),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mã xuất thuốc tại Nhà thuốc Bệnh viện',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Chạm để mở mã vạch / QR cấp thuốc không chờ đợi',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _primary),
          ],
        ),
      ),
    ),
  );

  Widget _reminderCard() => Card(
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Nhắc uống thuốc tự động',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _reminderEnabled
                  ? 'Đang nhắc cữ: ${_reminderTimes.join(', ')}'
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
                children: ['07:30', '12:00', '19:00', '21:00']
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
    elevation: 1,
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
                        fontSize: 15,
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
            child: Text(instruction, style: const TextStyle(height: 1.4, fontSize: 13)),
          ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '⚠️ Lưu ý: $note',
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
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lời dặn của Bác sĩ điều trị',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Tuyệt đối uống thuốc đúng giờ, dùng đủ 14 ngày phác đồ kháng sinh diệt Hp.\n• Kiêng hoàn toàn rượu bia, cà phê, ớt, tiêu, đồ chua lên men và nước ngọt có gas.\n• Ăn đúng bữa, nhai kỹ, không ăn quá no và không nằm ngay sau bữa ăn.\n• Sau khi hết thuốc 4 tuần, đến viện làm test thở C13 để kiểm tra độ sạch khuẩn Hp.',
            style: TextStyle(height: 1.5, fontSize: 13),
          ),
          const Divider(height: 24),
          const Row(
            children: [
              Icon(Icons.event_available_outlined, color: _primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hẹn tái khám: 10/03/2026 (Buổi sáng)',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
              label: const Text('Đặt lịch tái khám định kỳ'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _costSummary() => const Card(
    elevation: 1,
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _SummaryRow('Tổng tiền thuốc kê đơn (4 loại)', '850.000đ'),
          SizedBox(height: 8),
          _SummaryRow('BHYT chi trả theo quy định (80%)', '-680.000đ', success: true),
          Divider(height: 22),
          _SummaryRow('Số tiền bệnh nhân cùng chi trả', '170.000đ', bold: true),
        ],
      ),
    ),
  );

  void _showBarcodeDialog(String patientId) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Mã xuất thuốc điện tử'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.qr_code_2, size: 120, color: _primary),
          const SizedBox(height: 12),
          Text(
            '#DT-2026-$patientId',
            style: const TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Đưa mã này cho Dược sĩ tại Quầy phát thuốc Tầng 1 để nhận thuốc nhanh.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );

  void _sharePrescription() =>
      _message('Đã tạo liên kết chia sẻ đơn thuốc có bảo mật mã PIN.');

  void _orderDelivery() => _message(
    'Đã tiếp nhận yêu cầu giao thuốc đến địa chỉ của bạn. Dược sĩ sẽ liên hệ sau 15 phút.',
  );

  void _downloadPrescription() =>
      _message('Đang tải file PDF đơn thuốc có chữ ký số điện tử...');

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
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
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: Colors.grey),
      const SizedBox(width: 8),
      Text('$title: ', style: const TextStyle(color: Colors.black54, fontSize: 13)),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    ],
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
    this.title,
    this.value, {
    this.success = false,
    this.bold = false,
  });

  final String title;
  final String value;
  final bool success;
  final bool bold;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: bold ? 15 : 13,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: bold ? 18 : 13,
          fontWeight: FontWeight.bold,
          color: success
              ? const Color(0xFF10B981)
              : (bold ? const Color(0xFF0D6EFD) : Colors.black87),
        ),
      ),
    ],
  );
}

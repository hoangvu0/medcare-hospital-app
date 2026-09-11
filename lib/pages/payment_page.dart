import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../state/medical_store.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const _primary = Color(0xFF0D6EFD);
  static const _success = Color(0xFF10B981);
  int _selectedPayment = 0;
  bool _invoiceRequested = true;
  bool _privateGuarantee = false;
  String _wallet = 'MoMo';
  String _email = 'vu@example.com';

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final profile = store.profile;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thanh toán viện phí',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Chi tiết & thanh toán trực tuyến',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _downloadStatement,
            tooltip: 'Tải bảng kê',
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 132),
        children: [
          _invoiceCard(profile),
          const SizedBox(height: 18),
          _costSection(),
          const SizedBox(height: 18),
          _insuranceSection(profile),
          const SizedBox(height: 18),
          _paymentSection(),
          const SizedBox(height: 18),
          _eInvoiceSection(),
        ],
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _invoiceCard(PatientProfile profile) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Chip(
            avatar: Icon(Icons.circle, size: 8, color: Color(0xFFF59E0B)),
            label: Text('Chờ thanh toán viện phí'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mã đợt khám: #HS-2026-0891 (Khoa Tiêu hóa)',
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE7F0FF),
              child: Icon(Icons.person, color: _primary),
            ),
            title: Text(
              profile.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            subtitle: Text('Mã BN: ${profile.id} • ${profile.gender} • 24 tuổi'),
          ),
          const Text(
            'SỐ TIỀN THỰC TRẢ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Text(
                '330.000đ',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: _primary,
                ),
              ),
              SizedBox(width: 12),
              Chip(
                label: Text('Đã giảm 80% BHYT'),
                avatar: Icon(Icons.verified, size: 14, color: _success),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _costSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Bảng kê chi phí khám bệnh',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            'Minh bạch 100%',
            style: TextStyle(fontSize: 11, color: _success),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Card(
        child: Column(
          children: [
            const _CostItem(
              title: 'Phí khám Chuyên gia Tiêu hóa',
              detail: 'PGS.TS.BS Nguyễn Văn An • Khoa Tiêu hóa - Gan mật',
              gross: '500.000đ',
              insurance: '-400.000đ',
              payable: '100.000đ',
            ),
            const Divider(height: 1),
            const _CostItem(
              title: 'Nội soi Thực quản - Dạ dày - Tá tràng',
              detail: 'Nội soi gây mê không đau + Test vi khuẩn Hp',
              gross: '800.000đ',
              insurance: '-640.000đ',
              payable: '160.000đ',
            ),
            const Divider(height: 1),
            const _CostItem(
              title: 'Xét nghiệm máu sinh hóa 8 chỉ số',
              detail: 'Glucose, Ure, Creatinine, AST, ALT, Mỡ máu',
              gross: '350.000đ',
              insurance: '-280.000đ',
              payable: '70.000đ',
            ),
            Container(
              color: const Color(0xFFF1F5F9),
              padding: const EdgeInsets.all(16),
              child: const Column(
                children: [
                  _BillRow('Tổng chi phí gốc', '1.650.000đ'),
                  SizedBox(height: 8),
                  _BillRow('BHYT chi trả đúng tuyến (80%)', '-1.320.000đ', success: true),
                  Divider(height: 22),
                  _BillRow('Số tiền bệnh nhân thực trả', '330.000đ', bold: true),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _insuranceSection(PatientProfile profile) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Bảo hiểm y tế áp dụng',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: _success,
                  child: Icon(Icons.shield_outlined, color: Colors.white),
                ),
                title: const Text(
                  'Thẻ Bảo hiểm Y tế (BHYT)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${profile.insuranceNumber} • Đã liên thông Cổng BHXH VN'),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Dữ liệu đã được liên thông tự động với Cổng BHXH Quốc gia. Mức hưởng 80% đúng tuyến được áp dụng trực tiếp vào hóa đơn.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
              const Divider(height: 28),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _privateGuarantee,
                activeThumbColor: _success,
                onChanged: (value) => setState(() => _privateGuarantee = value),
                title: const Text(
                  'Bảo lãnh viện phí tư nhân',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _privateGuarantee
                      ? 'Đã gửi yêu cầu bảo lãnh đến đối tác bảo hiểm.'
                      : 'Gửi yêu cầu bảo lãnh trước khi thanh toán.',
                ),
              ),
              if (_privateGuarantee)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: Icon(
                      Icons.hourglass_top,
                      color: Color(0xFFF59E0B),
                      size: 16,
                    ),
                    label: Text('Đang chờ xác nhận bảo lãnh'),
                  ),
                ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _paymentSection() {
    const methods = [
      'VietQR / Napas247',
      'Ví điện tử',
      'Thẻ ngân hàng',
      'Lấy số tại Kiosk',
    ];
    const icons = [
      Icons.qr_code_2,
      Icons.account_balance_wallet_outlined,
      Icons.credit_card_outlined,
      Icons.confirmation_number_outlined,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hình thức thanh toán',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        RadioGroup<int>(
          groupValue: _selectedPayment,
          onChanged: (value) => setState(() => _selectedPayment = value ?? 0),
          child: Column(
            children: List.generate(
              methods.length,
              (index) => Card(
                child: RadioListTile<int>(
                  value: index,
                  secondary: Icon(icons[index], color: _primary),
                  title: Text(
                    methods[index],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    index == 0
                        ? 'Khuyên dùng • Miễn phí giao dịch'
                        : index == 3
                        ? 'In số thứ tự và thanh toán tại quầy Kiosk'
                        : 'Thanh toán an toàn qua MedCare',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_selectedPayment == 1)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Wrap(
              spacing: 8,
              children: ['MoMo', 'ZaloPay', 'VNPay']
                  .map(
                    (wallet) => ChoiceChip(
                      label: Text(wallet),
                      selected: _wallet == wallet,
                      onSelected: (_) => setState(() => _wallet = wallet),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _eInvoiceSection() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _invoiceRequested,
            onChanged: (value) =>
                setState(() => _invoiceRequested = value ?? false),
            title: const Text(
              'Xuất hóa đơn điện tử VAT y tế (e-Invoice)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'Hóa đơn được gửi về email sau khi thanh toán.',
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (_invoiceRequested)
            Row(
              children: [
                Expanded(
                  child: Text(
                    _email,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
                TextButton(onPressed: _editEmail, child: const Text('Sửa')),
              ],
            ),
          const Divider(),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, size: 17, color: _success),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kênh thanh toán được mã hóa 256-bit, tuân thủ chuẩn bảo mật PCI-DSS.',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _bottomBar() => Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 10)],
    ),
    child: SafeArea(
      top: false,
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng chi trả'),
              Text(
                '680.000đ',
                style: TextStyle(
                  fontSize: 20,
                  color: _primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: _confirmPayment,
              icon: const Icon(Icons.lock_outline),
              label: Text(
                _selectedPayment == 3
                    ? 'Lấy số thanh toán tại Kiosk'
                    : 'Thanh toán ngay 680.000đ',
              ),
            ),
          ),
        ],
      ),
    ),
  );

  void _confirmPayment() {
    if (_selectedPayment == 3) {
      _showKioskTicket();
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận thanh toán'),
        content: Text(
          'Phương thức: ${_paymentName()}\nSố tiền: 680.000đ${_invoiceRequested ? '\nHóa đơn điện tử sẽ gửi đến $_email.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showSuccess();
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _showKioskTicket() => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Đã lấy số thanh toán'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.confirmation_number_outlined, size: 56, color: _primary),
          SizedBox(height: 12),
          Text(
            'Số thứ tự K-042',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Vui lòng đến Kiosk tầng 1 và quét mã bệnh nhân MC-89241.'),
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
  void _showSuccess() => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Thanh toán thành công'),
      content: Text(
        'MedCare đã ghi nhận khoản thanh toán 680.000đ.${_invoiceRequested ? '\nHóa đơn điện tử sẽ được gửi về email của bạn.' : ''}',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Hoàn tất'),
        ),
      ],
    ),
  );
  void _downloadStatement() => _message('Đang chuẩn bị bảng kê chi phí PDF.');
  void _editEmail() {
    final controller = TextEditingController(text: _email);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Email nhận hóa đơn'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _email = controller.text.trim());
              Navigator.pop(dialogContext);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  String _paymentName() => switch (_selectedPayment) {
    0 => 'VietQR / Napas247',
    1 => 'Ví $_wallet',
    2 => 'Thẻ ngân hàng',
    _ => 'Kiosk',
  };
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );
}

class _CostItem extends StatelessWidget {
  const _CostItem({
    required this.title,
    required this.detail,
    required this.gross,
    required this.insurance,
    required this.payable,
  });
  final String title;
  final String detail;
  final String gross;
  final String insurance;
  final String payable;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.medical_services_outlined,
              color: Color(0xFF0D6EFD),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Text(gross, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BHYT hỗ trợ: $insurance',
              style: const TextStyle(fontSize: 11, color: Color(0xFF10B981)),
            ),
            Text(
              'Cần trả: $payable',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    ),
  );
}

class _BillRow extends StatelessWidget {
  const _BillRow(
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
          fontSize: bold ? 17 : 14,
          fontWeight: bold || success ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ],
  );
}

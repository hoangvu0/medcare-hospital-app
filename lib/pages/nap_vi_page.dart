import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_config.dart';
import '../state/medical_store.dart';

enum _TopUpStep { amount, method, review, success }

enum _TopUpMethod { vietQr, momo, zalopay, bankCard }

class WalletTopUpPage extends StatefulWidget {
  const WalletTopUpPage({super.key});

  @override
  State<WalletTopUpPage> createState() => _WalletTopUpPageState();
}

class _WalletTopUpPageState extends State<WalletTopUpPage> {
  static const _primary = Color(0xFF0057CD);
  static const _success = Color(0xFF15803D);
  static const _amounts = [200000, 500000, 1000000, 2000000];

  final _customAmountController = TextEditingController();
  _TopUpStep _step = _TopUpStep.amount;
  _TopUpMethod _method = _TopUpMethod.vietQr;
  int? _amount = 500000;
  bool _accepted = false;
  bool _processing = false;
  String? _clientTransactionId;

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _clientTransactionId = 'WALLET-${DateTime.now().millisecondsSinceEpoch}';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) MedicalScope.of(context).refreshWalletFromBackend();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        title: const Text(
          'Nạp ví MedCare Pay',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          tooltip: _step == _TopUpStep.amount ? 'Đóng' : 'Quay lại',
          icon: const Icon(Icons.arrow_back),
          onPressed: _step == _TopUpStep.success
              ? null
              : () {
                  if (_step == _TopUpStep.amount) {
                    Navigator.pop(context);
                  } else {
                    setState(() => _step = _TopUpStep.values[_step.index - 1]);
                  }
                },
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _buildStep(store),
      ),
      bottomNavigationBar: _step == _TopUpStep.success
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: FilledButton(
                onPressed: _processing ? null : () => _continue(store),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _processing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _step == _TopUpStep.review
                            ? 'Xác nhận nạp ${_formatMoney(_amount ?? 0)}'
                            : 'Tiếp tục',
                      ),
              ),
            ),
    );
  }

  Widget _buildStep(MedicalStore store) {
    switch (_step) {
      case _TopUpStep.amount:
        return _amountStep(store);
      case _TopUpStep.method:
        return _methodStep();
      case _TopUpStep.review:
        return _reviewStep(store);
      case _TopUpStep.success:
        return _successStep(store);
    }
  }

  Widget _amountStep(MedicalStore store) => _page(
    key: const ValueKey('amount'),
    children: [
      _balanceCard(store),
      const SizedBox(height: 22),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showWalletChargeDialog(store),
          icon: const Icon(Icons.payments_outlined),
          label: const Text('Thanh toán chi phí khác bằng ví'),
        ),
      ),
      const SizedBox(height: 18),
      const Text(
        'Bạn muốn nạp bao nhiêu?',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 6),
      const Text(
        'Tiền sẽ được cộng vào ví sau khi giao dịch hoàn tất.',
        style: TextStyle(color: Colors.black54),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _amounts
            .map(
              (amount) => ChoiceChip(
                label: Text(_formatMoney(amount)),
                selected:
                    _amount == amount && _customAmountController.text.isEmpty,
                onSelected: (_) {
                  setState(() {
                    _amount = amount;
                    _customAmountController.clear();
                  });
                },
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 18),
      TextField(
        controller: _customAmountController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) => setState(() {
          _amount = int.tryParse(value);
        }),
        decoration: const InputDecoration(
          labelText: 'Hoặc nhập số tiền khác',
          hintText: 'Tối thiểu 50.000đ',
          suffixText: 'VNĐ',
          prefixIcon: Icon(Icons.edit_outlined),
        ),
      ),
      const SizedBox(height: 12),
      _infoBox(
        icon: Icons.verified_user_outlined,
        text: 'Số tiền nạp tối thiểu 50.000đ và phải chia hết cho 1.000đ.',
      ),
    ],
  );

  Widget _methodStep() => _page(
    key: const ValueKey('method'),
    children: [
      _stepHeader(2, 'Chọn phương thức thanh toán'),
      const SizedBox(height: 18),
      _methodTile(
        method: _TopUpMethod.vietQr,
        icon: Icons.qr_code_2_rounded,
        title: 'VietQR / Napas247',
        subtitle: 'Miễn phí • Quét mã nhanh',
        recommended: true,
      ),
      _methodTile(
        method: _TopUpMethod.momo,
        icon: Icons.account_balance_wallet_outlined,
        title: 'Ví MoMo',
        subtitle: 'Thanh toán qua ứng dụng MoMo',
      ),
      _methodTile(
        method: _TopUpMethod.zalopay,
        icon: Icons.account_balance_wallet_outlined,
        title: 'Ví ZaloPay',
        subtitle: 'Thanh toán qua ứng dụng ZaloPay',
      ),
      _methodTile(
        method: _TopUpMethod.bankCard,
        icon: Icons.credit_card_outlined,
        title: 'Thẻ ngân hàng',
        subtitle: 'Visa • Mastercard • Napas',
      ),
    ],
  );

  Widget _reviewStep(MedicalStore store) => _page(
    key: const ValueKey('review'),
    children: [
      _stepHeader(3, 'Kiểm tra và xác nhận'),
      const SizedBox(height: 18),
      Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _summaryRow('Số tiền nạp', _formatMoney(_amount ?? 0)),
              const Divider(height: 24),
              _summaryRow('Phương thức', _methodLabel(_method)),
              const Divider(height: 24),
              _summaryRow('Phí giao dịch', 'Miễn phí'),
              const Divider(height: 24),
              _summaryRow(
                'Số dư hiện tại',
                _formatMoney(store.walletBalance),
                valueColor: _primary,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      CheckboxListTile(
        value: _accepted,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        onChanged: (value) => setState(() => _accepted = value ?? false),
        title: const Text(
          'Tôi xác nhận thông tin nạp ví là chính xác.',
          style: TextStyle(fontSize: 13),
        ),
      ),
      _infoBox(
        icon: Icons.info_outline,
        text: 'Yêu cầu sẽ được gửi đến cổng thanh toán. Số dư chỉ thay đổi sau khi có xác nhận giao dịch hợp lệ.',
      ),
      if (_method == _TopUpMethod.vietQr) ...[
        const SizedBox(height: 16),
        _vietQrPreview(),
      ],
    ],
  );

  Widget _successStep(MedicalStore store) => _page(
    key: const ValueKey('success'),
    center: true,
    children: [
      const SizedBox(height: 36),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFFDCFCE7),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 54, color: _success),
      ),
      const SizedBox(height: 20),
      const Text(
        'Đã gửi yêu cầu nạp ví',
        style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      const Text(
        'Yêu cầu đang chờ admin kiểm tra và duyệt. Số dư chưa thay đổi.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black54),
      ),
      const SizedBox(height: 20),
      Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _summaryRow(
                'Số dư hiện tại',
                _formatMoney(store.walletBalance),
                valueColor: _success,
              ),
              const SizedBox(height: 12),
              _summaryRow(
                'Mã giao dịch',
                _clientTransactionId ?? 'Đang cập nhật',
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Về trang chủ'),
        ),
      ),
    ],
  );

  Widget _page({
    required Key key,
    required List<Widget> children,
    bool center = false,
  }) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      child: center
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
    );
  }

  Widget _balanceCard(MedicalStore store) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0057CD), Color(0xFF0D6EFD)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Số dư hiện tại',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMoney(store.walletBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_outline, color: Colors.white70, size: 18),
        ],
      ),
    );
  }

  Widget _stepHeader(int step, String title) {
    return Row(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: _primary,
          child: Text('$step', style: const TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _methodTile({
    required _TopUpMethod method,
    required IconData icon,
    required String title,
    required String subtitle,
    bool recommended = false,
  }) {
    final selected = _method == method;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? _primary : const Color(0xFFE2E8F0),
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: () => setState(() => _method = method),
        leading: Icon(icon, color: selected ? _primary : Colors.black54),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (recommended)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text(
                  'Khuyên dùng',
                  style: TextStyle(fontSize: 10, color: _success),
                ),
              ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? _primary : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.black54)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
          ),
        ),
      ],
    );
  }

  Widget _infoBox({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _continue(MedicalStore store) async {
    if (_step == _TopUpStep.amount) {
      final amount = _amount;
      if (amount == null || amount < 50000 || amount % 1000 != 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập số tiền hợp lệ từ 50.000đ.'),
          ),
        );
        return;
      }
      setState(() => _step = _TopUpStep.method);
      return;
    }
    if (_step == _TopUpStep.method) {
      setState(() => _step = _TopUpStep.review);
      return;
    }
    if (!_accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng xác nhận thông tin giao dịch.')),
      );
      return;
    }
    setState(() => _processing = true);
    final method = _methodLabel(_method);
    try {
      final payment = await store.requestWalletTopUpOnline(
        amount: _amount!,
        method: method,
        clientTransactionId: _clientTransactionId,
      );
      _clientTransactionId = payment['clientTransactionId']?.toString();
    } catch (error) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tạo yêu cầu nạp ví: $error')),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _processing = false;
      _step = _TopUpStep.success;
    });
  }

  String _methodLabel(_TopUpMethod method) => switch (method) {
    _TopUpMethod.vietQr => 'VietQR / Napas247',
    _TopUpMethod.momo => 'Ví MoMo',
    _TopUpMethod.zalopay => 'Ví ZaloPay',
    _TopUpMethod.bankCard => 'Thẻ ngân hàng',
  };

  String _formatMoney(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return '$formattedđ';
  }

  Widget _vietQrPreview() {
    final amount = _amount ?? 0;
    final content = 'NAPVI-${_clientTransactionId ?? 'MEDCARE'}';
    final url =
        'https://img.vietqr.io/image/${AppConfig.paymentBankCode}-${AppConfig.paymentBankAccount}-compact2.png?amount=$amount&addInfo=${Uri.encodeComponent(content)}&accountName=${Uri.encodeComponent(AppConfig.paymentBankName)}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            const Text(
              'Quét QR để chuyển đúng số tiền nạp ví',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Image.network(url, height: 210, width: 210, fit: BoxFit.contain),
            const SizedBox(height: 6),
            Text(
              'Nội dung: $content',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            Text(
              '${AppConfig.paymentBankDisplayName} • ${AppConfig.paymentBankAccount}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showWalletChargeDialog(MedicalStore store) async {
    final amountCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController(
      text: 'Thanh toán dịch vụ MedCare',
    );
    final submit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thanh toán bằng ví MedCare Pay'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Số tiền (đồng)'),
            ),
            TextField(
              controller: descriptionCtrl,
              decoration: const InputDecoration(labelText: 'Nội dung chi phí'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Thanh toán'),
          ),
        ],
      ),
    );
    if (submit != true) {
      amountCtrl.dispose();
      descriptionCtrl.dispose();
      return;
    }
    final amount = int.tryParse(amountCtrl.text.trim()) ?? 0;
    final description = descriptionCtrl.text.trim();
    amountCtrl.dispose();
    descriptionCtrl.dispose();
    try {
      await store.chargeWalletOnline(amount: amount, description: description);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thanh toán và trừ tiền khỏi ví.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể thanh toán: $error')));
    }
  }
}

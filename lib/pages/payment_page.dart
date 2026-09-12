import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/medical_models.dart';
import '../state/medical_store.dart';

// ── Hằng số màu sắc ──────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF0D6EFD);
const _kSuccess = Color(0xFF10B981);
const _kWarning = Color(0xFFF59E0B);
const _kDanger = Color(0xFFEF4444);
const _kBg = Color(0xFFF8FAFC);

/// Trang Thanh toán Viện phí nâng cấp — MedCare Hospital
/// Luồng: Bill Review → QR/Ví/Thẻ/Kiosk → Success Screen | History Tab
class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

enum _PaymentStep { bill, qr, success }

class _PaymentPageState extends State<PaymentPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  // Bill state
  PaymentMethod _method = PaymentMethod.vietQr;
  bool _invoiceRequested = true;
  bool _privateGuarantee = false;
  String _email = 'vu@example.com';

  // QR countdown
  _PaymentStep _step = _PaymentStep.bill;
  int _qrSecondsLeft = 900; // 15 phút
  Timer? _qrTimer;
  Timer? _pollTimer;
  PaymentTransaction? _pendingTx;

  // Cost constants (sẽ được tính động từ store)
  static const int _gross = 1650000;
  static const int _insurance = 1320000;
  static const int _net = 330000;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _qrTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_step == _PaymentStep.qr) return _buildQrView();
    if (_step == _PaymentStep.success) return _buildSuccessView();

    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: _buildBillView(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  AppBar _buildAppBar() {
    if (_step == _PaymentStep.success) {
      return AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _kSuccess,
        foregroundColor: Colors.white,
        title: const Text('Thanh toán thành công',
            style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }
    if (_step == _PaymentStep.qr) {
      return AppBar(
        title: const Text('Quét QR để thanh toán'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _qrTimer?.cancel();
            _pollTimer?.cancel();
            setState(() => _step = _PaymentStep.bill);
          },
        ),
      );
    }
    return AppBar(
      bottom: TabBar(
        controller: _tabCtrl,
        tabs: const [
          Tab(icon: Icon(Icons.receipt_long), text: 'Chi tiết viện phí'),
          Tab(icon: Icon(Icons.history), text: 'Lịch sử'),
        ],
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thanh toán viện phí',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Minh bạch • Bảo mật • Nhanh chóng',
              style: TextStyle(fontSize: 11, color: Colors.black45)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.download_outlined),
          tooltip: 'Tải bảng kê PDF',
          onPressed: _downloadStatement,
        ),
      ],
    );
  }

  // ── View 1: Bảng kê viện phí ──────────────────────────────────────────────

  Widget _buildBillView() {
    final store = MedicalScope.of(context);
    return TabBarView(
      controller: _tabCtrl,
      children: [_billTab(store), _historyTab(store)],
    );
  }

  Widget _billTab(MedicalStore store) {
    final profile = store.profile;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 130),
      children: [
        _buildStatusCard(profile),
        const SizedBox(height: 18),
        _buildInsuranceProgress(store),
        const SizedBox(height: 18),
        _buildCostBreakdown(),
        const SizedBox(height: 18),
        _buildInsuranceCard(profile),
        const SizedBox(height: 18),
        _buildPaymentMethodCard(),
        const SizedBox(height: 18),
        _buildEInvoiceCard(),
      ],
    );
  }

  // ── Thẻ thông tin đợt khám ──────────────────────────────────────────────

  Widget _buildStatusCard(PatientProfile profile) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kWarning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kWarning.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 14, color: _kWarning),
                      SizedBox(width: 4),
                      Text('Chờ thanh toán viện phí',
                          style: TextStyle(
                              fontSize: 12,
                              color: _kWarning,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Spacer(),
                Text('#HS-2026-0891',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFFE7F0FF),
                  child: Icon(Icons.person, color: _kPrimary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                          'Mã BN: ${profile.id} • ${profile.gender} • Nhóm máu ${profile.bloodType}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text('SỐ TIỀN THỰC TRẢ',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black45,
                    letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatMoney(_net),
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: _kPrimary),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kSuccess.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 13, color: _kSuccess),
                      SizedBox(width: 4),
                      Text('Đã giảm 80% BHYT',
                          style:
                              TextStyle(fontSize: 11, color: _kSuccess, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
                'Tổng chi phí: ${_formatMoney(_gross)}  •  BHYT: -${_formatMoney(_insurance)}',
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  // ── Thanh tiến trình hạn mức BHYT năm ──────────────────────────────────

  Widget _buildInsuranceProgress(MedicalStore store) {
    const int yearLimit = 1500000; // hạn mức BHYT mẫu
    final int used = store.yearlyNetSpend(DateTime.now().year);
    final double ratio = (used / yearLimit).clamp(0.0, 1.0);
    final bool nearLimit = ratio > 0.75;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Hạn mức BHYT đã sử dụng năm nay',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (nearLimit)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kWarning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Sắp hết hạn mức',
                        style: TextStyle(
                            fontSize: 10,
                            color: _kWarning,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                    nearLimit ? _kWarning : _kSuccess),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Đã dùng: ${_formatMoney(used)}',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text('Hạn mức: ${_formatMoney(yearLimit)}',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Bảng kê chi phí chi tiết ────────────────────────────────────────────

  Widget _buildCostBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Bảng kê chi phí khám bệnh',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('Minh bạch 100%',
                style: TextStyle(fontSize: 11, color: _kSuccess)),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              _costItem(
                title: 'Phí khám Chuyên gia Tiêu hóa',
                detail: 'PGS.TS.BS Nguyễn Văn An • Khoa Tiêu hóa - Gan mật',
                gross: 500000,
                insurance: 400000,
              ),
              const Divider(height: 1, indent: 16),
              _costItem(
                title: 'Nội soi Thực quản - Dạ dày - Tá tràng',
                detail: 'Nội soi gây mê không đau + Test vi khuẩn Hp',
                gross: 800000,
                insurance: 640000,
              ),
              const Divider(height: 1, indent: 16),
              _costItem(
                title: 'Xét nghiệm máu sinh hóa 8 chỉ số',
                detail: 'Glucose, Ure, Creatinine, AST, ALT, Mỡ máu...',
                gross: 350000,
                insurance: 280000,
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _billRow('Tổng chi phí gốc', _formatMoney(_gross)),
                    const SizedBox(height: 6),
                    _billRow('BHYT chi trả (80% đúng tuyến)',
                        '-${_formatMoney(_insurance)}',
                        color: _kSuccess),
                    const Divider(height: 20),
                    _billRow('Số tiền thực trả', _formatMoney(_net),
                        bold: true, color: _kPrimary, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _costItem({
    required String title,
    required String detail,
    required int gross,
    required int insurance,
  }) {
    final payable = gross - insurance;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.medical_services_outlined,
                    color: _kPrimary, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(detail,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Text(_formatMoney(gross),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('BHYT hỗ trợ: -${_formatMoney(insurance)}',
                  style: const TextStyle(fontSize: 11, color: _kSuccess)),
              Text('Cần trả: ${_formatMoney(payable)}',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bảo hiểm y tế ──────────────────────────────────────────────────────

  Widget _buildInsuranceCard(PatientProfile profile) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bảo hiểm y tế áp dụng',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kSuccess.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_outlined,
                      color: _kSuccess, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Thẻ BHYT Quốc gia (BHXH Việt Nam)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                          '${profile.insuranceNumber} • Liên thông Cổng BHXH',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle, color: _kSuccess),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Dữ liệu đã liên thông tự động với Cổng BHXH Quốc gia. Mức hưởng 80% đúng tuyến được áp dụng trực tiếp vào hóa đơn. Không cần xuất trình thẻ giấy.',
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ),
            const Divider(height: 24),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _privateGuarantee,
              activeThumbColor: _kSuccess,
              onChanged: (v) => setState(() => _privateGuarantee = v),
              title: const Text('Bảo lãnh viện phí tư nhân',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                _privateGuarantee
                    ? 'Đã gửi yêu cầu bảo lãnh đến đối tác bảo hiểm.'
                    : 'Gửi yêu cầu bảo lãnh trước khi thanh toán.',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            if (_privateGuarantee)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kWarning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: _kWarning.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_top, color: _kWarning, size: 16),
                    SizedBox(width: 8),
                    Text('Đang chờ xác nhận bảo lãnh từ đối tác...',
                        style: TextStyle(fontSize: 12, color: _kWarning)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Hình thức thanh toán ─────────────────────────────────────────────────

  Widget _buildPaymentMethodCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hình thức thanh toán',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _paymentOption(
              method: PaymentMethod.vietQr,
              icon: Icons.qr_code_2,
              label: 'VietQR / Napas247',
              sub: 'Khuyên dùng • Miễn phí • Quét 1 chạm',
              recommended: true,
            ),
            _paymentOption(
              method: PaymentMethod.momo,
              icon: Icons.account_balance_wallet_outlined,
              label: 'Ví MoMo',
              sub: 'Thanh toán qua ví điện tử MoMo',
            ),
            _paymentOption(
              method: PaymentMethod.zalopay,
              icon: Icons.account_balance_wallet_outlined,
              label: 'Ví ZaloPay',
              sub: 'Thanh toán qua ví điện tử ZaloPay',
            ),
            _paymentOption(
              method: PaymentMethod.vnpay,
              icon: Icons.account_balance_wallet_outlined,
              label: 'Ví VNPay',
              sub: 'Thanh toán qua VNPay QR',
            ),
            _paymentOption(
              method: PaymentMethod.bankCard,
              icon: Icons.credit_card_outlined,
              label: 'Thẻ ngân hàng',
              sub: 'Visa / MasterCard / JCB / Napas',
            ),
            _paymentOption(
              method: PaymentMethod.kiosk,
              icon: Icons.confirmation_number_outlined,
              label: 'Lấy số tại Kiosk',
              sub: 'Thanh toán tiền mặt tại quầy thu ngân',
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentOption({
    required PaymentMethod method,
    required IconData icon,
    required String label,
    required String sub,
    bool recommended = false,
  }) {
    final selected = _method == method;
    return GestureDetector(
      onTap: () => setState(() => _method = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? _kPrimary.withValues(alpha: 0.06)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _kPrimary : Colors.grey.shade200,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? _kPrimary : Colors.grey.shade600,
                size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: selected
                                  ? _kPrimary
                                  : Colors.black87)),
                      if (recommended) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _kSuccess.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Khuyên dùng',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: _kSuccess,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  Text(sub,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? _kPrimary : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // ── Hóa đơn điện tử ─────────────────────────────────────────────────────

  Widget _buildEInvoiceCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _invoiceRequested,
              activeColor: _kPrimary,
              onChanged: (v) =>
                  setState(() => _invoiceRequested = v ?? false),
              title: const Text('Xuất hóa đơn điện tử VAT y tế',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Gửi về email sau thanh toán',
                  style: TextStyle(fontSize: 12)),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (_invoiceRequested)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined,
                        size: 16, color: _kPrimary),
                    const SizedBox(width: 6),
                    Text(_email,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    TextButton(
                      onPressed: _editEmail,
                      style: TextButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8)),
                      child: const Text('Sửa'),
                    ),
                  ],
                ),
              ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.lock_outline, size: 15, color: _kSuccess),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kênh thanh toán mã hóa 256-bit TLS • Tuân thủ chuẩn PCI-DSS • Bảo vệ dữ liệu PDPA',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom bar thanh toán ───────────────────────────────────────────────

  Widget? _buildBottomBar() {
    if (_step != _PaymentStep.bill) return null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08), blurRadius: 12)
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tổng thực trả',
                    style: TextStyle(color: Colors.grey.shade600)),
                Text(_formatMoney(_net),
                    style: const TextStyle(
                        fontSize: 22,
                        color: _kPrimary,
                        fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _onPressPayNow,
                icon: Icon(
                  _method == PaymentMethod.kiosk
                      ? Icons.confirmation_number_outlined
                      : Icons.lock_outline,
                ),
                label: Text(
                  _method == PaymentMethod.kiosk
                      ? 'Lấy số Kiosk — ${_formatMoney(_net)}'
                      : 'Thanh toán ngay — ${_formatMoney(_net)}',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── View 2: QR thanh toán ─────────────────────────────────────────────

  Widget _buildQrView() {
    final mins = (_qrSecondsLeft ~/ 60).toString().padLeft(2, '0');
    final secs = (_qrSecondsLeft % 60).toString().padLeft(2, '0');
    const bankNo = '19030927612014';
    const bankName = 'Techcombank — MEDCARE HOSPITAL';
    final content = 'VPHF ${_pendingTx?.id ?? 'HS-2026-0891'}';

    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Countdown banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: _qrSecondsLeft <= 60
                  ? _kDanger.withValues(alpha: 0.1)
                  : _kWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _qrSecondsLeft <= 60
                      ? _kDanger.withValues(alpha: 0.3)
                      : _kWarning.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer_outlined,
                    color: _qrSecondsLeft <= 60 ? _kDanger : _kWarning,
                    size: 18),
                const SizedBox(width: 8),
                Text(
                  'Mã QR hết hạn sau $mins:$secs',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _qrSecondsLeft <= 60 ? _kDanger : _kWarning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // QR placeholder (simulated)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9f/VietQR_logo.png/120px-VietQR_logo.png',
                        height: 28,
                        errorBuilder: (ctx, err, st) => const Text(
                          'VietQR',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _kPrimary,
                              fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('×',
                          style: TextStyle(
                              fontSize: 18, color: Colors.black45)),
                      const SizedBox(width: 12),
                      const Text('Napas247',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // QR simulation grid
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black87, width: 3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // QR pattern simulation
                        GridView.builder(
                          padding: const EdgeInsets.all(8),
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 10),
                          itemCount: 100,
                          itemBuilder: (_, i) => Container(
                            margin: const EdgeInsets.all(0.5),
                            color: [
                                  0, 1, 2, 3, 4, 5, 6, 7, 8,
                                  9, 18, 27, 36, 45, 54, 63, 72, 81, 90,
                                  10, 11, 12, 13, 14, 20, 30, 23, 33, 43,
                                  55, 66, 77, 88, 99, 50, 51, 52, 66, 77,
                                  15, 25, 35, 45, 55
                                ].contains(i)
                                ? Colors.black87
                                : Colors.white,
                          ),
                        ),
                        // Center logo
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.local_hospital,
                              color: _kPrimary, size: 28),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    _formatMoney(_net),
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _kPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(content,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bank info
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _bankInfoRow('Ngân hàng', bankName),
                  const Divider(height: 16),
                  _bankInfoRow('Số tài khoản', bankNo, copyable: true),
                  const Divider(height: 16),
                  _bankInfoRow('Số tiền', _formatMoney(_net),
                      highlight: true),
                  const Divider(height: 16),
                  _bankInfoRow('Nội dung CK', content, copyable: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Polling status
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _kPrimary),
                ),
                SizedBox(width: 12),
                Text('Đang chờ xác nhận giao dịch...',
                    style: TextStyle(fontSize: 13, color: _kPrimary)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Download QR button
          OutlinedButton.icon(
            onPressed: () => _snack('Đang tải ảnh QR về thiết bị...'),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Tải ảnh QR'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bankInfoRow(String label, String value,
      {bool copyable = false, bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    highlight ? FontWeight.w800 : FontWeight.bold,
                color: highlight ? _kPrimary : Colors.black87,
              ),
            ),
            if (copyable) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  _snack('Đã sao chép: $value');
                },
                child: const Icon(Icons.copy_outlined,
                    size: 16, color: _kPrimary),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ── View 3: Thanh toán thành công ─────────────────────────────────────

  Widget _buildSuccessView() {
    final tx = _pendingTx;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Success icon
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: _kSuccess.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: _kSuccess, size: 56),
            ),
            const SizedBox(height: 20),
            const Text('Thanh toán thành công!',
                style:
                    TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Cảm ơn bạn đã sử dụng dịch vụ MedCare',
                style:
                    TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 32),

            // Receipt card
            Card(
              elevation: 0,
              color: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _receiptRow('Số tiền đã trả', _formatMoney(_net),
                        valueStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: _kPrimary)),
                    const Divider(height: 24),
                    _receiptRow('Mã giao dịch', tx?.id ?? 'TXN-000'),
                    const SizedBox(height: 8),
                    _receiptRow('Mã hóa đơn',
                        tx?.receiptCode ?? 'RC-000000'),
                    const SizedBox(height: 8),
                    _receiptRow('Phương thức',
                        tx?.methodLabel ?? 'VietQR'),
                    const SizedBox(height: 8),
                    _receiptRow('Thời gian',
                        _formatDateTime(tx?.timestamp ?? DateTime.now())),
                    const SizedBox(height: 8),
                    _receiptRow('Đợt khám',
                        tx?.visitCode ?? '#HS-2026-0891'),
                    if (_invoiceRequested) ...[
                      const SizedBox(height: 8),
                      _receiptRow('Hóa đơn VAT', _email),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Actions
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    _snack('Đang xuất hóa đơn điện tử PDF...'),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Xem hóa đơn điện tử (PDF)'),
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _snack('Đang chia sẻ biên lai...'),
                icon: const Icon(Icons.share_outlined),
                label: const Text('Chia sẻ biên lai'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => setState(() {
                _step = _PaymentStep.bill;
                _pendingTx = null;
              }),
              child: const Text('Về danh sách viện phí'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value,
      {TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        Text(value,
            style: valueStyle ??
                const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ── Tab lịch sử giao dịch ─────────────────────────────────────────────

  Widget _historyTab(MedicalStore store) {
    final txList = store.transactions;
    final thisYear = DateTime.now().year;
    final spent = store.yearlyNetSpend(thisYear);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Tổng kết năm
        Card(
          elevation: 0,
          color: _kPrimary.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.bar_chart, color: _kPrimary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chi phí y tế năm $thisYear',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600)),
                      Text(_formatMoney(spent),
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _kPrimary)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      _snack('Đang xuất báo cáo chi phí năm $thisYear...'),
                  child: const Text('Xuất báo cáo'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Tất cả giao dịch',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (txList.isEmpty)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Chưa có giao dịch nào.')))
        else
          ...txList.map((tx) => _transactionCard(tx)),
      ],
    );
  }

  Widget _transactionCard(PaymentTransaction tx) {
    final statusColor = switch (tx.status) {
      PaymentStatus.success => _kSuccess,
      PaymentStatus.pending => _kWarning,
      PaymentStatus.failed => _kDanger,
      PaymentStatus.refunded => Colors.purple,
    };
    final statusIcon = switch (tx.status) {
      PaymentStatus.success => Icons.check_circle_outlined,
      PaymentStatus.pending => Icons.access_time_outlined,
      PaymentStatus.failed => Icons.cancel_outlined,
      PaymentStatus.refunded => Icons.replay_outlined,
    };

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.description,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(
                    '${tx.visitCode} • ${tx.methodLabel}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(tx.timestamp),
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  (tx.status == PaymentStatus.refunded ? '+' : '') +
                      _formatMoney(tx.netAmount),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: tx.status == PaymentStatus.refunded
                        ? _kSuccess
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tx.statusLabel,
                    style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Kiosk dialog ──────────────────────────────────────────────────────────

  void _showKioskDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.confirmation_number, color: _kPrimary),
            SizedBox(width: 8),
            Text('Số thanh toán Kiosk'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('K-042',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: _kPrimary)),
                  Text('Số thứ tự',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Vui lòng đến Kiosk thu ngân tầng 1\nXuất trình mã bệnh nhân: MC-89241',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _onPressPayNow() {
    if (_method == PaymentMethod.kiosk) {
      _showKioskDialog();
      return;
    }

    final store = MedicalScope.of(context);
    final tx = store.addTransaction(
      visitCode: '#HS-2026-0891',
      description: 'Khám Tiêu hóa + Nội soi + XN máu',
      grossAmount: _gross,
      insuranceAmount: _insurance,
      netAmount: _net,
      method: _method,
      walletName: switch (_method) {
        PaymentMethod.momo => 'MoMo',
        PaymentMethod.zalopay => 'ZaloPay',
        PaymentMethod.vnpay => 'VNPay',
        _ => null,
      },
      invoiceEmail: _invoiceRequested ? _email : null,
    );

    setState(() {
      _pendingTx = tx;
      _qrSecondsLeft = 900;
      _step = _PaymentStep.qr;
    });

    _startQrTimer(store, tx.id);
  }

  void _startQrTimer(MedicalStore store, String txId) {
    _qrTimer?.cancel();
    _qrTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _qrSecondsLeft--);
      if (_qrSecondsLeft <= 0) {
        t.cancel();
        _snack('Mã QR đã hết hạn. Vui lòng tạo lại.');
        setState(() => _step = _PaymentStep.bill);
      }
    });

    // Simulate payment polling: success after 4 seconds
    _pollTimer?.cancel();
    _pollTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      _qrTimer?.cancel();
      store.completeTransaction(txId);
      final updated = store.transactions.firstWhere((t) => t.id == txId);
      setState(() {
        _pendingTx = updated;
        _step = _PaymentStep.success;
      });
    });
  }

  void _downloadStatement() => _snack('Đang chuẩn bị bảng kê chi phí PDF...');

  void _editEmail() {
    final ctrl = TextEditingController(text: _email);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Email nhận hóa đơn'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              setState(() => _email = ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _billRow(String label, String value,
      {bool bold = false, Color? color, double? size}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontSize: 13)),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: size ?? 13,
                fontWeight:
                    bold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      );

  String _formatMoney(int amount) {
    final s = amount.toString();
    final result = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write('.');
      result.write(s[i]);
    }
    return '${result.toString()}đ';
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatDateTime(DateTime dt) => _formatDate(dt);
}

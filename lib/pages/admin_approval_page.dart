import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../state/medical_store.dart';

const _approvalBlue = Color(0xFF0D6EFD);
const _approvalGreen = Color(0xFF0F8A55);
const _approvalRed = Color(0xFFBA1A1A);

class AdminApprovalPage extends StatefulWidget {
  const AdminApprovalPage({super.key});

  @override
  State<AdminApprovalPage> createState() => _AdminApprovalPageState();
}

class _AdminApprovalPageState extends State<AdminApprovalPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _loading = true;
  String? _error;
  List<Map<String, Object?>> _payments = const [];
  List<Map<String, Object?>> _claims = const [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final store = MedicalScope.of(context);
    if (!store.isAdminRole) {
      setState(() {
        _loading = false;
        _error = 'Chỉ tài khoản admin mới được duyệt thanh toán và bảo lãnh.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await store.refreshBackendSessionOnline();
      final result = await Future.wait<List<Map<String, Object?>>>([
        store.fetchAdminPaymentsOnline(),
        store.fetchCashlessClaimsOnline(),
      ]);
      if (!mounted) return;
      var payments = result[0];
      if (payments.isEmpty && store.transactions.isNotEmpty) {
        payments = store.transactions
            .map(
              (tx) => {
                'id': tx.id,
                'clientTransactionId': tx.id,
                'amount': tx.netAmount,
                'status': switch (tx.status) {
                  PaymentStatus.success => 'success',
                  PaymentStatus.failed => 'failed',
                  PaymentStatus.refunded => 'refunded',
                  _ => 'pending',
                },
                'method': tx.method.name,
                'packageTitle': tx.description,
                'appointmentId': tx.visitCode,
              },
            )
            .toList();
      }
      var claims = result[1];
      if (claims.isEmpty && store.cashlessClaims.isNotEmpty) {
        claims = store.cashlessClaims
            .map(
              (c) => {
                'id': c.id,
                'policyNumber': c.policyNumber,
                'providerName': c.providerName,
                'hospitalBillId': c.hospitalBillId,
                'totalBill': c.totalBill,
                'coveredAmount': c.coveredAmount,
                'patientCoPay': c.patientCoPay,
                'status': c.status.name,
                'requestedAt': c.requestedAt.toIso8601String(),
                'approvalCode': c.approvalCode,
              },
            )
            .toList();
      }
      setState(() {
        _payments = payments;
        _claims = claims;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      final localPayments = store.transactions
          .map(
            (tx) => {
              'id': tx.id,
              'clientTransactionId': tx.id,
              'amount': tx.netAmount,
              'status': switch (tx.status) {
                PaymentStatus.success => 'success',
                PaymentStatus.failed => 'failed',
                PaymentStatus.refunded => 'refunded',
                _ => 'pending',
              },
              'method': tx.method.name,
              'packageTitle': tx.description,
              'appointmentId': tx.visitCode,
            },
          )
          .toList();
      final localClaims = store.cashlessClaims
          .map(
            (c) => {
              'id': c.id,
              'policyNumber': c.policyNumber,
              'providerName': c.providerName,
              'hospitalBillId': c.hospitalBillId,
              'totalBill': c.totalBill,
              'coveredAmount': c.coveredAmount,
              'patientCoPay': c.patientCoPay,
              'status': c.status.name,
              'requestedAt': c.requestedAt.toIso8601String(),
              'approvalCode': c.approvalCode,
            },
          )
          .toList();
      setState(() {
        _payments = localPayments;
        _claims = localClaims;
        _loading = false;
        _error = localPayments.isEmpty && localClaims.isEmpty ? '$error' : null;
      });
    }
  }

  Future<void> _reviewPayment(
    Map<String, Object?> payment, {
    required bool approve,
  }) async {
    final clientId = payment['clientTransactionId']?.toString() ?? '';
    if (clientId.isEmpty) return;
    final receiptController = TextEditingController();
    final receipt = approve
        ? await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Duyệt thanh toán'),
              content: TextField(
                controller: receiptController,
                decoration: const InputDecoration(
                  labelText: 'Mã biên lai / mã đối soát',
                  hintText: 'Có thể nhập sau nếu chưa có',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, receiptController.text),
                  child: const Text('Duyệt thành công'),
                ),
              ],
            ),
          )
        : '';
    receiptController.dispose();
    if (receipt == null || !mounted) return;

    try {
      await MedicalScope.of(context).reviewPaymentOnline(
        clientTransactionId: clientId,
        status: approve ? 'success' : 'failed',
        receiptCode: receipt,
      );
      if (!mounted) return;
      _showMessage(approve ? 'Đã duyệt thanh toán.' : 'Đã từ chối thanh toán.');
      await _load();
    } catch (error) {
      if (mounted) _showMessage('Không thể cập nhật thanh toán: $error');
    }
  }

  Future<void> _reviewClaim(
    Map<String, Object?> claim, {
    required bool approve,
  }) async {
    final id = claim['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Duyệt bảo lãnh viện phí' : 'Từ chối bảo lãnh'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Ghi chú xét duyệt',
            hintText: 'Nêu căn cứ hoặc lý do xử lý',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: approve ? _approvalGreen : _approvalRed,
            ),
            onPressed: () => Navigator.pop(ctx, noteController.text),
            child: Text(approve ? 'Duyệt yêu cầu' : 'Từ chối yêu cầu'),
          ),
        ],
      ),
    );
    noteController.dispose();
    if (note == null || !mounted) return;

    try {
      await MedicalScope.of(context).reviewCashlessClaimOnline(
        claimId: id,
        status: approve ? 'approved' : 'rejected',
        note: note,
      );
      if (!mounted) return;
      _showMessage(approve ? 'Đã duyệt bảo lãnh.' : 'Đã từ chối bảo lãnh.');
      await _load();
    } catch (error) {
      if (mounted) _showMessage('Không thể cập nhật bảo lãnh: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    if (!store.isAdminRole) {
      return Scaffold(
        appBar: AppBar(title: const Text('Không có quyền truy cập')),
        body: Center(child: Text(_error ?? 'Chỉ admin được truy cập.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyệt nghiệp vụ'),
        actions: [
          IconButton(
            tooltip: 'Tải lại từ backend',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: 'Thanh toán (${_pendingPaymentCount()})'),
            Tab(text: 'Bảo lãnh (${_pendingClaimCount()})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _errorView()
          : TabBarView(
              controller: _tabs,
              children: [_paymentList(), _claimList()],
            ),
    );
  }

  int _pendingPaymentCount() =>
      _payments.where((item) => item['status'] == 'pending').length;

  int _pendingClaimCount() => _claims
      .where(
        (item) =>
            item['status'] == 'pending_verification' ||
            item['status'] == 'pending',
      )
      .length;

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    ),
  );

  Widget _paymentList() {
    if (_payments.isEmpty) return _empty('Chưa có yêu cầu thanh toán.');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _payments.length,
        itemBuilder: (_, index) => _paymentCard(_payments[index]),
      ),
    );
  }

  Widget _claimList() {
    if (_claims.isEmpty) return _empty('Chưa có yêu cầu bảo lãnh.');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _claims.length,
        itemBuilder: (_, index) => _claimCard(_claims[index]),
      ),
    );
  }

  Widget _paymentCard(Map<String, Object?> payment) {
    final status = payment['status']?.toString() ?? 'pending';
    final pending = status == 'pending';
    final amount = payment['amount'];
    final amountText = amount is num ? '${amount.toInt()}đ' : '$amount';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payments_outlined, color: _approvalBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    amountText,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _statusChip(status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Giao dịch: ${payment['clientTransactionId'] ?? payment['id']}',
            ),
            if (payment['purpose']?.toString() == 'wallet_topup')
              const Text(
                'Loại: Nạp ví MedCare Pay (duyệt thủ công)',
                style: TextStyle(
                  color: _approvalBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (payment['purpose']?.toString() == 'pharmacy_order')
              const Text(
                'Loại: Thanh toán đơn thuốc / giao thuốc',
                style: TextStyle(
                  color: _approvalBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            Text('Phương thức: ${payment['method'] ?? 'Không rõ'}'),
            if ((payment['packageTitle']?.toString() ?? '').isNotEmpty)
              Text('Gói khám: ${payment['packageTitle']}'),
            if ((payment['appointmentId']?.toString() ?? '').isNotEmpty)
              Text('Lịch hẹn: ${payment['appointmentId']}'),
            if (pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _reviewPayment(payment, approve: true),
                      icon: const Icon(Icons.check),
                      label: const Text('Duyệt'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _approvalGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _reviewPayment(payment, approve: false),
                      icon: const Icon(Icons.close),
                      label: const Text('Từ chối'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _approvalRed,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _claimCard(Map<String, Object?> claim) {
    final status = claim['status']?.toString() ?? 'pending_verification';
    final pending = status == 'pending_verification' || status == 'pending';
    final payload = claim['payload'];
    final data = payload is Map
        ? Map<String, Object?>.from(payload)
        : const <String, Object?>{};
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.health_and_safety_outlined,
                  color: _approvalBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data['provider']?.toString() ?? 'Yêu cầu bảo lãnh viện phí',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                _statusChip(status),
              ],
            ),
            const SizedBox(height: 8),
            Text('Bệnh nhân: ${data['patientName'] ?? 'Chưa cập nhật'}'),
            Text('Số tiền dự kiến: ${data['amount'] ?? 'Chưa cập nhật'}'),
            Text('Mã hồ sơ: ${claim['id'] ?? ''}'),
            if (pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _reviewClaim(claim, approve: true),
                      icon: const Icon(Icons.verified),
                      label: const Text('Duyệt bảo lãnh'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _approvalGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _reviewClaim(claim, approve: false),
                      icon: const Icon(Icons.block),
                      label: const Text('Từ chối'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _approvalRed,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = switch (status) {
      'success' || 'approved' => _approvalGreen,
      'failed' || 'rejected' => _approvalRed,
      _ => Colors.orange.shade800,
    };
    return Chip(
      label: Text(status),
      labelStyle: TextStyle(color: color, fontSize: 11),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.25)),
    );
  }

  Widget _empty(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}

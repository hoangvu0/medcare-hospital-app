import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../state/medical_store.dart';

class InsuranceGuaranteePage extends StatefulWidget {
  const InsuranceGuaranteePage({super.key});

  @override
  State<InsuranceGuaranteePage> createState() => _InsuranceGuaranteePageState();
}

class _InsuranceGuaranteePageState extends State<InsuranceGuaranteePage> {
  int _selectedBill = 750000;
  String _selectedProvider = 'Bảo Việt An Gia (Bảo Việt Tokio Marine)';
  int _selectedCoverPercent = 100;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final policies = store.insurancePolicies;
    final claims = store.cashlessClaims;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảo Hiểm & Bảo Lãnh Viện Phí'),
        backgroundColor: const Color(0xFF006C49),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner BHYT & Direct Billing
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF006C49), Color(0xFF004D34)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x30006C49),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_user, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'BẢO LÃNH VIỆN PHÍ TRỰC TIẾP (CASHLESS)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Khám Chữa Bệnh Không Tiền Mặt',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Bệnh viện MedCare liên kết trực tiếp với BHYT Quốc Gia & 15+ hãng bảo hiểm tư nhân hàng đầu. Viện phí được khấu trừ tự động, người bệnh không phải ứng tiền trước.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'THẺ BẢO HIỂM ĐÃ ĐĂNG KÝ LIÊN THÔNG',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006C49),
            ),
          ),
          const SizedBox(height: 10),

          // Danh sách các thẻ bảo hiểm
          ...policies.map((p) => _buildPolicyCard(context, p, isDark)),
          const SizedBox(height: 16),

          // Yêu cầu bảo lãnh viện phí. Việc duyệt phải đến từ hệ thống bảo hiểm.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF006C49), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_long, color: Color(0xFF006C49)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'YÊU CẦU BẢO LÃNH VIỆN PHÍ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006C49),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                const Text(
                  'Chọn khoản chi phí khám / cận lâm sàng:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _billChoice(450000, 'Khám chuyên khoa (450k)'),
                    _billChoice(750000, 'Khám + Xét nghiệm (750k)'),
                    _billChoice(1500000, 'Combo Chẩn đoán hình ảnh (1.5tr)'),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Chọn đơn vị bảo lãnh chi trả:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedProvider,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: policies
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.providerName,
                          child: Text(
                            p.providerName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedProvider = val;
                        final found = policies.firstWhere(
                          (p) => p.providerName == val,
                        );
                        _selectedCoverPercent = found.coveragePercent;
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),
                // Tóm tắt chi phí
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tổng viện phí gốc:',
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            '.000đ',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          Text(
                            'Bảo hiểm chi trả (%):',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF006C49),
                            ),
                          ),
                          Text(
                            '- .000đ',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF006C49),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Bệnh nhân Đồng chi trả (Co-pay):',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '.000đ',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            setState(() => _isSubmitting = true);
                            final policy = policies.firstWhere(
                              (p) => p.providerName == _selectedProvider,
                            );
                            try {
                              final claim = await store
                                  .submitCashlessClaimOnlineFirst(
                                    policyNumber: policy.policyNumber,
                                    providerName: policy.providerName,
                                    totalBill: _selectedBill,
                                    coveredPercent: _selectedCoverPercent,
                                  );
                              if (context.mounted) {
                                _showClaimSuccessDialog(context, claim);
                              }
                            } catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Không thể gửi yêu cầu: $error',
                                    ),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isSubmitting = false);
                              }
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF006C49),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.flash_on),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'GỬI YÊU CẦU BẢO LÃNH',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Lịch sử yêu cầu và kết quả bảo lãnh
          if (claims.isNotEmpty) ...[
            const Text(
              'LỊCH SỬ YÊU CẦU BẢO LÃNH VIỆN PHÍ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ...claims.map((c) => _buildClaimHistoryCard(c, isDark)),
          ],
        ],
      ),
    );
  }

  Widget _billChoice(int amount, String label) {
    final isSel = _selectedBill == amount;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSel ? Colors.white : null,
        ),
      ),
      selected: isSel,
      selectedColor: const Color(0xFF006C49),
      onSelected: (_) => setState(() => _selectedBill = amount),
    );
  }

  Widget _buildPolicyCard(
    BuildContext context,
    InsurancePolicy policy,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(policy.logoEmoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      policy.providerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Số thẻ: ${policy.policyNumber}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Chi trả ${policy.coveragePercent}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006C49),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Hạn mức Ngoại trú: ${policy.outpatientLimit ~/ 1000}.000đ/năm',
                style: const TextStyle(fontSize: 11),
              ),
              Text(
                'Còn lại: ${policy.remainingOutpatient ~/ 1000}.000đ',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClaimHistoryCard(CashlessClaimRequest claim, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: claim.status == CashlessClaimStatus.approved
              ? const Color(0xFFE8F5E9)
              : const Color(0xFFFFF7ED),
          child: Icon(
            claim.status == CashlessClaimStatus.approved
                ? Icons.check
                : Icons.hourglass_top,
            color: claim.status == CashlessClaimStatus.approved
                ? const Color(0xFF006C49)
                : Colors.orange,
          ),
        ),
        title: Text(
          '${claim.providerName} • ${_claimStatusLabel(claim.status)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        subtitle: Text(
          'Số tiền: ${claim.totalBill ~/ 1000}.000đ • Đồng chi trả: ${claim.patientCoPay ~/ 1000}.000đ',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Icon(
          claim.status == CashlessClaimStatus.approved
              ? Icons.verified
              : Icons.pending_actions,
          color: claim.status == CashlessClaimStatus.approved
              ? Colors.green
              : Colors.orange,
          size: 18,
        ),
      ),
    );
  }

  String _claimStatusLabel(CashlessClaimStatus status) => switch (status) {
    CashlessClaimStatus.pending => 'Đang chờ xác minh',
    CashlessClaimStatus.approved => 'Đã được duyệt',
    CashlessClaimStatus.rejected => 'Bị từ chối',
  };

  void _showClaimSuccessDialog(
    BuildContext context,
    CashlessClaimRequest claim,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Đã gửi yêu cầu bảo lãnh'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trạng thái: ${_claimStatusLabel(claim.status)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text('Đơn vị bảo hiểm: ${claim.providerName}'),
            Text('Số tiền yêu cầu: ${claim.totalBill ~/ 1000}.000đ'),
            Text(
              'Số tiền đồng chi trả dự kiến: ${claim.patientCoPay ~/ 1000}.000đ',
            ),
            const SizedBox(height: 10),
            const Text(
              'Yêu cầu đã được lưu. Hệ thống sẽ cập nhật khi bảo hiểm/HIS phản hồi xác minh.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hoàn tất'),
          ),
        ],
      ),
    );
  }
}

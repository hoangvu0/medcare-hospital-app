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
                BoxShadow(color: Color(0x30006C49), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_user, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'BẢO LÃNH VIỆN PHÍ TRỰC TIẾP (CASHLESS)',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Khám Chữa Bệnh Không Tiền Mặt',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Bệnh viện MedCare liên kết trực tiếp với BHYT Quốc Gia & 15+ hãng bảo hiểm tư nhân hàng đầu. Viện phí được khấu trừ tự động, người bệnh không phải ứng tiền trước.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          const Text('THẺ BẢO HIỂM ĐÃ ĐĂNG KÝ LIÊN THÔNG', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF006C49))),
          const SizedBox(height: 10),

          // Danh sách các thẻ bảo hiểm
          ...policies.map((p) => _buildPolicyCard(context, p, isDark)),
          const SizedBox(height: 16),

          // Mô phỏng Bảo Lãnh Viện Phí Trực Tiếp (Cashless Claim Simulator)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF006C49), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_long, color: Color(0xFF006C49)),
                    SizedBox(width: 8),
                    Text(
                      'MÔ PHỎNG BẢO LÃNH VIỆN PHÍ TẠI VIỆN',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF006C49)),
                    ),
                  ],
                ),
                const Divider(height: 20),
                const Text('Chọn khoản chi phí khám / cận lâm sàng:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
                const Text('Chọn đơn vị bảo lãnh chi trả:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedProvider,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: policies.map((p) => DropdownMenuItem(value: p.providerName, child: Text(' ', style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedProvider = val;
                        final found = policies.firstWhere((p) => p.providerName == val);
                        _selectedCoverPercent = found.coveragePercent;
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),
                // Tóm tắt chi phí
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng viện phí gốc:', style: TextStyle(fontSize: 12)),
                          Text('.000đ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Bảo hiểm chi trả (%):', style: const TextStyle(fontSize: 12, color: Color(0xFF006C49))),
                          Text('- .000đ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF006C49))),
                        ],
                      ),
                      const Divider(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Bệnh nhân Đồng chi trả (Co-pay):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text(
                            '.000đ',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue),
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
                        : () {
                            setState(() => _isSubmitting = true);
                            final policy = policies.firstWhere((p) => p.providerName == _selectedProvider);
                            final claim = store.submitCashlessClaim(
                              policyNumber: policy.policyNumber,
                              providerName: policy.providerName,
                              totalBill: _selectedBill,
                              coveredPercent: _selectedCoverPercent,
                            );
                            setState(() => _isSubmitting = false);
                            _showClaimSuccessDialog(context, claim);
                          },
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF006C49), padding: const EdgeInsets.symmetric(vertical: 12)),
                    icon: const Icon(Icons.flash_on),
                    label: const Text('GỬI YÊU CẦU BẢO LÃNH TỨC THÌ (30S)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Lịch sử bảo lãnh đã duyệt
          if (claims.isNotEmpty) ...[
            const Text('LỊCH SỬ BẢO LÃNH VIỆN PHÍ ĐÃ DUYỆT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
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
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? Colors.white : null)),
      selected: isSel,
      selectedColor: const Color(0xFF006C49),
      onSelected: (_) => setState(() => _selectedBill = amount),
    );
  }

  Widget _buildPolicyCard(BuildContext context, InsurancePolicy policy, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
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
                    Text(policy.providerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('Số thẻ: ', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(6)),
                child: Text('Chi trả %', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF006C49))),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hạn mức Ngoại trú: tr/năm', style: const TextStyle(fontSize: 11)),
              Text('Còn lại: .000đ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
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
        leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.check, color: Color(0xFF006C49))),
        title: Text(' • Đã duyệt .000đ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        subtitle: Text('Mã duyệt:  • Đồng chi trả: .000đ', style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.verified, color: Colors.green, size: 18),
      ),
    );
  }

  void _showClaimSuccessDialog(BuildContext context, CashlessClaimRequest claim) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Bảo lãnh Thành Công!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mã phê duyệt: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006C49))),
            const SizedBox(height: 6),
            Text('Đơn vị bảo hiểm: '),
            Text('Số tiền bảo lãnh chi trả: .000đ'),
            Text('Số tiền bạn đồng chi trả: .000đ'),
            const SizedBox(height: 10),
            const Text('Hóa đơn đã được ghi nhận tự động vào hệ thống HIS và nhật ký bảo mật của Bệnh viện.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hoàn tất')),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../state/medical_store.dart';

class HealthPackagesPage extends StatelessWidget {
  const HealthPackagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final packages = store.healthPackages;

    return Scaffold(
      appBar: AppBar(title: const Text('Gói Khám Sức Khỏe & Tầm Soát')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0057CD), Color(0xFF003882)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chủ động Bảo vệ Sức khỏe Cùng MedCare',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Phát hiện sớm các bệnh lý hiểm nghèo, tiết kiệm tới 25% chi phí so với khám lẻ từng dịch vụ.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...packages.map((pkg) => _buildPackageCard(context, pkg)),
        ],
      ),
    );
  }

  Widget _buildPackageCard(BuildContext context, HealthPackage pkg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: pkg.isPopular
              ? const Color(0xFF0057CD)
              : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          width: pkg.isPopular ? 1.5 : 1,
        ),
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
          if (pkg.isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFF0057CD),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Center(
                child: Text(
                  '★ GÓI KHÁM ĐƯỢC CHỌN NHIỀU NHẤT ★',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pkg.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pkg.subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    Text(
                      '${pkg.price ~/ 1000}.000đ',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0057CD),
                      ),
                    ),
                    Text(
                      '${pkg.originalPrice ~/ 1000}.000đ',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_pin_outlined,
                        size: 16,
                        color: Color(0xFF0057CD),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đối tượng: ${pkg.targetGroup}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24),
                const Text(
                  'Quyền lợi nổi bật:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 6),
                ...pkg.benefits.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(b, style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      _showPackageDetailDialog(context, pkg);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Xem chi tiết danh mục & Đăng ký'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPackageDetailDialog(BuildContext context, HealthPackage pkg) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(pkg.title, style: const TextStyle(fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Giá gói: ${pkg.price ~/ 1000}.000đ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0057CD),
                ),
              ),
              const Divider(height: 18),
              const Text(
                'Danh mục các dịch vụ thực hiện:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ...pkg.items.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${entry.key + 1}. ${entry.value}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final messenger = ScaffoldMessenger.of(context);
              try {
                final requestId = await MedicalScope.of(context)
                    .submitPackageRequest(
                      category: 'Đăng ký gói tầm soát',
                      packageId: pkg.id,
                      packageTitle: pkg.title,
                      amount: pkg.price,
                      details: 'Danh mục: ${pkg.items.join('; ')}',
                    );
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Đã gửi yêu cầu ${pkg.title}. Mã xử lý: $requestId. Admin sẽ tiếp nhận và hướng dẫn thanh toán.',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (error) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Chưa gửi được yêu cầu: $error')),
                );
              }
            },
            child: const Text('Xác nhận đăng ký'),
          ),
        ],
      ),
    );
  }
}

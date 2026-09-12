import 'package:flutter/material.dart';

import '../state/medical_store.dart';

class VaccinationPage extends StatelessWidget {
  const VaccinationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final vaccines = store.vaccineRecords;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sổ Tiêm chủng Điện tử'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mũi tiêm của tôi'),
              Tab(text: 'Danh mục Vắc-xin'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: My vaccines
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF93C5FD)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF0057CD),
                        child: Icon(Icons.verified, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hộ chiếu Vắc-xin: ${store.profile.name}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Mã BN: ${store.profile.id} • Đã tiêm ${vaccines.length} mũi phòng bệnh',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Next dose countdown
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.alarm_on_rounded, color: Color(0xFF10B981), size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LỊCH TIÊM NHẮC KẾ TIẾP: CÒN 38 NGÀY',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF065F46)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Vắc-xin Phế cầu 13 (Prevenar 13) • 20/04/2026',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Phòng ngừa viêm phổi, viêm màng não do phế cầu khuẩn.',
                              style: TextStyle(fontSize: 11, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Mở QR Hộ chiếu tiêm chủng',
                        icon: const Icon(Icons.qr_code_2, color: Color(0xFF0057CD), size: 30),
                        onPressed: () => _showVaccinePassportDialog(context, store),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...vaccines.map((v) => _buildVaccineCard(context, v)),
              ],
            ),

            // Tab 2: Catalog
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildCatalogItem(
                  context,
                  name: 'Gardasil 9 (Mỹ)',
                  target: 'Phòng ung thư cổ tử cung & u nhú do HPV 9 chủng',
                  price: '2.950.000đ / mũi',
                  origin: 'Hãng MSD - Hoa Kỳ',
                ),
                _buildCatalogItem(
                  context,
                  name: 'Influvac Tetra (Hà Lan)',
                  target: 'Phòng cúm mùa 4 chủng (A/H1N1, A/H3N2, B)',
                  price: '380.000đ / mũi',
                  origin: 'Hãng Abbott - Hà Lan',
                ),
                _buildCatalogItem(
                  context,
                  name: 'Prevenar 13 (Bỉ)',
                  target: 'Phòng viêm phổi, viêm màng não do phế cầu khuẩn',
                  price: '1.290.000đ / mũi',
                  origin: 'Hãng Pfizer - Bỉ',
                ),
                _buildCatalogItem(
                  context,
                  name: 'Verorab (Pháp)',
                  target: 'Vắc-xin phòng bệnh Dại tinh chế',
                  price: '450.000đ / mũi',
                  origin: 'Hãng Sanofi Pasteur - Pháp',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaccineCard(BuildContext context, dynamic item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.vaccineName as String,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.status as String,
                  style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Phòng bệnh: ${item.diseaseTarget}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF0057CD), fontWeight: FontWeight.w500),
          ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Liều: ${item.doseNumber}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text('Ngày tiêm: ${item.dateAdministered}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Số lô: ${item.batchNumber}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(item.facility as String, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          if (item.nextDoseDate != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event, size: 14, color: Colors.amber),
                  const SizedBox(width: 6),
                  Text(
                    'Mũi nhắc lại dự kiến: ${item.nextDoseDate}',
                    style: const TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCatalogItem(
    BuildContext context, {
    required String name,
    required String target,
    required String price,
    required String origin,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE0E7FF),
            child: const Icon(Icons.vaccines, color: Color(0xFF0057CD)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(target, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(origin, style: const TextStyle(fontSize: 11, color: Color(0xFF0057CD))),
                const SizedBox(height: 4),
                Text(price, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã chọn đăng ký tiêm $name. Nhân viên tư vấn tiêm chủng sẽ liên hệ!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: const Text('Đăng ký', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showVaccinePassportDialog(BuildContext context, MedicalStore store) {
    final profile = store.activeFamilyMember;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Hộ chiếu Vắc-xin Điện tử'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(Icons.qr_code_2, size: 140, color: Color(0xFF0057CD)),
            ),
            const SizedBox(height: 12),
            Text(
              profile.name.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'BHYT: ${profile.insuranceNumber} • Sinh: ${profile.dateOfBirth}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
                  SizedBox(width: 4),
                  Text('CHỨNG NHẬN TIÊM ĐỦ LIỀU CƠ BẢN',
                      style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }
}


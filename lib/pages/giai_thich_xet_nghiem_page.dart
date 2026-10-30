import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../state/medical_store.dart';

class LabExplainerPage extends StatefulWidget {
  const LabExplainerPage({super.key});

  @override
  State<LabExplainerPage> createState() => _LabExplainerPageState();
}

class _LabExplainerPageState extends State<LabExplainerPage> {
  String _selectedFilter = 'all'; // all, hematology, biochemistry, abnormal

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final allLabs = store.labReports;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredLabs = allLabs.where((item) {
      if (_selectedFilter == 'hematology') {
        return item.category == LabCategory.hematology;
      }
      if (_selectedFilter == 'biochemistry') {
        return item.category == LabCategory.biochemistry;
      }
      if (_selectedFilter == 'abnormal') {
        return item.riskLevel != LabRiskLevel.normal;
      }
      return true;
    }).toList();

    final normalCount = allLabs
        .where((i) => i.riskLevel == LabRiskLevel.normal)
        .length;
    final warningCount = allLabs
        .where((i) => i.riskLevel == LabRiskLevel.warning)
        .length;
    final criticalCount = allLabs
        .where((i) => i.riskLevel == LabRiskLevel.critical)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ Lý AI Diễn Giải Xét Nghiệm'),
        backgroundColor: const Color(0xFF0057CD),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner Tóm tắt AI
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0057CD), Color(0xFF003882)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x300057CD),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 18,
                      child: Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF0057CD),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'AI Y KHOA PHÂN TÍCH KẾT QUẢ',
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
                const SizedBox(height: 12),
                const Text(
                  'Phiếu xét nghiệm Sinh hóa & Huyết học ngày 12/03/2026',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hệ thống AI đối chiếu theo tiêu chuẩn ADA (Hoa Kỳ) & EASL (Châu Âu), tự động giải thích ý nghĩa bệnh lý bằng tiếng Việt dễ hiểu.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statusBadge(
                      '$normalCount Bình thường',
                      Colors.green.shade100,
                      Colors.green.shade900,
                    ),
                    _statusBadge(
                      '$warningCount Chú ý',
                      Colors.amber.shade100,
                      Colors.amber.shade900,
                    ),
                    _statusBadge(
                      '$criticalCount Vượt ngưỡng',
                      Colors.red.shade100,
                      Colors.red.shade900,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bộ lọc danh mục
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Tất cả (${allLabs.length})', 'all'),
                const SizedBox(width: 8),
                _filterChip(
                  'Cần lưu ý (${warningCount + criticalCount})',
                  'abnormal',
                ),
                const SizedBox(width: 8),
                _filterChip('Huyết học (4)', 'hematology'),
                const SizedBox(width: 8),
                _filterChip('Sinh hóa máu (8)', 'biochemistry'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Danh sách các chỉ số xét nghiệm
          ...filteredLabs.map(
            (item) => _buildLabItemCard(context, item, isDark),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : null,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF0057CD),
      onSelected: (_) => setState(() => _selectedFilter = value),
    );
  }

  Widget _statusBadge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLabItemCard(
    BuildContext context,
    LabReportItem item,
    bool isDark,
  ) {
    final statusColor = switch (item.riskLevel) {
      LabRiskLevel.normal => const Color(0xFF006C49),
      LabRiskLevel.warning => const Color(0xFFB45309),
      LabRiskLevel.critical => const Color(0xFFBA1A1A),
    };

    final statusBg = switch (item.riskLevel) {
      LabRiskLevel.normal => const Color(0xFFE8F5E9),
      LabRiskLevel.warning => const Color(0xFFFEF3C7),
      LabRiskLevel.critical => const Color(0xFFFFDAD6),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.riskLevel == LabRiskLevel.critical
              ? Colors.red.shade300
              : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          width: item.riskLevel == LabRiskLevel.critical ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.code,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Khoảng tham chiếu: ',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      ' ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.riskLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 18),
            // Hộp AI giải thích
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.psychology,
                        size: 15,
                        color: Color(0xFF0057CD),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Ý nghĩa lâm sàng (AI Tóm tắt):',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0057CD),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.clinicalMeaning,
                    style: const TextStyle(fontSize: 12, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.restaurant, size: 14, color: Colors.green),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Chế độ ăn uống khuyên dùng:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.dietaryAdvice,
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

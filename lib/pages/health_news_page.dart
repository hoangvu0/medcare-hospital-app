import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../state/medical_store.dart';

class HealthNewsPage extends StatelessWidget {
  const HealthNewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final articles = store.healthArticles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cẩm nang Y khoa & Sức khỏe'),
      ),
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
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.menu_book_rounded, color: Color(0xFF0057CD)),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kiến thức Y khoa Chính thống',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Được biên soạn và kiểm duyệt bởi Hội đồng Bác sĩ MedCare.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...articles.map((art) => _buildArticleCard(context, art)),
        ],
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, HealthArticle art) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openArticleDetail(context, art),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0057CD).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      art.category,
                      style: const TextStyle(color: Color(0xFF0057CD), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(art.readTime, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                art.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, height: 1.3),
              ),
              const SizedBox(height: 6),
              Text(
                art.summary,
                style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tác giả: ${art.author}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    art.date,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openArticleDetail(BuildContext context, HealthArticle art) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(art.category),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                art.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.person_pin, size: 16, color: Color(0xFF0057CD)),
                  const SizedBox(width: 6),
                  Text(art.author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const Spacer(),
                  Text('${art.date} • ${art.readTime}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const Divider(height: 24),
              Text(
                art.content,
                style: const TextStyle(fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.health_and_safety_outlined, color: Color(0xFF0057CD)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Thông tin mang tính tham khảo. Hãy tham vấn bác sĩ trực tiếp trước khi áp dụng bất kỳ phác đồ điều trị nào.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF0057CD)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


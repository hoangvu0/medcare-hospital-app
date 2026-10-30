import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../state/medical_store.dart';

class HealthNewsPage extends StatefulWidget {
  const HealthNewsPage({super.key});

  @override
  State<HealthNewsPage> createState() => _HealthNewsPageState();
}

class _HealthNewsPageState extends State<HealthNewsPage> {
  bool _requestedInitialRefresh = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedInitialRefresh) return;
    _requestedInitialRefresh = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        MedicalScope.of(context).refreshHealthNews();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final articles = store.healthArticles;
    final updatedAt = store.healthNewsUpdatedAt;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cẩm nang Y khoa & Sức khỏe'),
        actions: [
          IconButton(
            tooltip: 'Cập nhật tin mới',
            onPressed: store.healthNewsLoading
                ? null
                : () => store.refreshHealthNews(),
            icon: store.healthNewsLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
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
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFF0057CD),
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kiến thức Y khoa Chính thống',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
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
          _buildNewsStatusCard(context, store, updatedAt),
          const SizedBox(height: 16),
          ...articles.map((art) => _buildArticleCard(context, art)),
        ],
      ),
    );
  }

  Widget _buildNewsStatusCard(
    BuildContext context,
    MedicalStore store,
    DateTime? updatedAt,
  ) {
    final isLive = updatedAt != null && store.healthNewsError == null;
    final color = isLive ? const Color(0xFF059669) : const Color(0xFF0057CD);
    final subtitle = isLive
        ? 'Tin được cập nhật tự động từ API bệnh viện/RSS lúc ${_formatTime(updatedAt)}.'
        : store.healthNewsError ??
              'Đang dùng dữ liệu cẩm nang nội bộ, bấm làm mới để lấy tin mới.';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(
            isLive ? Icons.cloud_done_rounded : Icons.info_outline_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLive ? 'Tin tức đang đồng bộ API' : 'Tin tức dự phòng',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, HealthArticle art) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = art.imageUrl ?? _fallbackImageFor(art.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFE2E7FF),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.health_and_safety_rounded,
                        size: 48,
                        color: Color(0xFF0057CD),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0057CD).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      art.category,
                      style: const TextStyle(
                        color: Color(0xFF0057CD),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    art.readTime,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                art.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                art.summary,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Nguồn: ${art.sourceName ?? art.author}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
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

  String _fallbackImageFor(String category) {
    final value = category.toLowerCase();
    if (value.contains('tim')) {
      return 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=900&auto=format&fit=crop&q=80';
    }
    if (value.contains('tiêu') || value.contains('dạ dày')) {
      return 'https://images.unsplash.com/photo-1530026405186-ed1f139313f8?w=900&auto=format&fit=crop&q=80';
    }
    return 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=900&auto=format&fit=crop&q=80';
  }

  void _openArticleDetail(BuildContext context, HealthArticle art) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(art.category)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  art.imageUrl ?? _fallbackImageFor(art.category),
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 190,
                    color: const Color(0xFFE2E7FF),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.health_and_safety_rounded,
                      size: 56,
                      color: Color(0xFF0057CD),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                art.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(
                    Icons.person_pin,
                    size: 16,
                    color: Color(0xFF0057CD),
                  ),
                  Text(
                    art.author,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${art.date} • ${art.readTime}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(
                art.content,
                style: const TextStyle(fontSize: 14, height: 1.6),
              ),
              if (art.sourceUrl != null && art.sourceUrl!.isNotEmpty) ...[
                const SizedBox(height: 16),
                SelectableText(
                  'Nguồn bài viết: ${art.sourceUrl}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF0057CD),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.health_and_safety_outlined,
                      color: Color(0xFF0057CD),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Thông tin mang tính tham khảo. Hãy tham vấn bác sĩ trực tiếp trước khi áp dụng bất kỳ phác đồ điều trị nào.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF0057CD),
                        ),
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

  String _formatTime(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

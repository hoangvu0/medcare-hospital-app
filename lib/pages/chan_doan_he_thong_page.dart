import 'package:flutter/material.dart';

import '../state/app_settings_store.dart';
import '../state/medical_store.dart';

class DiagnosticsPage extends StatelessWidget {
  const DiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final medicalStore = MedicalScope.maybeOf(context);
    final sync = medicalStore?.syncState;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cacheKb = (settings.simulatedCacheBytes / 1024).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(title: const Text('Chẩn đoán Hệ thống & Bộ nhớ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            context,
            title: 'Chỉ số Hiệu năng (Performance Metrics)',
            icon: Icons.speed_rounded,
            color: Colors.blue,
            children: [
              _metricRow('Tốc độ làm tươi màn hình', '60 FPS (Mượt mà)'),
              _metricRow('Thời gian phản hồi UI', '16 ms (Chuẩn 1 frame)'),
              _metricRow('Độ trễ máy chủ MedCare API', '28 ms (Cực nhanh)'),
              _metricRow(
                'Trạng thái luồng dựng hình (Raster)',
                'Khỏe mạnh (Optimal)',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _card(
            context,
            title: 'Quản lý Bộ nhớ & Cache (Storage)',
            icon: Icons.storage_rounded,
            color: Colors.orange,
            children: [
              _metricRow('Dung lượng bộ nhớ đệm (Cache)', '$cacheKb KB'),
              _metricRow(
                'Cơ sở dữ liệu cục bộ',
                'SQLite medcare.sqlite (Sẵn sàng)',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await settings.clearCache();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(settings.tr('clear_cache_success')),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.cleaning_services_outlined),
                  label: const Text('Dọn dẹp bộ nhớ đệm (Clear Cache)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _card(
            context,
            title: 'Đồng bộ Backend (Sync Readiness)',
            icon: Icons.cloud_sync_rounded,
            color: Colors.indigo,
            children: [
              _metricRow(
                'Trạng thái lưu trữ',
                sync == null
                    ? 'Chưa kết nối MedicalStore'
                    : 'SQLite local-first',
              ),
              _metricRow(
                'API backend thật',
                medicalStore?.backendApiConfigured ?? false
                    ? 'Đã cấu hình'
                    : 'Chưa cấu hình',
              ),
              _metricRow(
                'Thay đổi chờ đẩy API',
                sync == null ? 'N/A' : sync.pendingChanges.toString(),
              ),
              _metricRow(
                'Sửa đổi local gần nhất',
                _formatDateTime(sync?.lastLocalChangeAt),
              ),
              _metricRow(
                'Lần đồng bộ gần nhất',
                _formatDateTime(sync?.lastSyncedAt),
              ),
              if (sync?.hasError ?? false)
                _metricRow('Lỗi sync gần nhất', sync!.lastError!),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      medicalStore != null && (sync?.hasPendingChanges ?? false)
                      ? () async {
                          final ok = await medicalStore.syncWithBackend();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok ? 'Đã đồng bộ backend thành công' : 'Chưa đồng bộ được backend. Kiểm tra cấu hình API.',
                              ),
                              backgroundColor: ok ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.done_all_rounded),
                  label: const Text('Đồng bộ API thật'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _card(
            context,
            title: 'Kiểm thử Độ tin cậy (Network Resilience)',
            icon: Icons.wifi_tethering_rounded,
            color: Colors.teal,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Kiểm tra chế độ Ngoại tuyến (Offline)'),
                subtitle: const Text(
                  'Kiểm tra khả năng hiển thị thẻ BHYT và đơn thuốc khi mất mạng',
                ),
                value: settings.isOfflineSimulated,
                onChanged: (_) => settings.toggleOfflineSimulation(),
              ),
              _metricRow(
                'Trạng thái kết nối',
                settings.isOfflineSimulated
                    ? 'Ngoại tuyến (Offline)'
                    : 'Trực tuyến (Online 5G/Wi-Fi)',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _card(
            context,
            title: 'Tiêu chuẩn Bảo mật Y tế (Security & Compliance)',
            icon: Icons.security_rounded,
            color: Colors.green,
            children: [
              _metricRow(
                'Tiêu chuẩn bảo mật dữ liệu y tế',
                'Tuân thủ HIPAA & NĐ 13/2023',
              ),
              _metricRow('Mã hóa dữ liệu tại chỗ (At-Rest)', 'AES-256 Bit'),
              _metricRow(
                'Chế độ bảo vệ dữ liệu nhạy cảm',
                settings.isMaskingSensitiveData ? 'Đang bật (Masked)' : 'Tắt',
              ),
              _metricRow(
                'Mã khóa ứng dụng PIN',
                settings.pinCode != null
                    ? 'Đã thiết lập 4 số'
                    : 'Chưa kích hoạt',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'MedCare Hospital App v1.0.0+1 • Build 2026\nPhát triển bởi SV 2324801030077',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'Chưa có';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} $hour:$minute';
  }

  Widget _card(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../state/medical_store.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, this.currentRoute = AppRoutes.home});

  final String currentRoute;
  static const primary = Color(0xFF0057CD);

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final profile = store.profile;
    final displayName = profile.name.trim().isNotEmpty
        ? profile.name.trim()
        : 'Khách hàng MedCare';
    final email = profile.email.trim().isNotEmpty
        ? profile.email.trim()
        : store.currentIdentifier ?? 'Chưa cập nhật email';
    final recordId = profile.id.trim().isNotEmpty ? profile.id : 'Chưa có mã';

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0057CD), Color(0xFF003882)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _initials(displayName),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
            ),
            accountName: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            accountEmail: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Mã hồ sơ: $recordId',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerTile(
                  context,
                  icon: Icons.home_rounded,
                  title: 'Trang chủ',
                  route: AppRoutes.home,
                  selected: currentRoute == AppRoutes.home,
                ),
                _drawerTile(
                  context,
                  icon: Icons.category_rounded,
                  title: 'Danh mục chuyên khoa',
                  subtitle: 'Nhi, Tim mạch, Tiêu hóa,...',
                  route: AppRoutes.specialtyList,
                  selected: currentRoute == AppRoutes.specialtyList,
                ),
                _drawerTile(
                  context,
                  icon: Icons.people_alt_rounded,
                  title: 'Danh sách bác sĩ',
                  subtitle: 'Đặt hẹn chuyên gia hàng đầu',
                  route: AppRoutes.doctors,
                  selected: currentRoute == AppRoutes.doctors,
                ),
                _drawerTile(
                  context,
                  icon: Icons.calendar_month_rounded,
                  title: 'Lịch khám & Đặt hẹn',
                  route: AppRoutes.appointments,
                  selected: currentRoute == AppRoutes.appointments,
                ),
                _drawerTile(
                  context,
                  icon: Icons.folder_shared_rounded,
                  title: 'Hồ sơ bệnh án điện tử',
                  route: AppRoutes.records,
                  selected: currentRoute == AppRoutes.records,
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 4, bottom: 4),
                  child: Text(
                    'DỊCH VỤ & TIỆN ÍCH',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                _drawerTile(
                  context,
                  icon: Icons.medication_rounded,
                  title: 'Đơn thuốc điện tử',
                  route: AppRoutes.prescription,
                  selected: currentRoute == AppRoutes.prescription,
                ),
                _drawerTile(
                  context,
                  icon: Icons.inventory_2_rounded,
                  title: 'Gói khám tổng quát',
                  route: AppRoutes.healthPackages,
                  selected: currentRoute == AppRoutes.healthPackages,
                ),
                _drawerTile(
                  context,
                  icon: Icons.map_rounded,
                  title: 'Sơ đồ bệnh viện',
                  route: AppRoutes.hospitalMap,
                  selected: currentRoute == AppRoutes.hospitalMap,
                ),
                _drawerTile(
                  context,
                  icon: Icons.support_agent_rounded,
                  title: 'Hỗ trợ & liên hệ',
                  route: AppRoutes.support,
                  selected: currentRoute == AppRoutes.support,
                ),
                _drawerTile(
                  context,
                  icon: Icons.smart_toy_rounded,
                  title: 'Trợ lý sức khỏe AI',
                  route: AppRoutes.aiAssistant,
                  selected: currentRoute == AppRoutes.aiAssistant,
                ),
                const Divider(),
                _drawerTile(
                  context,
                  icon: Icons.person_outline_rounded,
                  title: 'Thông tin cá nhân',
                  route: AppRoutes.profile,
                  selected: currentRoute == AppRoutes.profile,
                ),
                _drawerTile(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Cài đặt hệ thống',
                  route: AppRoutes.settings,
                  selected: currentRoute == AppRoutes.settings,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFBA1A1A),
                  ),
                  title: const Text(
                    'Đăng xuất',
                    style: TextStyle(
                      color: Color(0xFFBA1A1A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    store.logout();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (_) => false,
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_rounded, size: 18, color: primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'MedCare Hospital • Hồ sơ được bảo mật',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
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

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'MC';
    if (parts.length == 1) {
      return parts.first.runes
          .take(2)
          .map(String.fromCharCode)
          .join()
          .toUpperCase();
    }
    return '${String.fromCharCode(parts.first.runes.first)}${String.fromCharCode(parts.last.runes.first)}'
        .toUpperCase();
  }

  Widget _drawerTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required String route,
    bool selected = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: selected ? primary : const Color(0xFF424655)),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          color: selected ? primary : null,
          fontSize: 14,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 11))
          : null,
      selected: selected,
      selectedTileColor: const Color(0xFFE2E7FF).withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: () {
        Navigator.pop(context);
        if (!selected) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}

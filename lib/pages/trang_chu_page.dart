import 'dart:async';

import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../routes/app_routes.dart';
import '../state/medical_store.dart';
import '../state/app_settings_store.dart';
import '../widgets/app_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int selectedIndex = 0;
  static const primary = Color(0xFF0057CD);
  static const dark = Color(0xFF131B2E);
  static const grey = Color(0xFF424655);
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MedicalScope.of(context).refreshNotificationsFromBackend();
      _notificationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        unawaited(MedicalScope.of(context).refreshNotificationsFromBackend());
      });
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final store = MedicalScope.of(context);

    if (store.isSeniorMode) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAF8FF),
        appBar: AppBar(
          title: const Text(
            'MedCare — Chế độ Người cao tuổi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          backgroundColor: const Color(0xFF0057CD),
          foregroundColor: Colors.white,
          actions: [
            FilledButton.tonal(
              onPressed: () => store.toggleSeniorMode(),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white24,
                foregroundColor: Colors.white,
              ),
              child: const Text('Thoát'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _buildSeniorModeScreen(store),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(currentRoute: AppRoutes.home),
      bottomNavigationBar: _buildBottomNavigationBar(settings),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: .08,
                  child: Image.network(
                    'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?w=1400&auto=format&fit=crop&q=80',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            ListView(
              padding: const EdgeInsets.only(top: 80, bottom: 20),
              children: [
                if (settings.isOfflineSimulated) _offlineBanner(settings),
                _greeting(),
                _clinicalPathwayBanner(store),
                _aiAssistantBanner(),
                _followUpReminderBanner(store),
                _hospitalWalletBanner(store),
                _emergency(),
                _appointment(),
                _quickActions(),
                _specialties(),
                _topDoctors(),
                _healthTips(),
              ],
            ),
            _header(),
          ],
        ),
      ),
    );
  }

  Widget _offlineBanner(AppSettingsStore settings) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF3C7),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFF59E0B)),
    ),
    child: Row(
      children: [
        const Icon(Icons.wifi_off_rounded, color: Color(0xFFB45309)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            settings.tr('offline_banner'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF92400E),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _header() {
    final store = MedicalScope.of(context);
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: .94),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8)],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: primary, size: 28),
            tooltip: 'Mở Menu (Drawer)',
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const SizedBox(width: 2),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFE2E7FF),
            child: Icon(Icons.local_hospital_rounded, color: primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MedCare',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hồ sơ ${store.profile.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF006C49),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              unawaited(store.refreshNotificationsFromBackend());
              Navigator.pushNamed(context, AppRoutes.notifications);
            },
            icon: Badge(
              isLabelVisible: store.unreadNotificationCount > 0,
              label: Text(
                store.unreadNotificationCount > 99
                    ? '99+'
                    : '${store.unreadNotificationCount}',
              ),
              backgroundColor: const Color(0xFFBA1A1A),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: dark,
                size: 22,
              ),
            ),
            tooltip: 'Thông báo',
          ),
          IconButton(
            onPressed: () {
              final store = MedicalScope.of(context);
              store.toggleSeniorMode();
            },
            tooltip: 'Chế độ Người cao tuổi (Senior Mode)',
            icon: const Icon(Icons.elderly_outlined, color: primary, size: 22),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            tooltip: 'Cài đặt hệ thống',
            icon: const Icon(Icons.settings_outlined, color: dark, size: 22),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
            icon: const Icon(Icons.person_outline, color: primary, size: 22),
            tooltip: 'Hồ sơ cá nhân',
          ),
        ],
      ),
    );
  }

  Widget _greeting() {
    final settings = AppSettingsScope.of(context);
    final store = MedicalScope.of(context);
    final profile = store.profile;
    final bhytText = settings.isMaskingSensitiveData
        ? 'BHYT: ${settings.maskText(profile.insuranceNumber, visiblePrefix: 4, visibleSuffix: 3)}'
        : 'BHYT: Đã liên kết';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/medcare_hospital_bg.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            Positioned.fill(
              child: ColoredBox(color: Colors.white.withValues(alpha: .84)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Xin chào 👋',
                              style: TextStyle(color: grey, fontSize: 13),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              profile.name,
                              style: const TextStyle(
                                color: dark,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E7FF),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified,
                              size: 14,
                              color: Color(0xFF006C49),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              bhytText,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Family profile switcher banner
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.familyProfiles),
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            MedicalScope.of(context)
                                .activeFamilyMember
                                .avatarEmoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Đang khám cho: ${MedicalScope.of(context).activeFamilyMember.name} (${MedicalScope.of(context).activeFamilyMember.relationLabel})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            ),
                          ),
                          const Text(
                            'Đổi',
                            style: TextStyle(
                              fontSize: 11,
                              color: primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(
                            Icons.swap_horiz_rounded,
                            size: 16,
                            color: primary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.search),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Color(0x0D000000), blurRadius: 3),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.search,
                            size: 19,
                            color: Color(0xFF727787),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Tìm bác sĩ, chuyên khoa, gói khám...',
                            style: TextStyle(
                              color: Color(0xFF727787),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _clinicalPathwayBanner(MedicalStore store) {
    final step = store.currentPathwayStep;
    final progress = store.pathwayProgressPercentage;
    final completedCount = store.completedStepsCount;
    final totalSteps = store.clinicalPathway.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.clinicalPathway),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F2B5C), Color(0xFF0057CD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x250057CD),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.alt_route_rounded,
                          color: Colors.amberAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'TIẾN ĐỘ KHÁM HÔM NAY (BƯỚC ${step.stepNumber}/$totalSteps)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Xong $completedCount/$totalSteps bước',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Cần làm: ${step.title}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '📍 ${step.location} • Dặn dò: ${step.doctorInstruction}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aiAssistantBanner() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.aiAssistant),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0057CD), Color(0xFF1E3A8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x330057CD),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'TRỢ LÝ Y TẾ AI',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tư vấn & Sàng lọc triệu chứng 24/7',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Mô tả biểu hiện để được gợi ý bác sĩ ngay ➔',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _followUpReminderBanner(MedicalStore store) {
    if (store.followUpReminders.isEmpty) return const SizedBox.shrink();
    final rem = store.followUpReminders.first;
    final daysRemaining = rem.reminderDate
        .difference(DateTime.now())
        .inDays
        .clamp(0, 99);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.event_repeat,
                  color: Color(0xFF0057CD),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'LỊCH HẸN TÁI KHÁM TỰ ĐỘNG (CÒN $daysRemaining NGÀY)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0057CD),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0057CD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Bác sĩ hẹn',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Bác sĩ: ${rem.doctorName} (${rem.specialty})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              rem.clinicalReason,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              'Dặn dò: ${rem.doctorInstructions}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hospitalWalletBanner(MedicalStore store) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFDCFCE7),
              child: Icon(
                Icons.account_balance_wallet,
                color: Color(0xFF15803D),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'VÍ VIỆN PHÍ MEDCARE PAY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Số dư: ${store.walletBalance ~/ 1000}.000đ',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Tạm ứng: ${store.advanceDeposit ~/ 1000}.000đ',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF15803D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: store.advanceDeposit > 0
                  ? () {
                      store.autoRefundAdvance();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Đã hoàn trả 100% số tiền tạm ứng thừa về tài khoản ngân hàng!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  : () => Navigator.pushNamed(context, AppRoutes.walletTopUp),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDCFCE7),
                foregroundColor: const Color(0xFF15803D),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
              ),
              child: Text(
                store.advanceDeposit > 0 ? 'Hoàn tiền' : 'Nạp ví',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emergency() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.emergencySos),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFDAD6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFBA1A1A),
              child: Icon(Icons.phone, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CẤP CỨU 24/7 & MEDICAL ID',
                    style: TextStyle(
                      color: Color(0xFFBA1A1A),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '1900 8899',
                    style: TextStyle(
                      color: Color(0xFF93000A),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.emergencySos),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFBA1A1A),
              ),
              child: const Text('Cấp cứu'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _appointment() {
    final store = MedicalScope.of(context);
    final confirmedAppointments = store.appointments
        .where((a) => a.status == AppointmentStatus.confirmed)
        .toList();
    final nextAppointment = confirmedAppointments.firstOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        children: [
          _sectionTitle(
            'Lịch hẹn sắp tới',
            'Tất cả (${confirmedAppointments.length})',
            route: AppRoutes.myAppointments,
          ),
          const SizedBox(height: 9),
          if (nextAppointment != null)
            InkWell(
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.appointmentDetail,
                arguments: nextAppointment,
              ),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1E7DD),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            nextAppointment.ticketNumber ?? 'Đã xác nhận khám',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F5132),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '#${nextAppointment.id}',
                          style: const TextStyle(color: grey, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Color(0xFFE2E7FF),
                          child: Icon(Icons.person, color: primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CHUYÊN KHOA ${nextAppointment.specialty.toUpperCase()}',
                                style: const TextStyle(
                                  color: primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                nextAppointment.doctorName,
                                style: const TextStyle(
                                  color: dark,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                nextAppointment.location,
                                style: const TextStyle(
                                  color: grey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F3FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 15,
                            color: primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ngày ${nextAppointment.dateTime.day.toString().padLeft(2, '0')}/${nextAppointment.dateTime.month.toString().padLeft(2, '0')}/${nextAppointment.dateTime.year}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${nextAppointment.dateTime.hour.toString().padLeft(2, '0')}:${nextAppointment.dateTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  const Text(
                    'Bạn chưa có lịch hẹn nào sắp tới.',
                    style: TextStyle(color: grey),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.appointments),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Đặt lịch khám ngay'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _quickActions() {
    const actions = [
      (
        Icons.family_restroom_rounded,
        'Hồ sơ\ngia đình',
        AppRoutes.familyProfiles,
        Color(0xFFEFF6FF),
        Color(0xFF0057CD),
      ),
      (
        Icons.video_call_rounded,
        'Khám\ntừ xa AI',
        AppRoutes.telemedicine,
        Color(0xFFDCFCE7),
        Color(0xFF15803D),
      ),
      (
        Icons.calendar_month_rounded,
        'Đặt khám\nnhanh',
        AppRoutes.appointments,
        Color(0xFFE2E7FF),
        Color(0xFF0057CD),
      ),
      (
        Icons.medication_rounded,
        'Nhắc uống\nthuốc',
        AppRoutes.medicationTracker,
        Color(0xFFDCFCE7),
        Color(0xFF15803D),
      ),

      (
        Icons.monitor_heart_rounded,
        'Chỉ số\nsinh hiệu',
        AppRoutes.vitalsTracker,
        Color(0xFFFFE4E6),
        Color(0xFFBE123C),
      ),
      (
        Icons.people_alt_rounded,
        'Hàng đợi\nkhám',
        AppRoutes.liveQueue,
        Color(0xFFFEF3C7),
        Color(0xFFB45309),
      ),
      (
        Icons.vaccines_rounded,
        'Sổ tiêm\nchủng',
        AppRoutes.vaccination,
        Color(0xFFCCFBF1),
        Color(0xFF0F766E),
      ),
      (
        Icons.inventory_2_rounded,
        'Gói khám\ntầm soát',
        AppRoutes.healthPackages,
        Color(0xFFEDE9FE),
        Color(0xFF6D28D9),
      ),

      (
        Icons.map_rounded,
        'Sơ đồ\nbệnh viện',
        AppRoutes.hospitalMap,
        Color(0xFFFEF9C3),
        Color(0xFFB45309),
      ),
      (
        Icons.credit_card_rounded,
        'Thẻ y tế\nBHYT 3D',
        AppRoutes.digitalCard,
        Color(0xFFE0E7FF),
        Color(0xFF1D4ED8),
      ),
      (
        Icons.description_rounded,
        'Bệnh án\nđiện tử',
        AppRoutes.records,
        Color(0xFFE2E7FF),
        Color(0xFF0057CD),
      ),
      (
        Icons.account_balance_wallet_rounded,
        'Thanh toán\nviện phí',
        AppRoutes.payment,
        Color(0xFFDCFCE7),
        Color(0xFF15803D),
      ),

      (
        Icons.spa_rounded,
        'Thư giãn\ntinh thần',
        AppRoutes.mentalHealth,
        Color(0xFFF3E8FF),
        Color(0xFF7E22CE),
      ),
      (
        Icons.menu_book_rounded,
        'Cẩm nang\ny khoa',
        AppRoutes.healthNews,
        Color(0xFFFFEDD5),
        Color(0xFFC2410C),
      ),
      (
        Icons.biotech_rounded,
        'AI Diễn giải\nxét nghiệm',
        AppRoutes.labExplainer,
        Color(0xFFE0F2FE),
        Color(0xFF0369A1),
      ),
      (
        Icons.shield_rounded,
        'Bảo hiểm\nbảo lãnh',
        AppRoutes.insuranceGuarantee,
        Color(0xFFECFDF5),
        Color(0xFF047857),
      ),
      (
        Icons.alt_route_rounded,
        'Lộ trình\nkhám',
        AppRoutes.clinicalPathway,
        Color(0xFFEFF6FF),
        Color(0xFF0057CD),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'DỊCH VỤ Y TẾ THÔNG MINH',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0057CD),
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0057CD).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '12 TIỆN ÍCH',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0057CD),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 14,
              crossAxisSpacing: 8,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              final item = actions[index];
              return InkWell(
                onTap: () => Navigator.pushNamed(context, item.$3),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: item.$4,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(item.$1, color: item.$5, size: 26),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.$2,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _specialties() {
    final store = MedicalScope.of(context);
    final seen = <String>{};
    final specialties = [
      for (final doctor in store.doctors)
        if (seen.add(doctor.specialty)) doctor.specialty,
    ].take(6).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        children: [
          _sectionTitle(
            'Chuyên khoa tiêu biểu',
            'Xem tất cả',
            route: AppRoutes.specialtyList,
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: .95,
            children: specialties.map((specialty) {
              final doctorCount = store.doctors
                  .where((doctor) => doctor.specialty == specialty)
                  .length;
              return InkWell(
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.specialty,
                  arguments: specialty,
                ),
                child: Container(
                  decoration: _cardDecoration(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_specialtyIcon(specialty), color: primary, size: 24),
                      const SizedBox(height: 7),
                      Text(
                        specialty,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$doctorCount bác sĩ',
                        style: const TextStyle(color: grey, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _specialtyIcon(String specialty) {
    final lower = specialty.toLowerCase();
    if (lower.contains('tim')) return Icons.favorite;
    if (lower.contains('nhi')) return Icons.child_care;
    if (lower.contains('tai') || lower.contains('mũi')) {
      return Icons.health_and_safety;
    }
    if (lower.contains('da')) return Icons.face;
    if (lower.contains('mắt')) return Icons.visibility;
    if (lower.contains('xương')) return Icons.accessibility_new;
    return Icons.local_hospital;
  }

  Widget _topDoctors() {
    final store = MedicalScope.of(context);
    final topDoctors = store.doctors.take(2).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        children: [
          _sectionTitle(
            'Bác sĩ tiêu biểu tuần này',
            'Xem tất cả (${store.doctors.length})',
            route: AppRoutes.doctors,
          ),
          const SizedBox(height: 12),
          ...topDoctors.map(
            (doctor) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _doctorCard(doctor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _doctorCard(DoctorProfile doctor) => InkWell(
    onTap: () =>
        Navigator.pushNamed(context, AppRoutes.doctorDetail, arguments: doctor),
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFFE2E7FF),
                child: Icon(Icons.person, color: primary, size: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Chip(label: Text(doctor.specialty)),
                    Text(
                      doctor.name,
                      style: const TextStyle(
                        color: dark,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      doctor.experience,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Phí khám tư vấn',
                    style: TextStyle(color: grey, fontSize: 10),
                  ),
                  Text(
                    '${doctor.price ~/ 1000}.000đ',
                    style: const TextStyle(
                      color: primary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.appointments,
                  arguments: doctor,
                ),
                icon: const Icon(Icons.calendar_month, size: 15),
                label: const Text('Đặt lịch ngay'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _healthTips() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
    child: Column(
      children: [
        _sectionTitle(
          'Cẩm nang sức khỏe',
          'Xem tất cả',
          route: AppRoutes.healthNews,
        ),
        const SizedBox(height: 12),
        ...[
          (
            'Tiêu hóa',
            '4 phút đọc',
            'Chế độ ăn cho người viêm loét dạ dày vi khuẩn Hp',
            Icons.restaurant,
          ),
          (
            'Tim mạch',
            '5 phút đọc',
            'Phân biệt đau thắt ngực do tim và trào ngược dạ dày',
            Icons.favorite,
          ),
        ].map(
          (article) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              onTap: () => Navigator.pushNamed(context, AppRoutes.healthNews),
              leading: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E7FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(article.$4, color: primary),
              ),
              title: Text(
                article.$3,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              subtitle: Text('${article.$1} • ${article.$2}'),
              trailing: const Icon(Icons.chevron_right, size: 18),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _sectionTitle(String title, String action, {String? route}) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: dark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      InkWell(
        onTap: route == null ? null : () => Navigator.pushNamed(context, route),
        child: Row(
          children: [
            Text(
              action,
              style: const TextStyle(
                color: primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.chevron_right, color: primary, size: 16),
          ],
        ),
      ),
    ],
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 2)),
    ],
  );

  Widget _buildBottomNavigationBar(AppSettingsStore settings) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (index) {
        setState(() => selectedIndex = index);
        settings.triggerHaptic();
        if (index == 0) {
          setState(() => selectedIndex = 0);
        } else if (index == 1) {
          Navigator.pushNamed(context, AppRoutes.doctors).then((_) {
            if (mounted) setState(() => selectedIndex = 0);
          });
        } else if (index == 2) {
          Navigator.pushNamed(context, AppRoutes.appointments).then((_) {
            if (mounted) setState(() => selectedIndex = 0);
          });
        } else if (index == 3) {
          Navigator.pushNamed(context, AppRoutes.records).then((_) {
            if (mounted) setState(() => selectedIndex = 0);
          });
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: primary,
      unselectedItemColor: grey,
      showUnselectedLabels: true,
      selectedFontSize: 12,
      unselectedFontSize: 11,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home_rounded),
          label: settings.tr('home'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.medical_services_outlined),
          activeIcon: const Icon(Icons.medical_services_rounded),
          label: settings.tr('doctors'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.calendar_month_outlined),
          activeIcon: const Icon(Icons.calendar_month_rounded),
          label: settings.tr('appointments'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.description_outlined),
          activeIcon: const Icon(Icons.description_rounded),
          label: settings.tr('records'),
        ),
      ],
    );
  }

  Widget _buildSeniorModeScreen(MedicalStore store) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0057CD),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kính chào Bác,',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              Text(
                store.profile.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Chế độ màn hình tối giản, chữ to rõ ràng dành riêng cho Người cao tuổi.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _seniorBigButton(
          title: 'GỌI CẤP CỨU & BÁC SĨ',
          subtitle: 'Kết nối khẩn cấp 1900 8899 / 115',
          icon: Icons.phone_in_talk,
          color: const Color(0xFFBA1A1A),
          onTap: () => Navigator.pushNamed(context, AppRoutes.emergencySos),
        ),
        const SizedBox(height: 16),

        _seniorBigButton(
          title: 'LỊCH KHÁM & TÁI KHÁM',
          subtitle: 'Xem phòng khám & bác sĩ hẹn',
          icon: Icons.calendar_month,
          color: const Color(0xFF0057CD),
          onTap: () => Navigator.pushNamed(context, AppRoutes.myAppointments),
        ),
        const SizedBox(height: 16),

        _seniorBigButton(
          title: 'GIỜ UỐNG THUỐC HÀNG NGÀY',
          subtitle: 'Xem danh sách thuốc cần uống hôm nay',
          icon: Icons.medication_rounded,
          color: const Color(0xFF006C49),
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.medicationTracker),
        ),
        const SizedBox(height: 16),

        _seniorBigButton(
          title: 'ĐỌC KẾT QUẢ XÉT NGHIỆM',
          subtitle: 'AI giải thích chỉ số máu bằng chữ to',
          icon: Icons.auto_awesome,
          color: const Color(0xFF7E22CE),
          onTap: () => Navigator.pushNamed(context, AppRoutes.labExplainer),
        ),
      ],
    );
  }

  Widget _seniorBigButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../routes/app_routes.dart';
import '../state/medical_store.dart';
import '../state/app_settings_store.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  static const primary = Color(0xFF0057CD);
  static const dark = Color(0xFF131B2E);
  static const grey = Color(0xFF424655);

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final store = MedicalScope.of(context);

    if (store.isSeniorMode) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAF8FF),
        appBar: AppBar(
          title: const Text('MedCare — Chế độ Người cao tuổi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          backgroundColor: const Color(0xFF0057CD),
          foregroundColor: Colors.white,
          actions: [
            FilledButton.tonal(
              onPressed: () => store.toggleSeniorMode(),
              style: FilledButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white),
              child: const Text('Thoát'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _buildSeniorModeScreen(store),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.only(top: 80, bottom: 84),
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
            _bottomNavigation(),

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

  Widget _header() => Container(
    height: 80,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor.withValues(alpha: .94),
      boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8)],
    ),
    child: Row(
      children: [
        const CircleAvatar(
          backgroundColor: Color(0xFFE2E7FF),
          child: Icon(Icons.local_hospital_rounded, color: primary),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MedCare Hospital',
                style: TextStyle(
                  color: primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Cơ sở 1 - Q. Hoàn Kiếm, Hà Nội',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: grey, fontSize: 11),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.notifications),
          icon: const Icon(Icons.notifications_none_rounded, color: dark),
        ),
        IconButton(
          onPressed: () {
            final store = MedicalScope.of(context);
            store.toggleSeniorMode();
          },
          tooltip: 'Chế độ Người cao tuổi (Senior Mode)',
          icon: const Icon(Icons.elderly_outlined, color: primary),
        ),
        IconButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          tooltip: 'Cài đặt hệ thống',
          icon: const Icon(Icons.settings_outlined, color: dark),
        ),
        IconButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          icon: const Icon(Icons.person_outline, color: primary),
        ),
      ],
    ),
  );

  Widget _greeting() {
    final settings = AppSettingsScope.of(context);
    final store = MedicalScope.of(context);
    final profile = store.profile;
    final bhytText = settings.isMaskingSensitiveData
        ? 'BHYT: ${settings.maskText(profile.insuranceNumber, visiblePrefix: 4, visibleSuffix: 3)}'
        : 'BHYT: Đã liên kết';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E7FF),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, size: 14, color: Color(0xFF006C49)),
                    const SizedBox(width: 5),
                    Text(
                      bhytText,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Family profile switcher banner
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.familyProfiles),
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Text(MedicalScope.of(context).activeFamilyMember.avatarEmoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    'Đang khám cho: ${MedicalScope.of(context).activeFamilyMember.name} (${MedicalScope.of(context).activeFamilyMember.relationLabel})',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primary),
                  ),
                  const Spacer(),
                  const Text('Đổi', style: TextStyle(fontSize: 11, color: primary, fontWeight: FontWeight.w600)),
                  const Icon(Icons.swap_horiz_rounded, size: 16, color: primary),
                ],
              ),
            ),
          ),

          // Thanh chuyển đổi tương tác Bác sĩ <-> Bệnh nhân
          Container(
            margin: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      store.switchRole(UserRole.doctor);
                      Navigator.pushNamed(context, AppRoutes.doctorPortal);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2B5C).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF0F2B5C).withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medical_services_outlined, size: 15, color: Color(0xFF0F2B5C)),
                          SizedBox(width: 6),
                          Text(
                            '🩺 Vào Bàn làm việc Bác sĩ (Gọi số, Kê đơn, Tái khám)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F2B5C)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
                  Icon(Icons.search, size: 19, color: Color(0xFF727787)),
                  SizedBox(width: 8),
                  Text(
                    'Tìm bác sĩ, chuyên khoa, gói khám...',
                    style: TextStyle(color: Color(0xFF727787), fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
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
              BoxShadow(color: Color(0x250057CD), blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.alt_route_rounded, color: Colors.amberAccent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'TIẾN ĐỘ KHÁM HÔM NAY (BƯỚC ${step.stepNumber}/$totalSteps)',
                        style: const TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      'Xong $completedCount/$totalSteps bước',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Cần làm: ${step.title}',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
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
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 28),
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
    final daysRemaining = rem.reminderDate.difference(DateTime.now()).inDays.clamp(0, 99);

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
                const Icon(Icons.event_repeat, color: Color(0xFF0057CD), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'LỊCH HẸN TÁI KHÁM TỰ ĐỘNG (CÒN $daysRemaining NGÀY)',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0057CD)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF0057CD), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Bác sĩ hẹn', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFDCFCE7),
              child: Icon(Icons.account_balance_wallet, color: Color(0xFF15803D)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('VÍ VIỆN PHÍ MEDCARE PAY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text(
                    'Số dư: ${store.walletBalance ~/ 1000}.000đ',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    'Tạm ứng: ${store.advanceDeposit ~/ 1000}.000đ',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (store.advanceDeposit > 0)
              FilledButton.tonal(
                onPressed: () {
                  store.autoRefundAdvance();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã hoàn trả 100% số tiền tạm ứng thừa về tài khoản ngân hàng!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDCFCE7),
                  foregroundColor: const Color(0xFF15803D),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                child: const Text('Hoàn tiền', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
              onPressed: () => Navigator.pushNamed(context, AppRoutes.emergencySos),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                style: const TextStyle(color: grey, fontSize: 11),
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
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.appointments),
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
      (Icons.family_restroom_rounded, 'Hồ sơ\ngia đình', AppRoutes.familyProfiles, Color(0xFFEFF6FF), Color(0xFF0057CD)),
      (Icons.video_call_rounded, 'Khám\ntừ xa AI', AppRoutes.telemedicine, Color(0xFFDCFCE7), Color(0xFF15803D)),
      (Icons.calendar_month_rounded, 'Đặt khám\nnhanh', AppRoutes.appointments, Color(0xFFE2E7FF), Color(0xFF0057CD)),
      (Icons.medication_rounded, 'Nhắc uống\nthuốc', AppRoutes.medicationTracker, Color(0xFFDCFCE7), Color(0xFF15803D)),

      (Icons.monitor_heart_rounded, 'Chỉ số\nsinh hiệu', AppRoutes.vitalsTracker, Color(0xFFFFE4E6), Color(0xFFBE123C)),
      (Icons.people_alt_rounded, 'Hàng đợi\nkhám', AppRoutes.liveQueue, Color(0xFFFEF3C7), Color(0xFFB45309)),
      (Icons.vaccines_rounded, 'Sổ tiêm\nchủng', AppRoutes.vaccination, Color(0xFFCCFBF1), Color(0xFF0F766E)),
      (Icons.inventory_2_rounded, 'Gói khám\ntầm soát', AppRoutes.healthPackages, Color(0xFFEDE9FE), Color(0xFF6D28D9)),

      (Icons.map_rounded, 'Sơ đồ\nbệnh viện', AppRoutes.hospitalMap, Color(0xFFFEF9C3), Color(0xFFB45309)),
      (Icons.credit_card_rounded, 'Thẻ y tế\nBHYT 3D', AppRoutes.digitalCard, Color(0xFFE0E7FF), Color(0xFF1D4ED8)),
      (Icons.description_rounded, 'Bệnh án\nđiện tử', AppRoutes.records, Color(0xFFE2E7FF), Color(0xFF0057CD)),
      (Icons.account_balance_wallet_rounded, 'Thanh toán\nviện phí', AppRoutes.payment, Color(0xFFDCFCE7), Color(0xFF15803D)),

      (Icons.spa_rounded, 'Thư giãn\ntinh thần', AppRoutes.mentalHealth, Color(0xFFF3E8FF), Color(0xFF7E22CE)),
      (Icons.menu_book_rounded, 'Cẩm nang\ny khoa', AppRoutes.healthNews, Color(0xFFFFEDD5), Color(0xFFC2410C)),
      (Icons.biotech_rounded, 'AI Diễn giải\nxét nghiệm', AppRoutes.labExplainer, Color(0xFFE0F2FE), Color(0xFF0369A1)),
      (Icons.shield_rounded, 'Bảo hiểm\nbảo lãnh', AppRoutes.insuranceGuarantee, Color(0xFFECFDF5), Color(0xFF047857)),
      (Icons.badge_rounded, 'Bàn làm việc\nBác sĩ', AppRoutes.doctorPortal, Color(0xFFE0E7FF), Color(0xFF0F2B5C)),
      (Icons.alt_route_rounded, 'Lộ trình\nkhám', AppRoutes.clinicalPathway, Color(0xFFEFF6FF), Color(0xFF0057CD)),
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
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0057CD)),
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
    const specialties = [
      ('Tim Mạch', '18 bác sĩ', Icons.favorite),
      ('Nhi Khoa', '24 bác sĩ', Icons.child_care),
      ('Tai Mũi Họng', '15 bác sĩ', Icons.health_and_safety),
      ('Da Liễu', '12 bác sĩ', Icons.face),
      ('Khoa Mắt', '14 bác sĩ', Icons.visibility),
      ('Nội Tiết', '9 bác sĩ', Icons.accessibility_new),
    ];
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
            children: specialties
                .map(
                  (item) => InkWell(
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.specialty,
                      arguments: item.$1,
                    ),
                    child: Container(
                      decoration: _cardDecoration(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.$3, color: primary, size: 24),
                          const SizedBox(height: 7),
                          Text(
                            item.$1,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            item.$2,
                            style: const TextStyle(color: grey, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
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
    onTap: () => Navigator.pushNamed(
      context,
      AppRoutes.doctorDetail,
      arguments: doctor,
    ),
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
        _sectionTitle('Cẩm nang sức khỏe', 'Xem tất cả', route: AppRoutes.healthNews),
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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

  Widget _bottomNavigation() {
    final settings = AppSettingsScope.of(context);
    final cardColor = Theme.of(context).cardColor;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: cardColor,
          boxShadow: const [BoxShadow(color: Color(0x120F172A), blurRadius: 12)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomItem(
              icon: Icons.home_outlined,
              title: settings.tr('home'),
              active: selectedIndex == 0,
              onTap: () => settings.triggerHaptic(),
            ),
            _BottomItem(
              icon: Icons.medical_services_outlined,
              title: settings.tr('doctors'),
              active: selectedIndex == 1,
              onTap: () {
                settings.triggerHaptic();
                Navigator.pushNamed(context, AppRoutes.doctors);
              },
            ),
            _BottomItem(
              icon: Icons.calendar_month_outlined,
              title: settings.tr('appointments'),
              active: selectedIndex == 2,
              onTap: () {
                settings.triggerHaptic();
                Navigator.pushNamed(context, AppRoutes.appointments);
              },
            ),
            _BottomItem(
              icon: Icons.description_outlined,
              title: settings.tr('records'),
              active: selectedIndex == 3,
              onTap: () {
                settings.triggerHaptic();
                Navigator.pushNamed(context, AppRoutes.records);
              },
            ),
          ],
        ),
      ),
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
              const Text('Kính chào Bác,', style: TextStyle(color: Colors.white70, fontSize: 16)),
              Text(store.profile.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Chế độ màn hình tối giản, chữ to rõ ràng dành riêng cho Người cao tuổi.', style: TextStyle(color: Colors.white70, fontSize: 13)),
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
          onTap: () => Navigator.pushNamed(context, AppRoutes.medicationTracker),
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
            BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
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
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
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

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.title,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 19,
            color: active ? const Color(0xFF0057CD) : const Color(0xFF424655),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: active ? const Color(0xFF0057CD) : const Color(0xFF424655),
            ),
          ),
        ],
      ),
    ),
  );
}

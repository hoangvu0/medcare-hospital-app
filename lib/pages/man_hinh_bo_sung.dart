import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../routes/app_routes.dart';
import '../state/medical_store.dart';
import '../models/medical_models.dart';
import '../state/app_settings_store.dart';
import '../widgets/doctor_avatar.dart';

const _primary = Color(0xFF0D6EFD);
const _heading = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
const _authBlue = Color(0xFF0B67D1);
const _authNavy = Color(0xFF083B7A);
const _authInk = Color(0xFF102A43);
const _authMuted = Color(0xFF66788A);

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({
    required this.formTitle,
    required this.formSubtitle,
    required this.form,
    required this.heroTitle,
    required this.heroDescription,
    required this.heroIcon,
    this.heroFeatures = const [],
    this.showBackButton = false,
  });

  final String formTitle;
  final String formSubtitle;
  final Widget form;
  final String heroTitle;
  final String heroDescription;
  final IconData heroIcon;
  final List<String> heroFeatures;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF101827)
        : const Color(0xFFFAF8FF);
    final isRegister = showBackButton;
    final isCompactHeight = MediaQuery.sizeOf(context).height < 700;

    return Scaffold(
      backgroundColor: background,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isCompactHeight ? 56 : 76),
        child: _StitchAuthHeader(compact: isCompactHeight),
      ),
      // Auth actions must remain reachable on short Android viewports; the
      // decorative site navigation is intentionally omitted from this flow.
      bottomNavigationBar: null,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            isCompactHeight ? 0 : 18,
            16,
            isCompactHeight ? 12 : 28,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StitchAuthIntro(
                    isRegister: isRegister,
                    compact: isCompactHeight,
                    title: isRegister
                        ? 'Tạo Hồ Sơ Bệnh Nhân Mới'
                        : 'Đăng nhập tài khoản',
                    subtitle: isRegister
                        ? 'Đăng ký để đặt khám trực tuyến, liên kết BHYT và nhận kết quả xét nghiệm tức thì bảo mật cao.'
                        : 'Quản lý hồ sơ y tế, đặt lịch khám và bệnh án điện tử an toàn, bảo mật tiêu chuẩn Bộ Y Tế.',
                  ),
                  if (isRegister) ...[
                    const SizedBox(height: 18),
                    const _StitchRegisterStepper(),
                  ],
                  const SizedBox(height: 18),
                  _StitchAuthTabs(isRegister: isRegister),
                  const SizedBox(height: 18),
                  form,
                  const SizedBox(height: 12),
                  Text(
                    'Bảo mật thông tin bệnh nhân theo tiêu chuẩn HIPAA & Bộ Y Tế',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF7FE0B5)
                          : const Color(0xFF006C49),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StitchAuthHeader extends StatelessWidget {
  const _StitchAuthHeader({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF111D2C)
        : Colors.white.withValues(alpha: .92),
    elevation: 1,
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 14, 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E7FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                color: _authBlue,
                size: 23,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MedCare Hospital',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : _authBlue,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (!compact)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: _authBlue,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            'Cơ sở 1 - Q. Hoàn Kiếm, Hà Nội',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white60
                                  : _authMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          size: 15,
                          color: _authMuted,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Thông báo',
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.notifications),
              icon: const Badge(
                smallSize: 7,
                backgroundColor: Color(0xFFBA1A1A),
                child: Icon(Icons.notifications_none_rounded),
              ),
            ),
            const CircleAvatar(
              radius: 17,
              backgroundColor: Color(0xFFD9E5F7),
              child: Icon(Icons.person_rounded, color: _authBlue, size: 21),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StitchAuthIntro extends StatelessWidget {
  const _StitchAuthIntro({
    required this.isRegister,
    this.compact = false,
    required this.title,
    required this.subtitle,
  });

  final bool isRegister;
  final bool compact;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: isRegister ? 64 : (compact ? 58 : 78),
            height: isRegister ? 64 : (compact ? 58 : 78),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E7FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.local_hospital_rounded,
              color: _authBlue,
              size: 38,
            ),
          ),
          Positioned(
            right: -5,
            bottom: -5,
            child: Container(
              width: 25,
              height: 25,
              decoration: const BoxDecoration(
                color: Color(0xFF00885D),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: Colors.white,
                size: 15,
              ),
            ),
          ),
        ],
      ),
      SizedBox(height: compact ? 6 : 13),
      if (isRegister)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFC9E6FF).withValues(alpha: .8),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            '◉  Cổng Đăng Ký Y Tế Điện Tử',
            style: TextStyle(
              color: Color(0xFF004C6E),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        )
      else
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 7,
          children: [
            const Text(
              'MedCare Hospital',
              style: TextStyle(
                color: _authBlue,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFC9E6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Portal Bệnh Nhân',
                style: TextStyle(
                  color: Color(0xFF004666),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      SizedBox(height: compact ? 4 : 7),
      Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : const Color(0xFF131B2E),
          fontSize: isRegister ? 20 : 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      if (!compact) ...[
        const SizedBox(height: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : const Color(0xFF424655),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    ],
  );
}

class _StitchRegisterStepper extends StatelessWidget {
  const _StitchRegisterStepper();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .78),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E7FF)),
    ),
    child: const Row(
      children: [
        _StitchStep(number: '1', label: 'Thông tin', active: true),
        Expanded(child: Divider(color: Color(0xFFCBD5F5))),
        _StitchStep(number: '2', label: 'Xác thực\nOTP'),
        Expanded(child: Divider(color: Color(0xFFCBD5F5))),
        _StitchStep(number: '3', label: 'Hoàn tất'),
      ],
    ),
  );
}

class _StitchStep extends StatelessWidget {
  const _StitchStep({
    required this.number,
    required this.label,
    this.active = false,
  });

  final String number;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 70,
    child: Column(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: active ? _authBlue : const Color(0xFFDAE2FF),
          child: Text(
            number,
            style: TextStyle(
              color: active ? Colors.white : const Color(0xFF424655),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? _authBlue : const Color(0xFF424655),
            fontSize: 10,
            height: 1.15,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _StitchAuthTabs extends StatelessWidget {
  const _StitchAuthTabs({required this.isRegister});

  final bool isRegister;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFE2E7FF),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        Expanded(
          child: _StitchTab(
            icon: Icons.lock_open_rounded,
            label: 'Đăng nhập',
            active: !isRegister,
            onTap: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.login),
          ),
        ),
        Expanded(
          child: _StitchTab(
            icon: Icons.person_add_alt_1_rounded,
            label: 'Đăng ký mới',
            active: isRegister,
            onTap: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.register),
          ),
        ),
      ],
    ),
  );
}

class _StitchTab extends StatelessWidget {
  const _StitchTab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(10),
    onTap: active ? null : onTap,
    child: Container(
      height: 48,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        boxShadow: active
            ? const [BoxShadow(color: Color(0x140F172A), blurRadius: 4)]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: active ? _authBlue : const Color(0xFF424655),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: active ? _authBlue : const Color(0xFF424655),
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

// ignore: unused_element
class _StitchBottomNavigation extends StatelessWidget {
  const _StitchBottomNavigation({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const routes = [
      AppRoutes.home,
      AppRoutes.doctors,
      AppRoutes.appointments,
      AppRoutes.records,
      AppRoutes.profile,
    ];
    const items = [
      (Icons.home_outlined, 'Trang chủ'),
      (Icons.medical_services_outlined, 'Bác sĩ'),
      (Icons.calendar_month_outlined, 'Lịch hẹn'),
      (Icons.description_outlined, 'Bệnh án'),
      (Icons.person_outline_rounded, 'Tài khoản'),
    ];

    return Material(
      color: isDark
          ? const Color(0xFF111D2C)
          : Colors.white.withValues(alpha: .96),
      elevation: 8,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final active = index == 4;
              return Expanded(
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, routes[index]),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.$1,
                        size: 22,
                        color: active
                            ? _authBlue
                            : (isDark
                                  ? Colors.white70
                                  : const Color(0xFF131B2E)),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.$2,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: active
                              ? _authBlue
                              : (isDark
                                    ? Colors.white70
                                    : const Color(0xFF131B2E)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _AuthGlow extends StatelessWidget {
  const _AuthGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    ),
  );
}

// ignore: unused_element
class _AuthBrand extends StatelessWidget {
  const _AuthBrand({required this.showBackButton, required this.isDark});

  final bool showBackButton;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (showBackButton) ...[
        IconButton(
          tooltip: 'Quay lại',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          color: isDark ? Colors.white : _authInk,
          style: IconButton.styleFrom(
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: .08)
                : Colors.white,
            side: BorderSide(
              color: isDark ? Colors.white12 : const Color(0xFFE0EAF4),
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0B67D1), Color(0xFF16A6C7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _authBlue.withValues(alpha: .22),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.local_hospital_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      const SizedBox(width: 11),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MedCare',
            style: TextStyle(
              color: isDark ? Colors.white : _authNavy,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -.3,
            ),
          ),
          Text(
            'HOSPITAL CARE PLATFORM',
            style: TextStyle(
              color: isDark ? Colors.white54 : _authMuted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    ],
  );
}

// ignore: unused_element
class _AuthHero extends StatelessWidget {
  const _AuthHero({
    required this.title,
    required this.description,
    required this.icon,
    required this.features,
    // ignore: unused_element_parameter
    this.compact = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<String> features;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 18 : 34),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A4D9A), Color(0xFF0D8BB5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(compact ? 22 : 30),
        boxShadow: [
          BoxShadow(
            color: _authBlue.withValues(alpha: .22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -22,
            child: Icon(
              Icons.health_and_safety_rounded,
              size: compact ? 78 : 180,
              color: Colors.white.withValues(alpha: .08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 40 : 54,
                height: compact ? 40 : 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(compact ? 13 : 17),
                  border: Border.all(color: Colors.white24),
                ),
                child: Icon(icon, color: Colors.white, size: compact ? 23 : 30),
              ),
              SizedBox(height: compact ? 12 : 26),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 20 : 34,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .82),
                  fontSize: compact ? 12 : 15,
                  height: 1.45,
                ),
              ),
              if (!compact && features.isNotEmpty) ...[
                const SizedBox(height: 24),
                ...features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (compact)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Bảo mật thông tin y tế',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .9),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _AuthFormCard extends StatelessWidget {
  const _AuthFormCard({
    required this.title,
    required this.subtitle,
    required this.surface,
    required this.outline,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Color surface;
  final Color outline;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: outline),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? .24 : .07,
          ),
          blurRadius: 30,
          offset: const Offset(0, 16),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : _authInk,
            fontSize: 25,
            fontWeight: FontWeight.w900,
            letterSpacing: -.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white60
                : _authMuted,
            fontSize: 13,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 22),
        child,
      ],
    ),
  );
}

class _AuthNotice extends StatelessWidget {
  const _AuthNotice({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF6EB5FF) : _authBlue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: .16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : _authMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StitchQrBanner extends StatelessWidget {
  const _StitchQrBanner();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFC9E6FF).withValues(alpha: .65),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFB1D8F4)),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.qr_code_2_rounded,
            color: _authBlue,
            size: 27,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Quét mã QR trên CCCD gắn chip  ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: 'Nhanh',
                  style: TextStyle(
                    color: Color(0xFF006C49),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: '\nTự động điền Họ tên, Ngày sinh & Số CCCD',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: _authMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Icon(Icons.arrow_forward_rounded, color: _authBlue, size: 20),
      ],
    ),
  );
}

class _StitchFieldLabel extends StatelessWidget {
  const _StitchFieldLabel({required this.label, this.trailing});

  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.label_important_outline, color: _authBlue, size: 15),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF131B2E),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      if (trailing != null)
        Text(
          trailing!,
          style: const TextStyle(
            color: _authBlue,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
    ],
  );
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});
  @override
  Widget build(BuildContext context) => const _FeaturePage(
    title: 'MedCare Hospital',
    icon: Icons.local_hospital,
    message: 'Chăm sóc sức khỏe tận tâm, an toàn và thuận tiện.',
    actionText: 'Bắt đầu',
    actionRoute: AppRoutes.login,
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _CleanLoginPageState();
}

class _CleanLoginPageState extends State<LoginPage> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    if (identifier.isEmpty || password.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Đăng nhập không thành công: vui lòng nhập tài khoản và mật khẩu.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final store = MedicalScope.of(context);
    final ok = await store.loginOnlineFirst(
      identifier: identifier,
      password: password,
    );
    if (!mounted) return;

    if (!ok) {
      setState(() => _isLoading = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            store.lastAuthError ?? 'Đăng nhập không thành công: tài khoản hoặc mật khẩu không đúng.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Đăng nhập thành công với quyền ${_roleLabel(store.currentUserRole)}.',
        ),
        backgroundColor: Colors.green,
      ),
    );
    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.landingForRole(store.currentUserRole),
      (_) => false,
    );
  }

  String _roleLabel(UserRole role) => switch (role) {
    UserRole.patient => 'bệnh nhân',
    UserRole.doctor => 'bác sĩ',
    UserRole.admin => 'quản trị viên',
  };

  @override
  Widget build(BuildContext context) => _AuthScaffold(
    formTitle: 'Chào mừng trở lại',
    formSubtitle: 'Đăng nhập để tiếp tục hành trình chăm sóc sức khỏe.',
    heroTitle: 'Chăm sóc sức khỏe\ntrong tầm tay.',
    heroDescription: 'Quản lý lịch khám, hồ sơ y tế và kết nối cùng đội ngũ chuyên môn trên một nền tảng an toàn.',
    heroIcon: Icons.favorite_rounded,
    heroFeatures: const [
      'Tự nhận diện đúng quyền truy cập sau khi đăng nhập',
      'Bảo mật thông tin y tế và phiên làm việc',
      'Kết nối nhanh với bệnh viện và bác sĩ',
    ],
    form: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StitchFieldLabel(
          label: 'Số điện thoại hoặc Mã bệnh nhân (Mã BN)',
          trailing: 'Mã BN ở đâu?',
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _identifierController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Số điện thoại hoặc Mã bệnh nhân',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: 12),
        const _StitchFieldLabel(label: 'Mật khẩu', trailing: 'Quên mật khẩu?'),
        const SizedBox(height: 6),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _isLoading ? null : _handleLogin(),
          decoration: InputDecoration(
            hintText: 'Nhập mật khẩu của bạn',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: _isLoading ? null : _handleLogin,
            style: FilledButton.styleFrom(
              backgroundColor: _authBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.arrow_forward_rounded),
            label: Text(_isLoading ? 'Đang xác thực...' : 'Đăng nhập'),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.pushNamed(
                          context,
                          AppRoutes.forgotPassword,
                        ),
                  child: const Text('Quên mật khẩu?'),
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.pushNamed(context, AppRoutes.register),
                  child: const Text('Tạo hồ sơ mới'),
                ),
              ),
            ),
          ],
        ),
        const Divider(height: 22),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.emergencySos),
            icon: const Icon(Icons.emergency_outlined, size: 19),
            label: const Text('Cần hỗ trợ khẩn cấp? Gọi 115'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFBA1A1A),
              padding: const EdgeInsets.symmetric(vertical: 11),
            ),
          ),
        ),
      ],
    ),
  );
}

class LegacyLoginPage extends StatefulWidget {
  const LegacyLoginPage({super.key});

  @override
  State<LegacyLoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LegacyLoginPage> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số điện thoại/email và mật khẩu.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final store = MedicalScope.of(context);
    final ok = await store.loginOnlineFirst(
      identifier: identifier,
      password: password,
    );
    if (!mounted) return;

    if (!ok) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            store.lastAuthError ??
                'Thông tin đăng nhập không đúng hoặc tài khoản chưa được cấp.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (store.isDoctorRole) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.doctorPortal,
        (_) => false,
      );
    } else if (store.isAdminRole) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.adminSlots,
        (_) => false,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    }
  }

  void _fillAccount(String id, String pass) {
    setState(() {
      _identifierController.text = id;
      _passwordController.text = pass;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã điền tài khoản: $id'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF0057CD);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── HERO BANNER VỚI HÌNH ẢNH BỆNH VIỆN VÀ GRADIENT ──
            Stack(
              children: [
                // Hình ảnh nền y tế chuẩn hiện đại
                Container(
                  height: 260,
                  width: double.infinity,
                  decoration: const BoxDecoration(color: Color(0xFF003882)),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=900&auto=format&fit=crop&q=80',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF002966),
                            Color(0xFF0057CD),
                            Color(0xFF0075FF),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),
                // Lớp phủ Gradient mờ ảo sang trọng
                Container(
                  height: 260,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF002966).withValues(alpha: 0.75),
                        const Color(0xFF004099).withValues(alpha: 0.88),
                        isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF8FAFC),
                      ],
                      stops: const [0.0, 0.65, 1.0],
                    ),
                  ),
                ),
                // Nội dung Brand trong Header
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Icon(
                                Icons.local_hospital_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.verified,
                                    color: Colors.lightGreenAccent,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'JCI & HIPAA 2026',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'MedCare Hospital',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Hệ Thống Y Tế & Chăm Sóc Sức Khỏe Thông Minh',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── THẺ FORM ĐĂNG NHẬP CHÍNH (FLOATING CARD) ──
            Transform.translate(
              offset: const Offset(0, -28),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.3 : 0.08,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đăng nhập tài khoản',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chào mừng quý khách quay trở lại MedCare',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // TextField 0: Email hoặc SĐT
                    Text(
                      'Số điện thoại hoặc email',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _identifierController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Email hoặc số điện thoại...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white30 : Colors.black38,
                        ),
                        prefixIcon: const Icon(
                          Icons.alternate_email_rounded,
                          color: primaryColor,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF334155).withValues(alpha: 0.5)
                            : const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: primaryColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // TextField 1: Mật khẩu
                    Text(
                      'Mật khẩu',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Nhập mật khẩu (tối thiểu 6 ký tự)',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white30 : Colors.black38,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: primaryColor,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: isDark ? Colors.white60 : Colors.black45,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF334155).withValues(alpha: 0.5)
                            : const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: primaryColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    // Ghi nhớ & Quên mật khẩu
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (val) =>
                                    setState(() => _rememberMe = val ?? true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ghi nhớ đăng nhập',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.forgotPassword,
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Quên mật khẩu?',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Nút Đăng nhập chính
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                          shadowColor: primaryColor.withValues(alpha: 0.4),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.login_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Đăng nhập',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    // Tài khoản nội bộ được cấp
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: Colors.amber.shade700,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'TÀI KHOẢN NỘI BỘ ĐƯỢC CẤP:',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.register,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: primaryColor.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    child: const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Bệnh nhân',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Đăng ký để tạo hồ sơ',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _fillAccount(
                                    'doctor@medcare.vn',
                                    '123456',
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.teal.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    child: const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Bác sĩ',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'doctor@medcare.vn',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () =>
                                _fillAccount('admin@medcare.vn', 'admin123'),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.purple.withValues(alpha: 0.2),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Admin Quản trị',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'admin@medcare.vn',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Luồng xác thực bổ sung
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Hoặc xác thực bổ sung',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white38 : Colors.black45,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialButton(
                          icon: Icons.fingerprint,
                          label: 'Sinh trắc',
                          color: Colors.blue.shade700,
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.register),
                        ),
                        const SizedBox(width: 14),
                        _socialButton(
                          icon: Icons.qr_code_scanner,
                          label: 'BHYT QR',
                          color: Colors.teal,
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.register),
                        ),
                        const SizedBox(width: 14),
                        _socialButton(
                          icon: Icons.g_mobiledata,
                          label: 'Google',
                          color: Colors.red.shade600,
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.register),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── LIÊN KẾT ĐĂNG KÝ & CHÂN TRANG ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Chưa có tài khoản? ',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF64748B),
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.register),
                        child: const Text(
                          'Đăng ký ngay',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Cấp cứu khẩn cấp 115 link
                  InkWell(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.emergencySos),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emergency,
                            color: Color(0xFFBA1A1A),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Cần hỗ trợ y tế khẩn cấp? Gọi 115',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Security notice
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 12,
                        color: isDark ? Colors.white38 : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Bảo mật mã hóa 256-bit AES & chuẩn HIPAA Y tế',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 88,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  bool _otpRequested = false;
  // Email is the default because it works without a Twilio SMS account.
  // Users can still switch to SMS when the backend has Twilio configured.
  String _verificationChannel = 'email';
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_otpRequested) {
      await _verifyOtp();
      return;
    }
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Đăng ký không thành công: vui lòng nhập đầy đủ thông tin.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final store = MedicalScope.of(context);
    final validation = store.validatePatientRegistration(
      name: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
    if (!mounted) return;

    if (!validation.success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(validation.message),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (store.backendApiConfigured) {
      setState(() => _isSubmitting = true);
      final result = await store.requestRegistrationOtp(
        name: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        password: _passwordController.text,
        channel: _verificationChannel,
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      if (!result.success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      setState(() {
        _otpRequested = true;
      });
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Mã OTP đã được gửi. Mã có hiệu lực trong 10 phút.'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Chưa thể đăng ký: ứng dụng chưa được kết nối dịch vụ OTP thật.',
        ),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _verifyOtp() async {
    final messenger = ScaffoldMessenger.of(context);
    if (MedicalScope.of(context).backendApiConfigured) {
      setState(() => _isSubmitting = true);
      final result = await MedicalScope.of(context).registerPatientOnline(
        name: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        password: _passwordController.text,
        code: _otpController.text.trim(),
        channel: _verificationChannel,
      );
      if (!mounted) return;
      if (!result.success) {
        setState(() => _isSubmitting = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
      return;
    }

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Cần kết nối backend để xác thực OTP.'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? Colors.white70 : _authMuted;

    return _AuthScaffold(
      showBackButton: true,
      formTitle: _otpRequested
          ? (_verificationChannel == 'email'
                ? 'Xác thực email'
                : 'Xác thực số điện thoại')
          : 'Tạo hồ sơ bệnh nhân',
      formSubtitle: _otpRequested
          ? 'Nhập mã OTP để hoàn tất đăng ký tài khoản.'
          : 'Điền thông tin để bắt đầu quản lý sức khỏe chủ động.',
      heroTitle: 'Bắt đầu hành trình\nkhỏe mạnh hơn.',
      heroDescription: 'Tạo hồ sơ MedCare để đặt lịch, lưu trữ thông tin y tế và nhận hỗ trợ phù hợp với bạn.',
      heroIcon: Icons.person_add_alt_1_rounded,
      heroFeatures: const [
        'Hồ sơ y tế được đồng bộ an toàn',
        'Đăng ký nhanh bằng mã OTP',
        'Dễ dàng quản lý lịch khám và người thân',
      ],
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StitchQrBanner(),
          const SizedBox(height: 16),
          _AuthField(
            controller: _nameController,
            label: 'Họ và tên',
            icon: Icons.badge_outlined,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _AuthField(
            controller: _phoneController,
            label: 'Số điện thoại',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _AuthField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          if (!_otpRequested) ...[
            const SizedBox(height: 14),
            Text(
              'Kênh nhận mã xác nhận',
              style: TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  selected: _verificationChannel == 'sms',
                  avatar: const Icon(Icons.sms_outlined, size: 18),
                  label: const Text('SMS OTP'),
                  onSelected: (_) =>
                      setState(() => _verificationChannel = 'sms'),
                ),
                ChoiceChip(
                  selected: _verificationChannel == 'email',
                  avatar: const Icon(Icons.email_outlined, size: 18),
                  label: const Text('Email/Gmail OTP'),
                  onSelected: (_) =>
                      setState(() => _verificationChannel = 'email'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _AuthField(
            controller: _passwordController,
            label: 'Mật khẩu',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _AuthField(
            controller: _confirmPasswordController,
            label: 'Nhập lại mật khẩu',
            icon: Icons.verified_user_outlined,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _isSubmitting ? null : _handleRegister(),
            suffixIcon: IconButton(
              tooltip: _obscureConfirmPassword
                  ? 'Hiện mật khẩu'
                  : 'Ẩn mật khẩu',
              onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          if (_otpRequested) ...[
            const SizedBox(height: 12),
            _AuthField(
              controller: _otpController,
              label: 'Mã OTP 6 số',
              icon: _verificationChannel == 'email'
                  ? Icons.email_outlined
                  : Icons.sms_outlined,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _isSubmitting ? null : _handleRegister(),
            ),
          ],
          const SizedBox(height: 14),
          _AuthNotice(
            icon: _otpRequested
                ? (_verificationChannel == 'email'
                      ? Icons.email_outlined
                      : Icons.sms_outlined)
                : Icons.info_outline_rounded,
            title: _otpRequested ? 'Mã OTP đã được gửi' : 'Lưu ý khi đăng ký',
            message: _otpRequested
                ? 'Kiểm tra ${_verificationChannel == 'email' ? 'hộp thư Gmail/email' : 'tin nhắn SMS'} và không chia sẻ mã OTP với bất kỳ ai.'
                : 'Email đúng định dạng, số điện thoại Việt Nam, mật khẩu từ 6 ký tự gồm chữ và số.',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _handleRegister,
              style: FilledButton.styleFrom(
                backgroundColor: _authBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _otpRequested
                          ? Icons.verified_outlined
                          : Icons.arrow_forward_rounded,
                    ),
              label: Text(
                _isSubmitting
                    ? 'Đang xử lý...'
                    : _otpRequested
                    ? 'Xác nhận OTP và tạo tài khoản'
                    : 'Tiếp tục đăng ký',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.login,
                    ),
              child: const Text('Đã có tài khoản? Đăng nhập'),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Thông tin của bạn được bảo vệ trong suốt quá trình sử dụng.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 10.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : const Color(0xFF131B2E),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: switch (label) {
            'Họ và tên' => 'TRẦN HOÀNG MINH',
            'Số điện thoại' => '0912 345 678',
            'Email' => 'email@example.com',
            'Mật khẩu' => 'Tạo mật khẩu an toàn',
            'Nhập lại mật khẩu' => 'Nhập lại mật khẩu',
            'Mã OTP 6 số' => 'Nhập mã OTP 6 số',
            _ => null,
          },
          prefixIcon: Icon(icon),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    ],
  );
}

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});
  @override
  Widget build(BuildContext context) => const _FormPage(
    title: 'Quên mật khẩu',
    fields: ['Số điện thoại hoặc email'],
    action: 'Nhận mã xác thực',
    actionRoute: AppRoutes.otp,
    secondary: 'Nhập mã OTP',
    secondaryRoute: AppRoutes.otp,
  );
}

class OtpPage extends StatelessWidget {
  const OtpPage({super.key});
  @override
  Widget build(BuildContext context) => const _FormPage(
    title: 'Xác thực OTP',
    fields: ['Mã OTP 6 số'],
    action: 'Xác nhận',
    actionRoute: AppRoutes.home,
    secondary: 'Gửi lại mã',
  );
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctors = MedicalScope.of(context).doctors;
    final query = _controller.text.trim().toLowerCase();
    final matchingDoctors = doctors
        .where(
          (doctor) =>
              query.isEmpty ||
              doctor.name.toLowerCase().contains(query) ||
              doctor.specialty.toLowerCase().contains(query) ||
              doctor.experience.toLowerCase().contains(query),
        )
        .take(8)
        .toList();
    final showLab = query.isEmpty || 'xét nghiệm máu'.contains(query);
    final showBooking = query.isEmpty || 'đặt lịch khám'.contains(query);
    return Scaffold(
      appBar: AppBar(title: const Text('Tìm kiếm')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _openResult(_controller.text),
            decoration: InputDecoration(
              hintText: 'Tìm bác sĩ, chuyên khoa, dịch vụ...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => setState(_controller.clear),
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            query.isEmpty ? 'Gợi ý tìm kiếm' : 'Kết quả phù hợp',
            style: _heading,
          ),
          const SizedBox(height: 8),
          if (matchingDoctors.isEmpty && !showLab && !showBooking)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Không tìm thấy kết quả phù hợp.')),
            ),
          ...matchingDoctors.map((doctor) => _SearchDoctorCard(doctor: doctor)),
          if (showLab)
            ListTile(
              leading: const Icon(Icons.science_outlined),
              title: const Text('Xét nghiệm máu'),
              subtitle: const Text('Xem kết quả xét nghiệm và chỉ số'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openResult('Xét nghiệm máu'),
            ),
          if (showBooking)
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Đặt lịch khám'),
              subtitle: const Text('Chọn chuyên khoa, bác sĩ và khung giờ'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openResult('Đặt lịch khám'),
            ),
        ],
      ),
    );
  }

  void _openDoctor(DoctorProfile doctor) {
    Navigator.pushNamed(context, AppRoutes.doctorDetail, arguments: doctor);
  }

  void _openResult(String value) {
    final doctor = MedicalScope.of(context).doctors
        .cast<DoctorProfile?>()
        .firstWhere(
          (item) => item != null && value.startsWith(item.name),
          orElse: () => null,
        );
    if (doctor != null) {
      _openDoctor(doctor);
      return;
    }
    final route = value.toLowerCase().contains('đặt lịch')
        ? AppRoutes.appointments
        : value.toLowerCase().contains('xét nghiệm')
        ? AppRoutes.labResults
        : AppRoutes.doctors;
    Navigator.pushNamed(context, route);
  }
}

class _SearchDoctorCard extends StatelessWidget {
  const _SearchDoctorCard({required this.doctor});

  final DoctorProfile doctor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.doctorDetail,
                arguments: doctor,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DoctorAvatar(doctor: doctor, size: 64, borderRadius: 16),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${doctor.specialty} • ${doctor.experience}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 15,
                              color: Color(0xFFFFA000),
                            ),
                            const SizedBox(width: 4),
                            Text(doctor.rating.toStringAsFixed(1)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                doctor.availability,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF006C49),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Phí khám: ${doctor.price ~/ 1000}.000đ',
                    style: const TextStyle(
                      color: Color(0xFF0057CD),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.appointments,
                    arguments: doctor,
                  ),
                  icon: const Icon(Icons.calendar_month_outlined, size: 16),
                  label: const Text('Đặt lịch ngay'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SpecialtyListPage extends StatelessWidget {
  const SpecialtyListPage({super.key});
  @override
  Widget build(BuildContext context) {
    const specialties = [
      'Tim mạch',
      'Nhi khoa',
      'Nội tổng quát',
      'Ngoại khoa',
      'Da liễu',
      'Tai Mũi Họng',
      'Cơ xương khớp',
      'Thần kinh',
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách chuyên khoa')),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: specialties
            .map(
              (item) => Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.specialtyDetail,
                    arguments: item,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.local_hospital,
                        size: 34,
                        color: _primary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class SpecialtyDetailPage extends StatelessWidget {
  const SpecialtyDetailPage({super.key, this.specialty = 'Chuyên khoa'});
  final String specialty;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(specialty)),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _FeatureCard(
          title: 'Giới thiệu $specialty',
          text: 'Đội ngũ bác sĩ chuyên môn cao, quy trình khám an toàn và dịch vụ chăm sóc toàn diện.',
        ),
        const SizedBox(height: 16),
        const _FeatureCard(
          title: 'Dịch vụ',
          text: 'Khám tư vấn, xét nghiệm hỗ trợ và theo dõi điều trị.',
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.doctors),
          icon: const Icon(Icons.people),
          label: const Text('Xem bác sĩ'),
        ),
      ],
    ),
  );
}

class ConfirmAppointmentPage extends StatefulWidget {
  const ConfirmAppointmentPage({super.key});

  @override
  State<ConfirmAppointmentPage> createState() => _ConfirmAppointmentPageState();
}

class _ConfirmAppointmentPageState extends State<ConfirmAppointmentPage> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final profile = store.profile;
    final draft =
        ModalRoute.of(context)?.settings.arguments as AppointmentDraft?;
    if (draft == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Xác nhận đặt lịch')),
        body: const Center(child: Text('Không tìm thấy thông tin lịch hẹn.')),
      );
    }
    final date =
        '${draft.dateTime.day.toString().padLeft(2, '0')}/${draft.dateTime.month.toString().padLeft(2, '0')}/${draft.dateTime.year}';
    final time =
        '${draft.dateTime.hour.toString().padLeft(2, '0')}:${draft.dateTime.minute.toString().padLeft(2, '0')}';

    final originalPrice = draft.doctor.price;
    final packageSurcharge = draft.packagePriceDelta;
    final insuranceDiscount = draft.useInsurance
        ? (originalPrice * 0.8).round()
        : 0;
    final finalPrice = originalPrice - insuranceDiscount + packageSurcharge;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(title: const Text('Xác nhận đặt lịch khám')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E7FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 32,
                      color: Color(0xFF0057CD),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E7FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            draft.doctor.specialty,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0057CD),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          draft.doctor.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          draft.doctor.location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thời gian khám',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Color(0xFF0057CD),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ngày $date',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Color(0xFF0057CD),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Khung giờ: $time',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0057CD),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin người khám',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildKeyValue('Họ và tên:', draft.patientName),
                  _buildKeyValue('Mã bệnh nhân:', profile.id),
                  _buildKeyValue('Số điện thoại:', profile.phone),
                  _buildKeyValue(
                    'Bảo hiểm y tế:',
                    draft.useInsurance
                        ? '${profile.insuranceNumber} (Đúng tuyến - Giảm 80%)'
                        : 'Không áp dụng BHYT',
                    valueColor: draft.useInsurance
                        ? const Color(0xFF006C49)
                        : Colors.black87,
                  ),
                  _buildKeyValue('Lý do khám:', draft.reason),
                  _buildKeyValue('Gói khám:', draft.packageTitle),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chi tiết chi phí khám',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildKeyValue(
                    'Giá khám ban đầu:',
                    '${originalPrice ~/ 1000}.000đ',
                  ),
                  if (packageSurcharge > 0)
                    _buildKeyValue(
                      'Phụ phí ${draft.packageTitle}:',
                      '+${packageSurcharge ~/ 1000}.000đ',
                      valueColor: const Color(0xFF0057CD),
                    ),
                  if (draft.useInsurance)
                    _buildKeyValue(
                      'BHYT chi trả (80%):',
                      '- ${insuranceDiscount ~/ 1000}.000đ',
                      valueColor: const Color(0xFF006C49),
                    ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tạm tính thanh toán:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${finalPrice ~/ 1000}.000đ',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0057CD),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      setState(() => _isSubmitting = true);
                      try {
                        final appointment = await store.bookOnlineFirst(
                          doctor: draft.doctor,
                          dateTime: draft.dateTime,
                          patientName: draft.patientName,
                          reason: draft.reason,
                          useInsurance: draft.useInsurance,
                          packageId: draft.packageId,
                          packageTitle: draft.packageTitle,
                          packagePriceDelta: draft.packagePriceDelta,
                          priorityLevel: draft.priorityLevel,
                        );
                        if (!context.mounted) return;
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.bookingSuccess,
                          ModalRoute.withName(AppRoutes.home),
                          arguments: appointment,
                        );
                      } on StateError catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error.message),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _isSubmitting = false);
                      }
                    },
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                _isSubmitting ? 'Đang gửi yêu cầu...' : 'Xác nhận đặt lịch',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildKeyValue(String key, String value, {Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                key,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ),
          ],
        ),
      );
}

class BookingSuccessPage extends StatelessWidget {
  const BookingSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appointment =
        ModalRoute.of(context)?.settings.arguments as Appointment?;
    final date = appointment != null
        ? '${appointment.dateTime.day.toString().padLeft(2, '0')}/${appointment.dateTime.month.toString().padLeft(2, '0')}/${appointment.dateTime.year}'
        : '--/--/----';
    final time = appointment != null
        ? '${appointment.dateTime.hour.toString().padLeft(2, '0')}:${appointment.dateTime.minute.toString().padLeft(2, '0')}'
        : '--:--';

    final ticketNo = appointment?.ticketNumber ?? 'Đang cập nhật';
    final apptId = appointment?.id ?? 'Đang cập nhật';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        title: const Text('Đã tạo lịch hẹn'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFD1E7DD),
              child: Icon(
                Icons.check_rounded,
                size: 50,
                color: Color(0xFF0F5132),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Đã tạo lịch hẹn khám',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F5132),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'Vui lòng thanh toán viện phí để bệnh viện xác nhận lịch khám và mở mã check-in.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF0057CD), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Text(
                    'MÃ YÊU CẦU ĐẶT KHÁM',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Color(0xFF0057CD),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ticketNo,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0057CD),
                    ),
                  ),
                  Text(
                    'Mã lịch hẹn: $apptId • Chờ thanh toán',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_clock_outlined,
                          size: 64,
                          color: Color(0xFF664D03),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'QR mở sau thanh toán',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sau khi thanh toán thành công, lịch hẹn sẽ chuyển sang “Đã xác nhận” và dùng được tại Kiosk tiếp đón.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  const Divider(height: 24),
                  _infoRow(
                    'Bác sĩ khám:',
                    appointment?.doctorName ?? 'Đang cập nhật',
                  ),
                  _infoRow(
                    'Chuyên khoa:',
                    appointment?.specialty ?? 'Đang cập nhật',
                  ),
                  _infoRow('Thời gian:', '$date lúc $time'),
                  _infoRow(
                    'Phòng khám:',
                    appointment?.location ?? 'Đang cập nhật',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            color: const Color(0xFFFFF3CD),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF664D03), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lịch hẹn chưa được xác nhận cho đến khi thanh toán thành công. Nếu quá hạn thanh toán, bệnh viện có thể giải phóng slot.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF664D03)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.payment),
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Thanh toán để xác nhận lịch'),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.myAppointments),
            icon: const Icon(Icons.calendar_month),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F5132),
            ),
            label: const Text('Xem lịch hẹn của tôi'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (_) => false,
            ),
            child: const Text('Về trang chủ'),
          ),
        ],
      ),
    );
  }

  static Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

class MyAppointmentsPage extends StatelessWidget {
  const MyAppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final appointments = store.appointments;

    final upcoming = appointments
        .where(
          (a) =>
              a.status == AppointmentStatus.awaitingPayment ||
              a.status == AppointmentStatus.confirmed,
        )
        .toList();
    final completed = appointments
        .where((a) => a.status == AppointmentStatus.completed)
        .toList();
    final cancelled = appointments
        .where((a) => a.status == AppointmentStatus.cancelled)
        .toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF8FF),
        appBar: AppBar(
          title: const Text('Lịch hẹn của tôi'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Sắp tới (${upcoming.length})'),
              Tab(text: 'Đã khám (${completed.length})'),
              Tab(text: 'Đã hủy (${cancelled.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AppointmentList(
              items: upcoming,
              emptyMessage: 'Bạn không có lịch hẹn nào sắp tới.',
              showBookButton: true,
            ),
            _AppointmentList(
              items: completed,
              emptyMessage: 'Chưa có đợt khám nào hoàn thành.',
            ),
            _AppointmentList(
              items: cancelled,
              emptyMessage: 'Không có lịch hẹn nào đã hủy.',
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  const _AppointmentList({
    required this.items,
    required this.emptyMessage,
    this.showBookButton = false,
  });

  final List<Appointment> items;
  final String emptyMessage;
  final bool showBookButton;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.event_busy_outlined,
                size: 64,
                color: Colors.black26,
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
              if (showBookButton) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.appointments),
                  icon: const Icon(Icons.add),
                  label: const Text('Đặt lịch khám mới'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final date =
            '${item.dateTime.day.toString().padLeft(2, '0')}/${item.dateTime.month.toString().padLeft(2, '0')}/${item.dateTime.year} • ${item.dateTime.hour.toString().padLeft(2, '0')}:${item.dateTime.minute.toString().padLeft(2, '0')}';

        final (statusText, statusBg, statusFg) = switch (item.status) {
          AppointmentStatus.awaitingPayment => (
            'Chờ thanh toán',
            const Color(0xFFFFF3CD),
            const Color(0xFF664D03),
          ),
          AppointmentStatus.confirmed => (
            'Đã xác nhận',
            const Color(0xFFD1E7DD),
            const Color(0xFF0F5132),
          ),
          AppointmentStatus.completed => (
            'Đã khám',
            const Color(0xFFCFE2FF),
            const Color(0xFF084298),
          ),
          AppointmentStatus.cancelled => (
            'Đã hủy',
            const Color(0xFFF8D7DA),
            const Color(0xFF842029),
          ),
        };

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.appointmentDetail,
              arguments: item,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E7FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.ticketNumber ?? 'Chưa có mã lịch',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0057CD),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusFg,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFFE2E7FF),
                        child: Icon(Icons.person, color: Color(0xFF0057CD)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.doctorName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Khoa ${item.specialty} • ${item.location}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Color(0xFF0057CD),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AppointmentDetailPage extends StatelessWidget {
  const AppointmentDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final item = ModalRoute.of(context)?.settings.arguments as Appointment?;
    final store = MedicalScope.of(context);
    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết lịch hẹn')),
        body: const Center(child: Text('Không tìm thấy lịch hẹn.')),
      );
    }

    final date =
        '${item.dateTime.day.toString().padLeft(2, '0')}/${item.dateTime.month.toString().padLeft(2, '0')}/${item.dateTime.year} lúc ${item.dateTime.hour.toString().padLeft(2, '0')}:${item.dateTime.minute.toString().padLeft(2, '0')}';

    final (statusText, statusBg, statusFg) = switch (item.status) {
      AppointmentStatus.awaitingPayment => (
        'Chờ thanh toán để xác nhận',
        const Color(0xFFFFF3CD),
        const Color(0xFF664D03),
      ),
      AppointmentStatus.confirmed => (
        'Đã xác nhận khám',
        const Color(0xFFD1E7DD),
        const Color(0xFF0F5132),
      ),
      AppointmentStatus.completed => (
        'Đã hoàn thành khám',
        const Color(0xFFCFE2FF),
        const Color(0xFF084298),
      ),
      AppointmentStatus.cancelled => (
        'Đã hủy hẹn',
        const Color(0xFFF8D7DA),
        const Color(0xFF842029),
      ),
    };

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(title: const Text('Chi tiết lịch hẹn')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusFg,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    item.ticketNumber ?? 'Chưa có mã lịch',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0057CD),
                    ),
                  ),
                  Text(
                    'Mã phiếu khám: ${item.id}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin khám',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _row('Bác sĩ:', item.doctorName),
                  _row('Chuyên khoa:', item.specialty),
                  _row('Thời gian hẹn:', date),
                  _row('Phòng khám:', item.location),
                  _row('Người khám:', item.patientName),
                  _row(
                    'Bảo hiểm y tế:',
                    item.insuranceApplied
                        ? 'Áp dụng đúng tuyến (80%)'
                        : 'Không dùng BHYT',
                  ),
                  _row('Lý do khám:', item.reason),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.directions,
                        color: Color(0xFF0057CD),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Chỉ dẫn di chuyển nội viện',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    '1. Gửi xe tại Tòa nhà Bãi đỗ xe MedCare hoặc Cổng số 1.\n2. Đến Kiosk Tầng 1, quét mã QR để in phiếu số thứ tự.\n3. Đi thang máy B lên tầng tương ứng với phòng khám của bác sĩ.\n4. Xuất trình CCCD / VssID tại quầy điều dưỡng tiếp đón.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (item.status == AppointmentStatus.awaitingPayment) ...[
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.payment),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Thanh toán để xác nhận lịch'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.cancelAppointment,
                arguments: item,
              ),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Hủy lịch hẹn này'),
            ),
          ],
          if (item.status == AppointmentStatus.confirmed) ...[
            OutlinedButton.icon(
              onPressed: () async {
                final selected = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 180)),
                  initialDate: item.dateTime.isBefore(DateTime.now())
                      ? DateTime.now()
                      : item.dateTime,
                );
                if (!context.mounted || selected == null) return;
                final selectedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(item.dateTime),
                );
                if (!context.mounted || selectedTime == null) return;
                final target = DateTime(
                  selected.year,
                  selected.month,
                  selected.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                try {
                  await store.rescheduleAppointmentOnlineFirst(item.id, target);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã gửi yêu cầu đổi lịch khám.'),
                    ),
                  );
                  Navigator.pop(context);
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Không thể đổi lịch: $error')),
                  );
                }
              },
              icon: const Icon(Icons.event_repeat_outlined),
              label: const Text('Đổi ngày khám'),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.cancelAppointment,
                arguments: item,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC3545),
              ),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Hủy lịch hẹn này'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  final checkIn = await store.createCheckInOnline(item.id);
                  if (!context.mounted) return;
                  final payload = checkIn['payload'] is Map
                      ? Map<String, Object?>.from(checkIn['payload'] as Map)
                      : const <String, Object?>{};
                  final token = checkIn['token'] as String?;
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Mã check-in'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (token != null)
                            QrImageView(
                              data: token,
                              size: 180,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Colors.black,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Colors.black,
                              ),
                            )
                          else
                            const Icon(Icons.qr_code_2, size: 96),
                          const SizedBox(height: 12),
                          SelectableText(
                            token ??
                                'Mã đã được cấp trước đó; yêu cầu cấp lại.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Có hiệu lực đến ${payload['expiresAt'] ?? 'hết hạn theo hệ thống'}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Đóng'),
                        ),
                      ],
                    ),
                  );
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Không thể tạo mã check-in: $error'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Tạo mã check-in'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  final queue = await store.joinQueueForAppointment(item.id);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Đã nhận số ${queue.ticketCode}. Vui lòng theo dõi hàng đợi.',
                      ),
                    ),
                  );
                  Navigator.pushNamed(context, AppRoutes.liveQueue);
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Chưa thể nhận số: $error')),
                  );
                }
              },
              icon: const Icon(Icons.confirmation_number_outlined),
              label: const Text('Nhận số thứ tự'),
            ),
          ],
          if (item.status == AppointmentStatus.completed) ...[
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.records),
              icon: const Icon(Icons.folder_shared_outlined),
              label: const Text('Xem bệnh án đợt khám này'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.doctorRating),
              icon: const Icon(Icons.star_outline),
              label: const Text('Đánh giá bác sĩ'),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class CancelAppointmentPage extends StatefulWidget {
  const CancelAppointmentPage({super.key});

  @override
  State<CancelAppointmentPage> createState() => _CancelAppointmentPageState();
}

class _CancelAppointmentPageState extends State<CancelAppointmentPage> {
  int _selectedReason = 0;
  final _reasonController = TextEditingController();

  final _reasons = const [
    'Bận công việc cá nhân đột xuất',
    'Triệu chứng bệnh đã thuyên giảm / khỏi hẳn',
    'Đã khám tại cơ sở y tế khác gần nhà',
    'Muốn đổi bác sĩ chuyên khoa hoặc khung giờ khác',
    'Lý do khác',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = ModalRoute.of(context)?.settings.arguments as Appointment?;
    final store = MedicalScope.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(title: const Text('Hủy lịch khám')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (item != null)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mã lịch hẹn: ${item.ticketNumber ?? item.id}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0057CD),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.doctorName} • ${item.specialty}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      item.location,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Vui lòng cho biết lý do bạn muốn hủy lịch hẹn:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...List.generate(_reasons.length, (index) {
            final isSelected = _selectedReason == index;
            return InkWell(
              onTap: () => setState(() => _selectedReason = index),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: isSelected
                          ? const Color(0xFF0057CD)
                          : Colors.black45,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _reasons[index],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (_selectedReason == _reasons.length - 1) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Nhập chi tiết lý do hủy...',
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              try {
                if (item != null) {
                  await store.cancelAppointmentOnlineFirst(item.id);
                } else if (store.appointments.isNotEmpty) {
                  final firstConfirmed = store.appointments
                      .where(
                        (a) =>
                            a.status == AppointmentStatus.awaitingPayment ||
                            a.status == AppointmentStatus.confirmed,
                      )
                      .firstOrNull;
                  if (firstConfirmed != null) {
                    await store.cancelAppointmentOnlineFirst(firstConfirmed.id);
                  }
                }
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã hủy lịch khám thành công!'),
                    backgroundColor: Color(0xFFDC3545),
                  ),
                );
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.myAppointments,
                  ModalRoute.withName(AppRoutes.home),
                );
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Không thể hủy lịch: $error')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC3545),
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Xác nhận hủy lịch khám'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Quay lại'),
          ),
        ],
      ),
    );
  }
}

class VisitHistoryPage extends StatelessWidget {
  const VisitHistoryPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Lịch sử khám')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.event_note),
          title: const Text('Khám Tim mạch'),
          subtitle: const Text('15/10/2024 • Hoàn thành'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, AppRoutes.records),
        ),
        ListTile(
          leading: const Icon(Icons.event_note),
          title: const Text('Khám Tai Mũi Họng'),
          subtitle: const Text('28/07/2024 • Đã khỏi bệnh'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, AppRoutes.records),
        ),
      ],
    ),
  );
}

class DoctorRatingPage extends StatefulWidget {
  const DoctorRatingPage({super.key});
  @override
  State<DoctorRatingPage> createState() => _DoctorRatingPageState();
}

class _DoctorRatingPageState extends State<DoctorRatingPage> {
  int _rating = 5;
  final _comment = TextEditingController();
  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đánh giá bác sĩ')),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text('Bạn hài lòng với lần khám này?'),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => IconButton(
                onPressed: () => setState(() => _rating = index + 1),
                icon: Icon(
                  Icons.star,
                  size: 38,
                  color: index < _rating ? Colors.amber : Colors.grey,
                ),
              ),
            ),
          ),
          TextField(
            controller: _comment,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Chia sẻ nhận xét của bạn...',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _submit, child: const Text('Gửi đánh giá')),
        ],
      ),
    ),
  );
  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cảm ơn bạn đã gửi đánh giá.')),
    );
    Navigator.pop(context);
  }
}

class PatientProfilePage extends StatefulWidget {
  const PatientProfilePage({super.key});
  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  @override
  Widget build(BuildContext context) {
    final profile = MedicalScope.of(context).profile;
    final settings = AppSettingsScope.of(context);
    final phoneDisplay = settings.maskText(profile.phone);
    final insuranceDisplay = settings.maskText(profile.insuranceNumber);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        actions: [
          IconButton(
            tooltip: settings.isMaskingSensitiveData
                ? 'Hiện thông tin nhạy cảm'
                : 'Ẩn thông tin nhạy cảm',
            icon: Icon(
              settings.isMaskingSensitiveData
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
            onPressed: () {
              settings.setMaskingSensitiveData(
                !settings.isMaskingSensitiveData,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(
            radius: 42,
            backgroundColor: Color(0xFFE7F0FF),
            child: Icon(Icons.person, size: 48, color: _primary),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              profile.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          _FeatureCard(
            title: 'Thông tin bệnh nhân',
            text:
                'Mã bệnh nhân: ${profile.id}\nSố điện thoại: $phoneDisplay\nEmail: ${profile.email}\nBHYT: $insuranceDisplay',
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _editProfile,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Chỉnh sửa thông tin'),
          ),
        ],
      ),
    );
  }

  void _editProfile() {
    final profile = MedicalScope.of(context).profile;
    final name = TextEditingController(text: profile.name);
    final phone = TextEditingController(text: profile.phone);
    final email = TextEditingController(text: profile.email);
    final dob = TextEditingController(text: profile.dateOfBirth);
    final address = TextEditingController(text: profile.address);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chỉnh sửa thông tin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Họ và tên'),
              ),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
              ),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: dob,
                decoration: const InputDecoration(
                  labelText: 'Ngày sinh (DD/MM/YYYY)',
                  hintText: '15/08/2002',
                ),
              ),
              TextField(
                controller: address,
                decoration: const InputDecoration(labelText: 'Địa chỉ'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty ||
                  phone.text.trim().isEmpty ||
                  !email.text.contains('@')) {
                return;
              }
              MedicalScope.of(context).updateProfile(
                name: name.text.trim(),
                phone: phone.text.trim(),
                email: email.text.trim(),
                dateOfBirth: dob.text.trim(),
                address: address.text.trim(),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}

class LabResultsPage extends StatelessWidget {
  const LabResultsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final tests = store.labTests;
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả xét nghiệm')),
      body: tests.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Chưa có kết quả xét nghiệm mới.\nKết quả sẽ hiển thị tại đây sau khi bác sĩ chỉ định cận lâm sàng.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tests.length,
              itemBuilder: (context, index) {
                final test = tests[index];
                return ListTile(
                  title: Text(test.name),
                  subtitle: Text(
                    '${test.value} ${test.unit} (Chuẩn: ${test.normalRange})',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.labDetail),
                );
              },
            ),
    );
  }
}

class LabResultDetailPage extends StatelessWidget {
  const LabResultDetailPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chi tiết kết quả')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        _FeatureCard(
          title: 'Công thức máu',
          text: 'Hồng cầu: 4.8 T/L\nBạch cầu: 7.2 G/L\nTiểu cầu: 260 G/L\n\nKết luận: Các chỉ số trong giới hạn bình thường.',
        ),
        SizedBox(height: 14),
        _FeatureCard(
          title: 'Ghi chú bác sĩ',
          text: 'Tiếp tục theo dõi định kỳ và tái khám theo lịch hẹn.',
        ),
      ],
    ),
  );
}

class PrescriptionDetailPage extends StatelessWidget {
  const PrescriptionDetailPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final appointmentId = ModalRoute.of(context)?.settings.arguments as String?;
    final prescriptions = store.backendPrescriptions
        .where((item) {
          return appointmentId == null ||
              item['appointmentId']?.toString() == appointmentId;
        })
        .toList(growable: false);
    final prescription = prescriptions.isNotEmpty ? prescriptions.first : null;
    final medicines = prescription?['medicines'] is List
        ? (prescription!['medicines'] as List)
        : const <Object?>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đơn thuốc')),
      body: prescription == null
          ? const Center(child: Text('Chưa có đơn thuốc của ca khám này.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chẩn đoán: ${prescription['diagnosis'] ?? 'Chưa cập nhật'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text('Mã đơn: ${prescription['id'] ?? '--'}'),
                        Text('Ngày kê: ${prescription['createdAt'] ?? '--'}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (final raw in medicines.whereType<Map>())
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.medication_outlined,
                        color: Colors.teal,
                      ),
                      title: Text(
                        '${raw['name'] ?? ''} ${raw['dosage'] ?? ''}',
                      ),
                      subtitle: Text(
                        '${raw['quantity'] ?? ''}\n${raw['instruction'] ?? ''}',
                      ),
                      isThreeLine: true,
                      trailing: Text('${raw['price'] ?? 0}đ'),
                    ),
                  ),
              ],
            ),
    );
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  Future<void> _reload() async {
    await MedicalScope.of(context).refreshNotificationsFromBackend();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final items = store.notifications;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo y tế'),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => store.markAllNotificationsRead(),
              child: const Text('Đọc tất cả'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: items.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 220),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 64,
                          color: Colors.black26,
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Chưa có thông báo nào.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Các thông báo về lịch khám, kết quả xét nghiệm, CĐHA\nvà đơn thuốc điện tử sẽ hiển thị tại đây.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final (iconData, iconColor, category) = _getNotificationStyle(
                    item,
                  );
                  return Card(
                    elevation: item.read ? 0.5 : 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: item.read
                            ? (isDark
                                  ? Colors.white12
                                  : const Color(0xFFE2E8F0))
                            : iconColor.withValues(alpha: 0.5),
                        width: item.read ? 1 : 1.5,
                      ),
                    ),
                    color: item.read
                        ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                        : (isDark
                              ? const Color(0xFF1E293B)
                              : iconColor.withValues(alpha: 0.04)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        store.markNotificationRead(item.id);
                        _showNotificationDetail(context, item);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: iconColor.withValues(
                                alpha: 0.14,
                              ),
                              child: Icon(iconData, color: iconColor, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: iconColor.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          category,
                                          style: TextStyle(
                                            color: iconColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _formatNotificationTime(item.createdAt),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black45,
                                        ),
                                      ),
                                      if (!item.read) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: iconColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: item.read
                                          ? FontWeight.w600
                                          : FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.body,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.4,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
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
                },
              ),
      ),
    );
  }

  static (IconData, Color, String) _getNotificationStyle(AppNotification item) {
    final t = '${item.title} ${item.body}'.toLowerCase();
    if (t.contains('x-quang') ||
        t.contains('siêu âm') ||
        t.contains('nội soi') ||
        t.contains('cđha') ||
        t.contains('ecg')) {
      return (
        Icons.image_search_rounded,
        const Color(0xFF7C3AED),
        'CĐHA / Thăm dò',
      );
    }
    if (t.contains('xét nghiệm') ||
        t.contains('cbc') ||
        t.contains('sinh hóa')) {
      return (Icons.biotech_rounded, const Color(0xFF0D9488), 'Xét nghiệm');
    }
    if (t.contains('đơn thuốc') ||
        t.contains('uống thuốc') ||
        t.contains('dược')) {
      return (Icons.medication_rounded, const Color(0xFF059669), 'Đơn thuốc');
    }
    if (t.contains('emr') ||
        t.contains('bệnh án') ||
        t.contains('khám bệnh') ||
        t.contains('hoàn tất ca khám')) {
      return (
        Icons.medical_information_rounded,
        const Color(0xFF0057CD),
        'Hồ sơ EMR',
      );
    }
    if (t.contains('tái khám') ||
        t.contains('lịch hẹn') ||
        t.contains('phòng khám')) {
      return (
        Icons.calendar_month_rounded,
        const Color(0xFFD97706),
        'Lịch khám',
      );
    }
    if (t.contains('thanh toán') ||
        t.contains('viện phí') ||
        t.contains('hóa đơn')) {
      return (Icons.payments_rounded, const Color(0xFF2563EB), 'Viện phí');
    }
    return (
      Icons.notifications_rounded,
      const Color(0xFF0057CD),
      'Thông báo y tế',
    );
  }

  void _showNotificationDetail(BuildContext context, AppNotification item) {
    final (iconData, iconColor, category) = _getNotificationStyle(item);
    final text = '${item.title} ${item.body}'.toLowerCase();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: iconColor.withValues(alpha: 0.15),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: iconColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  item.body,
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: Colors.black45,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Thời gian: ${_formatNotificationTime(item.createdAt)}',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          if (text.contains('emr') ||
              text.contains('bệnh án') ||
              text.contains('x-quang') ||
              text.contains('nội soi') ||
              text.contains('xét nghiệm'))
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRoutes.records);
              },
              icon: const Icon(Icons.description_outlined, size: 16),
              label: const Text('Mở Hồ sơ EMR'),
            )
          else if (text.contains('thuốc'))
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRoutes.prescription);
              },
              icon: const Icon(Icons.medication_outlined, size: 16),
              label: const Text('Xem đơn thuốc'),
            )
          else if (text.contains('lịch') || text.contains('tái khám'))
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRoutes.myAppointments);
              },
              icon: const Icon(Icons.calendar_month_outlined, size: 16),
              label: const Text('Xem lịch khám'),
            ),
        ],
      ),
    );
  }

  String _formatNotificationTime(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _messageController = TextEditingController();
  String _category = 'Lịch khám';
  bool _isSubmitting = false;
  bool _isLoadingRequests = false;
  List<Map<String, Object?>> _requests = const [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung cần hỗ trợ.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    final category = _category;
    final store = MedicalScope.of(context);
    try {
      final code = await store.submitSupportRequest(
        category: category,
        message: message,
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _messageController.clear();
      await _loadRequests();
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Đã tiếp nhận yêu cầu'),
          content: Text(
            'Mã yêu cầu: $code\n\nBộ phận $category sẽ phản hồi trong giờ làm việc.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể gửi yêu cầu: $error')));
    }
  }

  Future<void> _loadRequests() async {
    final store = MedicalScope.of(context);
    if (!store.hasBackendSession) return;
    setState(() => _isLoadingRequests = true);
    try {
      final requests = await store.fetchSupportRequests();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _isLoadingRequests = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingRequests = false);
    }
  }

  Future<void> _openRequest(Map<String, Object?> request) async {
    final id = request['id'] as String?;
    if (id == null) return;
    final store = MedicalScope.of(context);
    try {
      var detail = await store.fetchSupportRequest(id);
      if (!mounted) return;
      final replyController = TextEditingController();
      var sending = false;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, dialogSetState) {
            final messages = detail['messages'] is List
                ? (detail['messages'] as List).whereType<Map>().toList()
                : const <Map>[];
            return AlertDialog(
              title: Text('Yêu cầu ${detail['id'] ?? id}'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Trạng thái: ${detail['status'] ?? 'open'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.person_outline),
                            title: Text(detail['message'] as String? ?? ''),
                          ),
                          ...messages.map(
                            (item) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.chat_bubble_outline),
                              title: Text(item['message'] as String? ?? ''),
                              subtitle: Text(item['senderId'] as String? ?? ''),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: replyController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Phản hồi',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: sending
                            ? null
                            : () async {
                                final message = replyController.text.trim();
                                if (message.isEmpty) return;
                                dialogSetState(() => sending = true);
                                try {
                                  await store.addSupportMessage(
                                    requestId: id,
                                    message: message,
                                  );
                                  detail = await store.fetchSupportRequest(id);
                                  replyController.clear();
                                } finally {
                                  dialogSetState(() => sending = false);
                                }
                              },
                        child: Text(sending ? 'Đang gửi...' : 'Gửi phản hồi'),
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
              ],
            );
          },
        ),
      );
      replyController.dispose();
      await _loadRequests();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể tải yêu cầu: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hỗ trợ & liên hệ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: const ListTile(
              leading: Icon(Icons.phone_in_talk_outlined, color: _primary),
              title: Text('Tổng đài hỗ trợ 24/7'),
              subtitle: Text('1900 1234 • Cấp cứu: 115'),
            ),
          ),
          Card(
            child: const ListTile(
              leading: Icon(Icons.location_on_outlined, color: _primary),
              title: Text('Bệnh viện Đại học Y Dược TP.HCM'),
              subtitle: Text('215 Hồng Bàng, Phường 11, Quận 5, TP.HCM'),
            ),
          ),
          if (_isLoadingRequests)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(),
            )
          else if (_requests.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Yêu cầu đã gửi',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._requests.map(
              (request) => Card(
                child: ListTile(
                  leading: const Icon(Icons.support_agent_outlined),
                  title: Text(request['category'] as String? ?? 'Hỗ trợ'),
                  subtitle: Text(request['message'] as String? ?? ''),
                  trailing: Text(request['status'] as String? ?? 'open'),
                  onTap: () => _openRequest(request),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Gửi yêu cầu hỗ trợ',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Nhóm hỗ trợ',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'Lịch khám', child: Text('Lịch khám')),
              DropdownMenuItem(value: 'Thanh toán', child: Text('Thanh toán')),
              DropdownMenuItem(value: 'Tài khoản', child: Text('Tài khoản')),
              DropdownMenuItem(value: 'Hồ sơ y tế', child: Text('Hồ sơ y tế')),
            ],
            onChanged: (value) =>
                setState(() => _category = value ?? _category),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Nội dung cần hỗ trợ',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.edit_note_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(_isSubmitting ? 'Đang gửi...' : 'Gửi yêu cầu'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Không nhập mật khẩu, mã OTP hoặc thông tin thẻ vào nội dung hỗ trợ.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final store = MedicalScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(settings.tr('settings_title'))),
      body: ListView(
        children: [
          _sectionHeader(settings.tr('settings_appearance')),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: Text(settings.tr('dark_mode')),
            subtitle: Text(settings.tr('dark_mode_desc')),
            value: settings.themeMode == ThemeMode.dark,
            onChanged: (val) {
              settings.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(settings.tr('language')),
            subtitle: Text(
              settings.locale == 'vi' ? 'Tiếng Việt 🇻🇳' : 'English 🇬🇧',
            ),
            trailing: DropdownButton<String>(
              value: settings.locale,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt 🇻🇳')),
                DropdownMenuItem(value: 'en', child: Text('English 🇬🇧')),
              ],
              onChanged: (val) {
                if (val != null) settings.setLocale(val);
              },
            ),
          ),
          const Divider(),
          _sectionHeader(settings.tr('accessibility')),
          SwitchListTile(
            secondary: const Icon(Icons.format_size_rounded),
            title: Text(settings.tr('large_text')),
            subtitle: Text(settings.tr('large_text_desc')),
            value: settings.isLargeText,
            onChanged: (val) => settings.setLargeText(val),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.contrast_rounded),
            title: Text(settings.tr('high_contrast')),
            subtitle: Text(settings.tr('high_contrast_desc')),
            value: settings.isHighContrast,
            onChanged: (val) => settings.setHighContrast(val),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.vibration_rounded),
            title: Text(settings.tr('haptics')),
            subtitle: Text(settings.tr('haptics_desc')),
            value: settings.hapticsEnabled,
            onChanged: (val) => settings.setHapticsEnabled(val),
          ),
          const Divider(),
          _sectionHeader(settings.tr('security')),
          SwitchListTile(
            secondary: const Icon(Icons.visibility_off_outlined),
            title: Text(settings.tr('mask_data')),
            subtitle: Text(settings.tr('mask_data_desc')),
            value: settings.isMaskingSensitiveData,
            onChanged: (val) => settings.setMaskingSensitiveData(val),
          ),
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: Text(settings.tr('pin_lock')),
            subtitle: Text(
              settings.pinCode != null
                  ? 'Mã PIN đang bật • Bấm để đổi hoặc tắt'
                  : settings.tr('pin_lock_desc'),
            ),
            trailing: settings.pinCode != null
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.chevron_right),
            onTap: () => _managePinDialog(settings),
          ),
          const Divider(),
          _sectionHeader(settings.tr('performance_diagnostics')),
          ListTile(
            leading: const Icon(Icons.speed_rounded, color: Colors.blue),
            title: Text(settings.tr('diagnostics_title')),
            subtitle: Text(settings.tr('diagnostics_desc')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, AppRoutes.diagnostics),
          ),
          ListTile(
            leading: const Icon(
              Icons.cleaning_services_outlined,
              color: Colors.orange,
            ),
            title: Text(settings.tr('clear_cache')),
            subtitle: const Text('Giải phóng dung lượng bộ nhớ đệm'),
            onTap: () async {
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
          ),
          const Divider(),
          _sectionHeader('Tài khoản & Thông báo'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            value: _notifications,
            onChanged: (value) => setState(() => _notifications = value),
            title: const Text('Thông báo đẩy'),
            subtitle: const Text('Lịch khám, xét nghiệm và nhắc thuốc'),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Hồ sơ bệnh nhân'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          if (store.isAdminRole) ...[
            const Divider(),
            _sectionHeader('Quản trị'),
            ListTile(
              leading: const Icon(
                Icons.admin_panel_settings_outlined,
                color: Color(0xFF0D6EFD),
              ),
              title: const Text('Quản lý Slot khám (Admin)'),
              subtitle: const Text('Giới hạn lượt đặt phòng theo khung giờ'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, AppRoutes.adminSlots),
            ),
          ],
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            onTap: _confirmLogout,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0057CD),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _managePinDialog(AppSettingsStore settings) {
    final controller = TextEditingController(text: settings.pinCode ?? '');
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thiết lập mã PIN bảo mật'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nhập mã PIN 4 chữ số để khóa bảo vệ ứng dụng:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'VD: 1234',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          if (settings.pinCode != null)
            TextButton(
              onPressed: () {
                settings.setPinCode(null);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã gỡ bỏ mã PIN bảo vệ!')),
                );
              },
              child: const Text(
                'Tắt mã PIN',
                style: TextStyle(color: Colors.red),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final pin = controller.text.trim();
              if (pin.length == 4) {
                settings.setPinCode(pin);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã cập nhật mã PIN bảo mật thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Lưu mã PIN'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Đăng xuất'),
      content: const Text('Bạn có chắc muốn đăng xuất khỏi MedCare?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            MedicalScope.of(context).logout();
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.login,
              (_) => false,
            );
          },
          child: const Text('Đăng xuất'),
        ),
      ],
    ),
  );
}

class _FeaturePage extends StatelessWidget {
  const _FeaturePage({
    required this.title,
    required this.icon,
    required this.message,
    required this.actionText,
    this.actionRoute,
  });
  final String title;
  final IconData icon;
  final String message;
  final String actionText;
  final String? actionRoute;
  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 72, color: _primary),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, height: 1.5),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => actionRoute == null
                    ? Navigator.pop(context)
                    : Navigator.pushNamed(context, actionRoute!),
                child: Text(actionText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormPage extends StatefulWidget {
  const _FormPage({
    required this.title,
    required this.fields,
    required this.action,
    required this.secondary,
    this.actionRoute,
    this.secondaryRoute,
  });
  final String title;
  final List<String> fields;
  final String action;
  final String secondary;
  final String? actionRoute;
  final String? secondaryRoute;
  @override
  State<_FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<_FormPage> {
  late final List<TextEditingController> _controllers;
  @override
  void initState() {
    super.initState();
    _controllers = widget.fields.map((_) => TextEditingController()).toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ...List.generate(widget.fields.length, (index) {
            final field = widget.fields[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TextField(
                controller: _controllers[index],
                obscureText: field.toLowerCase().contains('mật khẩu'),
                keyboardType: field.toLowerCase().contains('email')
                    ? TextInputType.emailAddress
                    : field.toLowerCase().contains('điện thoại')
                    ? TextInputType.phone
                    : TextInputType.text,
                decoration: InputDecoration(
                  labelText: field,
                  border: const OutlineInputBorder(),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: FilledButton(onPressed: _submit, child: Text(widget.action)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: widget.secondaryRoute == null
                ? () => Navigator.pop(context)
                : () => Navigator.pushNamed(context, widget.secondaryRoute!),
            child: Text(widget.secondary),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_controllers.any((controller) => controller.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thành công: vui lòng điền đầy đủ thông tin.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (widget.title == 'Đăng nhập') {
      final ok = MedicalScope.of(
        context,
      ).login(identifier: _controllers[0].text, password: _controllers[1].text);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đăng nhập không thành công: tài khoản hoặc mật khẩu không đúng.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng nhập thành công.'),
          backgroundColor: Colors.green,
        ),
      );
    }
    if (widget.title == 'Đăng ký tài khoản') {
      final name = _controllers[0].text.trim();
      final phone = _controllers[1].text.trim();
      final email = _controllers[2].text.trim();
      final password = _controllers[4].text.trim();
      if (!email.contains('@') || email.length < 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký không thành công: email không hợp lệ.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      if (password.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đăng ký không thành công: mật khẩu tối thiểu 6 ký tự.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      MedicalScope.of(context)
          .register(name: name, phone: phone, email: email, password: password);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký thành công. Tài khoản bệnh nhân đã được lưu.'),
          backgroundColor: Colors.green,
        ),
      );
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (_) => false,
        );
      });
      return;
    }
    if (widget.actionRoute == null) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushNamedAndRemoveUntil(
      context,
      widget.actionRoute!,
      (_) => false,
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.title, required this.text});
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(height: 1.5)),
        ],
      ),
    ),
  );
}

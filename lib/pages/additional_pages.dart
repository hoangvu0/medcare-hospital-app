import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../state/medical_store.dart';
import '../models/medical_models.dart';
import '../state/app_settings_store.dart';

const _primary = Color(0xFF0D6EFD);
const _heading = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});
  @override
  Widget build(BuildContext context) => _FeaturePage(
    title: 'MedCare Hospital',
    icon: Icons.local_hospital,
    message: 'Chăm sóc sức khỏe tận tâm, an toàn và thuận tiện.',
    actionText: 'Bắt đầu',
    actionRoute: MedicalScope.of(context).authenticated
        ? AppRoutes.home
        : AppRoutes.intro,
  );
}

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});
  @override
  Widget build(BuildContext context) => const _FeaturePage(
    title: 'Chào mừng đến MedCare',
    icon: Icons.health_and_safety,
    message: 'Đặt lịch khám, quản lý hồ sơ và thanh toán viện phí trong một ứng dụng.',
    actionText: 'Đăng nhập',
    actionRoute: AppRoutes.login,
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
    final ok = store.login(identifier: identifier, password: password);

    if (!ok) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu cần ít nhất 6 ký tự.'),
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
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (_) => false,
      );
    }
  }

  void _fillDemo(String id, String pass) {
    setState(() {
      _identifierController.text = id;
      _passwordController.text = pass;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã điền tài khoản mẫu: $id'),
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
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
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
                  decoration: const BoxDecoration(
                    color: Color(0xFF003882),
                  ),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=900&auto=format&fit=crop&q=80',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF002966), Color(0xFF0057CD), Color(0xFF0075FF)],
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
                        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      ],
                      stops: const [0.0, 0.65, 1.0],
                    ),
                  ),
                ),
                // Nội dung Brand trong Header
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: const Icon(
                                Icons.local_hospital_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.verified, color: Colors.lightGreenAccent, size: 14),
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
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
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
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _identifierController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'vu@example.com hoặc 0901...',
                        hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white30 : Colors.black38),
                        prefixIcon: const Icon(Icons.alternate_email_rounded, color: primaryColor, size: 20),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: primaryColor, width: 1.5),
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
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Nhập mật khẩu (tối thiểu 6 ký tự)',
                        hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white30 : Colors.black38),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: primaryColor, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: isDark ? Colors.white60 : Colors.black45,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: primaryColor, width: 1.5),
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (val) => setState(() => _rememberMe = val ?? true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ghi nhớ đăng nhập',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                          shadowColor: primaryColor.withValues(alpha: 0.4),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.login_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Đăng nhập',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    // Tiện ích Demo điền nhanh
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.amber.shade700, size: 14),
                              const SizedBox(width: 6),
                              const Text(
                                'TÀI KHOẢN MẪU ĐỂ TEST NHANH:',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _fillDemo('vu@example.com', '123456'),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                                    ),
                                    child: const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('👤 Bệnh nhân', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        Text('vu@example.com', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _fillDemo('doctor@medcare.vn', '123456'),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
                                    ),
                                    child: const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('🩺 Bác sĩ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        Text('doctor@medcare.vn', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _fillDemo('admin@medcare.vn', 'admin123'),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('⚙️ Admin Quản trị (Toàn quyền)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  Text('admin@medcare.vn', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Hoặc đăng nhập nhanh bằng
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Hoặc đăng nhập nhanh bằng',
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black45),
                          ),
                        ),
                        Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
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
                          onTap: () => _fillDemo('vu@example.com', '123456'),
                        ),
                        const SizedBox(width: 14),
                        _socialButton(
                          icon: Icons.qr_code_scanner,
                          label: 'BHYT QR',
                          color: Colors.teal,
                          onTap: () => _fillDemo('vu@example.com', '123456'),
                        ),
                        const SizedBox(width: 14),
                        _socialButton(
                          icon: Icons.g_mobiledata,
                          label: 'Google',
                          color: Colors.red.shade600,
                          onTap: () => _fillDemo('vu@example.com', '123456'),
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
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.register),
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
                    onTap: () => Navigator.pushNamed(context, AppRoutes.emergencySos),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emergency, color: Color(0xFFBA1A1A), size: 16),
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
                      Icon(Icons.shield_outlined, size: 12, color: isDark ? Colors.white38 : Colors.grey),
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
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});
  @override
  Widget build(BuildContext context) => const _FormPage(
    title: 'Đăng ký tài khoản',
    fields: ['Họ và tên', 'Số điện thoại', 'Email', 'Ngày sinh', 'Mật khẩu'],
    action: 'Tạo tài khoản',
    actionRoute: AppRoutes.home,
    secondary: 'Đã có tài khoản? Đăng nhập',
    secondaryRoute: AppRoutes.login,
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
    final query = _controller.text.trim().toLowerCase();
    final suggestions = [
      ...MedicalScope.of(context).doctors
          .map((doctor) => '${doctor.name} • ${doctor.specialty}'),
      'Xét nghiệm máu',
      'Đặt lịch khám',
    ];
    final results = suggestions
        .where((item) => item.toLowerCase().contains(query))
        .toList();
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
          if (results.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Không tìm thấy kết quả phù hợp.')),
            ),
          ...results.map(
            (item) => ListTile(
              leading: const Icon(Icons.search),
              title: Text(item),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openResult(item),
            ),
          ),
        ],
      ),
    );
  }

  void _openResult(String value) {
    final route = value.toLowerCase().contains('đặt lịch')
        ? AppRoutes.appointments
        : value.toLowerCase().contains('xét nghiệm')
        ? AppRoutes.labResults
        : AppRoutes.doctors;
    Navigator.pushNamed(context, route);
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

class ConfirmAppointmentPage extends StatelessWidget {
  const ConfirmAppointmentPage({super.key});
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
    final insuranceDiscount = draft.useInsurance ? (originalPrice * 0.8).round() : 0;
    final finalPrice = originalPrice - insuranceDiscount;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(title: const Text('Xác nhận đặt lịch khám')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    child: const Icon(Icons.person, size: 32, color: Color(0xFF0057CD)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          draft.doctor.location,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thời gian khám', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Color(0xFF0057CD)),
                      const SizedBox(width: 8),
                      Text('Ngày $date', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      const Icon(Icons.access_time, size: 16, color: Color(0xFF0057CD)),
                      const SizedBox(width: 8),
                      Text('Khung giờ: $time', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0057CD))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thông tin người khám', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildKeyValue('Họ và tên:', draft.patientName),
                  _buildKeyValue('Mã bệnh nhân:', profile.id),
                  _buildKeyValue('Số điện thoại:', profile.phone),
                  _buildKeyValue(
                    'Bảo hiểm y tế:',
                    draft.useInsurance ? '${profile.insuranceNumber} (Đúng tuyến - Giảm 80%)' : 'Không áp dụng BHYT',
                    valueColor: draft.useInsurance ? const Color(0xFF006C49) : Colors.black87,
                  ),
                  _buildKeyValue('Lý do khám:', draft.reason),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chi tiết chi phí khám', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildKeyValue('Giá khám ban đầu:', '${originalPrice ~/ 1000}.000đ'),
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
                      const Text('Tạm tính thanh toán:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
              onPressed: () {
                final appointment = store.book(
                  doctor: draft.doctor,
                  dateTime: draft.dateTime,
                  patientName: draft.patientName,
                  reason: draft.reason,
                  useInsurance: draft.useInsurance,
                );
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.bookingSuccess,
                  ModalRoute.withName(AppRoutes.home),
                  arguments: appointment,
                );
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Xác nhận đặt lịch', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildKeyValue(String key, String value, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(key, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? Colors.black87),
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
    final appointment = ModalRoute.of(context)?.settings.arguments as Appointment?;
    final date = appointment != null
        ? '${appointment.dateTime.day.toString().padLeft(2, '0')}/${appointment.dateTime.month.toString().padLeft(2, '0')}/${appointment.dateTime.year}'
        : '20/03/2026';
    final time = appointment != null
        ? '${appointment.dateTime.hour.toString().padLeft(2, '0')}:${appointment.dateTime.minute.toString().padLeft(2, '0')}'
        : '09:00';

    final ticketNo = appointment?.ticketNumber ?? 'KB-0824';
    final apptId = appointment?.id ?? 'AP-2026-8924';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        title: const Text('Đặt lịch thành công'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFD1E7DD),
              child: Icon(Icons.check_rounded, size: 50, color: Color(0xFF0F5132)),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Đặt lịch khám thành công!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F5132)),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'Phiếu khám điện tử của bạn đã được ghi nhận vào hệ thống.',
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
                    'SỐ THỨ TỰ KHÁM TIẾP ĐÓN',
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
                    'Mã lịch hẹn: $apptId',
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
                        Icon(Icons.qr_code_2, size: 100, color: Colors.black87),
                        Text(
                          'Mã QR Check-in',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Quét mã QR tại Kiosk Tiếp đón tầng 1 để nhận phiếu in tự động',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  const Divider(height: 24),
                  _infoRow('Bác sĩ khám:', appointment?.doctorName ?? 'PGS.TS.BS Nguyễn Văn An'),
                  _infoRow('Chuyên khoa:', appointment?.specialty ?? 'Tiêu hóa'),
                  _infoRow('Thời gian:', '$date lúc $time'),
                  _infoRow('Phòng khám:', appointment?.location ?? 'Phòng 305, Tòa B'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            color: const Color(0xFFFFF3CD),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF664D03), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vui lòng mang theo CCCD gắn chip hoặc thẻ BHYT trên ứng dụng VssID và đến trước giờ khám 15 phút.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF664D03)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.myAppointments),
            icon: const Icon(Icons.calendar_month),
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
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

    final upcoming = appointments.where((a) => a.status == AppointmentStatus.confirmed).toList();
    final completed = appointments.where((a) => a.status == AppointmentStatus.completed).toList();
    final cancelled = appointments.where((a) => a.status == AppointmentStatus.cancelled).toList();

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
              const Icon(Icons.event_busy_outlined, size: 64, color: Colors.black26),
              const SizedBox(height: 16),
              Text(emptyMessage, style: const TextStyle(fontSize: 15, color: Colors.black54)),
              if (showBookButton) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.appointments),
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
          AppointmentStatus.confirmed => ('Đã xác nhận', const Color(0xFFD1E7DD), const Color(0xFF0F5132)),
          AppointmentStatus.completed => ('Đã khám', const Color(0xFFCFE2FF), const Color(0xFF084298)),
          AppointmentStatus.cancelled => ('Đã hủy', const Color(0xFFF8D7DA), const Color(0xFF842029)),
        };

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E7FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.ticketNumber ?? 'KB-0824',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0057CD),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Khoa ${item.specialty} • ${item.location}',
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
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
                      const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF0057CD)),
                      const SizedBox(width: 6),
                      Text(date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      const Icon(Icons.chevron_right, size: 18, color: Colors.black45),
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
    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết lịch hẹn')),
        body: const Center(child: Text('Không tìm thấy lịch hẹn.')),
      );
    }

    final date =
        '${item.dateTime.day.toString().padLeft(2, '0')}/${item.dateTime.month.toString().padLeft(2, '0')}/${item.dateTime.year} lúc ${item.dateTime.hour.toString().padLeft(2, '0')}:${item.dateTime.minute.toString().padLeft(2, '0')}';

    final (statusText, statusBg, statusFg) = switch (item.status) {
      AppointmentStatus.confirmed => ('Đã xác nhận khám', const Color(0xFFD1E7DD), const Color(0xFF0F5132)),
      AppointmentStatus.completed => ('Đã hoàn thành khám', const Color(0xFFCFE2FF), const Color(0xFF084298)),
      AppointmentStatus.cancelled => ('Đã hủy hẹn', const Color(0xFFF8D7DA), const Color(0xFF842029)),
    };

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(title: const Text('Chi tiết lịch hẹn')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(fontWeight: FontWeight.bold, color: statusFg),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    item.ticketNumber ?? 'KB-0824',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0057CD)),
                  ),
                  Text('Mã phiếu khám: ${item.id}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thông tin khám', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _row('Bác sĩ:', item.doctorName),
                  _row('Chuyên khoa:', item.specialty),
                  _row('Thời gian hẹn:', date),
                  _row('Phòng khám:', item.location),
                  _row('Người khám:', item.patientName),
                  _row('Bảo hiểm y tế:', item.insuranceApplied ? 'Áp dụng đúng tuyến (80%)' : 'Không dùng BHYT'),
                  _row('Lý do khám:', item.reason),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions, color: Color(0xFF0057CD), size: 20),
                      SizedBox(width: 8),
                      Text('Chỉ dẫn di chuyển nội viện', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    '1. Gửi xe tại Tòa nhà Bãi đỗ xe MedCare hoặc Cổng số 1.\n2. Đến Kiosk Tầng 1, quét mã QR để in phiếu số thứ tự.\n3. Đi thang máy B lên tầng tương ứng với phòng khám của bác sĩ.\n4. Xuất trình CCCD / VssID tại quầy điều dưỡng tiếp đón.',
                    style: TextStyle(fontSize: 12, height: 1.6, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (item.status == AppointmentStatus.confirmed) ...[
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
          ],
          if (item.status == AppointmentStatus.completed) ...[
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.records),
              icon: const Icon(Icons.folder_shared_outlined),
              label: const Text('Xem bệnh án đợt khám này'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.doctorRating),
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
          child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lịch hẹn: ${item.ticketNumber ?? item.id}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0057CD)),
                    ),
                    const SizedBox(height: 4),
                    Text('${item.doctorName} • ${item.specialty}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    Text(item.location, style: const TextStyle(fontSize: 12, color: Colors.black54)),
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
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? const Color(0xFF0057CD) : Colors.black45,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_reasons[index], style: const TextStyle(fontSize: 14)),
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
            onPressed: () {
              if (item != null) {
                store.cancelAppointment(item.id);
              } else if (store.appointments.isNotEmpty) {
                final firstConfirmed = store.appointments.where((a) => a.status == AppointmentStatus.confirmed).firstOrNull;
                if (firstConfirmed != null) {
                  store.cancelAppointment(firstConfirmed.id);
                }
              }
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
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
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
              settings.setMaskingSensitiveData(!settings.isMaskingSensitiveData);
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
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chỉnh sửa thông tin'),
        content: Column(
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
          ],
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kết quả xét nghiệm')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          title: const Text('Công thức máu'),
          subtitle: const Text('18/10/2024 • Bình thường'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, AppRoutes.labDetail),
        ),
        ListTile(
          title: const Text('Xét nghiệm nước tiểu'),
          subtitle: const Text('02/08/2024 • Đã có kết quả'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, AppRoutes.labDetail),
        ),
      ],
    ),
  );
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
  Widget build(BuildContext context) => const _FeaturePage(
    title: 'Chi tiết đơn thuốc',
    icon: Icons.medication,
    message: 'Hapacol 250mg • 1 gói/lần\nAugmentin 250mg • 5 ml, ngày 2 lần\nProspan • 2.5 ml, ngày 3 lần',
    actionText: 'Mở đơn thuốc đầy đủ',
    actionRoute: AppRoutes.prescription,
  );
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final items = store.notifications;
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: items.isEmpty
          ? const Center(child: Text('Bạn chưa có thông báo mới.'))
          : ListView(
              children: items
                  .map(
                    (item) => ListTile(
                      leading: Icon(
                        Icons.notifications_outlined,
                        color: item.read ? Colors.grey : _primary,
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: item.read
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(item.body),
                      onTap: () {
                        store.markNotificationRead(item.id);
                        Navigator.pushNamed(context, AppRoutes.myAppointments);
                      },
                    ),
                  )
                  .toList(),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(settings.tr('settings_title')),
      ),
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
            subtitle: Text(settings.locale == 'vi' ? 'Tiếng Việt 🇻🇳' : 'English 🇬🇧'),
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
            leading: const Icon(Icons.cleaning_services_outlined, color: Colors.orange),
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
          const Divider(),
          _sectionHeader('Quản trị & Bác sĩ'),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF0D6EFD)),
            title: const Text('Quản lý Slot khám (Admin)'),
            subtitle: const Text('Giới hạn lượt đặt phòng theo khung giờ'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, AppRoutes.adminSlots),
          ),
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
              child: const Text('Tắt mã PIN', style: TextStyle(color: Colors.red)),
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
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (_) => false,
          ),
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
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin.')),
      );
      return;
    }
    if (widget.title == 'Đăng nhập') {
      final ok = MedicalScope.of(
        context,
      ).login(identifier: _controllers[0].text, password: _controllers[1].text);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mật khẩu cần ít nhất 6 ký tự.')),
        );
        return;
      }
    }
    if (widget.title == 'Đăng ký tài khoản') {
      MedicalScope.of(context).register(
        name: _controllers[0].text.trim(),
        phone: _controllers[1].text.trim(),
        email: _controllers[2].text.trim(),
      );
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

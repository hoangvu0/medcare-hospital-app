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

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) => const _FormPage(
    title: 'Đăng nhập',
    fields: ['Số điện thoại hoặc email', 'Mật khẩu'],
    action: 'Đăng nhập',
    actionRoute: AppRoutes.home,
    secondary: 'Quên mật khẩu?',
    secondaryRoute: AppRoutes.forgotPassword,
    footer: 'Chưa có tài khoản? Đăng ký',
    footerRoute: AppRoutes.register,
  );
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
    final draft =
        ModalRoute.of(context)?.settings.arguments as AppointmentDraft?;
    if (draft == null) {
      return const Scaffold(
        body: Center(child: Text('Không tìm thấy thông tin lịch hẹn.')),
      );
    }
    final date =
        '${draft.dateTime.day.toString().padLeft(2, '0')}/${draft.dateTime.month.toString().padLeft(2, '0')}/${draft.dateTime.year}';
    final time =
        '${draft.dateTime.hour.toString().padLeft(2, '0')}:${draft.dateTime.minute.toString().padLeft(2, '0')}';
    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận đặt lịch')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.fact_check, size: 72, color: _primary),
          const SizedBox(height: 20),
          Text(
            draft.doctor.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _FeatureCard(
            title: 'Thông tin lịch hẹn',
            text:
                'Chuyên khoa: ${draft.doctor.specialty}\nNgày khám: $date\nKhung giờ: $time\nNgười khám: ${draft.patientName}\n${draft.doctor.location}\nTạm tính: ${(draft.useInsurance ? draft.doctor.price * .2 : draft.doctor.price).round()}đ',
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              final appointment = MedicalScope.of(context).book(
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
            icon: const Icon(Icons.check),
            label: const Text('Xác nhận đặt lịch'),
          ),
        ],
      ),
    );
  }
}

class BookingSuccessPage extends StatelessWidget {
  const BookingSuccessPage({super.key});
  @override
  Widget build(BuildContext context) {
    final appointment =
        ModalRoute.of(context)?.settings.arguments as Appointment?;
    return _FeaturePage(
      title: 'Đặt lịch thành công',
      icon: Icons.check_circle,
      message:
          'Mã lịch hẹn: ${appointment?.id ?? 'MED'}\nVui lòng đến trước giờ khám 15 phút.',
      actionText: 'Xem lịch hẹn',
      actionRoute: AppRoutes.myAppointments,
    );
  }
}

class MyAppointmentsPage extends StatelessWidget {
  const MyAppointmentsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final appointments = MedicalScope.of(context).appointments;
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch hẹn của tôi')),
      body: appointments.isEmpty
          ? const Center(child: Text('Bạn chưa có lịch hẹn nào.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: appointments.map((item) {
                final date =
                    '${item.dateTime.day.toString().padLeft(2, '0')}/${item.dateTime.month.toString().padLeft(2, '0')}/${item.dateTime.year} • ${item.dateTime.hour.toString().padLeft(2, '0')}:${item.dateTime.minute.toString().padLeft(2, '0')}';
                final status = switch (item.status) {
                  AppointmentStatus.confirmed => 'Đã xác nhận',
                  AppointmentStatus.completed => 'Hoàn thành',
                  AppointmentStatus.cancelled => 'Đã hủy',
                };
                return Card(
                  child: ListTile(
                    leading: Icon(
                      item.status == AppointmentStatus.cancelled
                          ? Icons.cancel_outlined
                          : Icons.calendar_month,
                      color: item.status == AppointmentStatus.cancelled
                          ? Colors.red
                          : _primary,
                    ),
                    title: Text('${item.doctorName} • $status'),
                    subtitle: Text('$date\n${item.location}'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.appointmentDetail,
                      arguments: item,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class AppointmentDetailPage extends StatelessWidget {
  const AppointmentDetailPage({super.key});
  @override
  Widget build(BuildContext context) {
    final item = ModalRoute.of(context)?.settings.arguments as Appointment?;
    if (item == null) {
      return const Scaffold(
        body: Center(child: Text('Không tìm thấy lịch hẹn.')),
      );
    }
    final date =
        '${item.dateTime.day.toString().padLeft(2, '0')}/${item.dateTime.month.toString().padLeft(2, '0')}/${item.dateTime.year} lúc ${item.dateTime.hour.toString().padLeft(2, '0')}:${item.dateTime.minute.toString().padLeft(2, '0')}';
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết lịch hẹn')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _FeatureCard(
            title: item.doctorName,
            text:
                '${item.specialty}\n$date\n${item.location}\nMã lịch hẹn: ${item.id}\nLý do khám: ${item.reason}',
          ),
          const SizedBox(height: 16),
          if (item.status == AppointmentStatus.completed)
            FilledButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.doctorRating),
              icon: const Icon(Icons.star_outline),
              label: const Text('Đánh giá sau khám'),
            ),
          if (item.status == AppointmentStatus.confirmed)
            OutlinedButton.icon(
              onPressed: () {
                MedicalScope.of(context).cancelAppointment(item.id);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Hủy lịch khám'),
            ),
        ],
      ),
    );
  }
}

class CancelAppointmentPage extends StatelessWidget {
  const CancelAppointmentPage({super.key});
  @override
  Widget build(BuildContext context) => const _FormPage(
    title: 'Hủy lịch khám',
    fields: ['Lý do hủy lịch'],
    action: 'Xác nhận hủy lịch',
    actionRoute: AppRoutes.myAppointments,
    secondary: 'Quay lại',
  );
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
    this.footer,
    this.footerRoute,
  });
  final String title;
  final List<String> fields;
  final String action;
  final String secondary;
  final String? actionRoute;
  final String? secondaryRoute;
  final String? footer;
  final String? footerRoute;
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
          if (widget.footer != null)
            TextButton(
              onPressed: widget.footerRoute == null
                  ? null
                  : () => Navigator.pushNamed(context, widget.footerRoute!),
              child: Text(widget.footer!),
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

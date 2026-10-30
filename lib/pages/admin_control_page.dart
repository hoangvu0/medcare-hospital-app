import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../state/medical_store.dart';

const _adminNavy = Color(0xFF0D2657);
const _adminGreen = Color(0xFF0F8A55);
const _adminRed = Color(0xFFBA1A1A);

class AdminControlPage extends StatefulWidget {
  const AdminControlPage({super.key});

  @override
  State<AdminControlPage> createState() => _AdminControlPageState();
}

class _AdminControlPageState extends State<AdminControlPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _loading = true;
  String? _error;
  Map<String, Object?> _overview = const {};
  List<Map<String, Object?>> _users = const [];
  List<Map<String, Object?>> _appointments = const [];
  List<Map<String, Object?>> _records = const [];
  List<Map<String, Object?>> _prescriptions = const [];
  List<Map<String, Object?>> _clinicalActions = const [];
  List<Map<String, Object?>> _auditLogs = const [];
  List<Map<String, Object?>> _doctors = const [];
  String _userRoleFilter = 'all';
  String _userSearch = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 7, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final store = MedicalScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await store.refreshBackendSessionOnline();
      final result = await Future.wait<Object?>([
        store.fetchAdminOverviewDataOnline(),
        store.fetchAdminUsersOnline(),
        store.fetchAdminAppointmentsOnline(),
        store.fetchAdminRecordsOnline(),
        store.fetchAdminPrescriptionsOnline(),
        store.fetchAdminClinicalActionsOnline(),
        store.fetchAdminAuditLogsOnline(),
        store.fetchAdminDoctorsOnline(),
      ]);
      if (!mounted) return;
      setState(() {
        _overview = Map<String, Object?>.from(result[0] as Map);
        _users = List<Map<String, Object?>>.from(result[1] as List);
        _appointments = List<Map<String, Object?>>.from(result[2] as List);
        _records = List<Map<String, Object?>>.from(result[3] as List);
        _prescriptions = List<Map<String, Object?>>.from(result[4] as List);
        _clinicalActions = List<Map<String, Object?>>.from(result[5] as List);
        _auditLogs = List<Map<String, Object?>>.from(result[6] as List);
        _doctors = List<Map<String, Object?>>.from(result[7] as List);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  Future<void> _toggleUser(Map<String, Object?> user) async {
    final id = user['id']?.toString() ?? '';
    final active = user['active'] == true;
    final identifier = user['identifier']?.toString() ?? id;
    if (identifier == MedicalScope.of(context).currentIdentifier) return;
    try {
      await MedicalScope.of(context)
          .updateAdminUserOnline(id: id, active: !active);
      if (!mounted) return;
      _message(!active ? 'Đã mở khóa tài khoản.' : 'Đã khóa tài khoản.');
      await _load();
    } catch (error) {
      if (mounted) _message('Không thể cập nhật tài khoản: $error');
    }
  }

  Future<void> _renameUser(Map<String, Object?> user) async {
    final controller = TextEditingController(
      text: user['displayName']?.toString() ?? '',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cập nhật tên hiển thị'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Tên hiển thị'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.length < 2 || !mounted) return;
    try {
      await MedicalScope.of(context).updateAdminUserOnline(
        id: user['id']?.toString() ?? '',
        displayName: name,
      );
      _message('Đã cập nhật tên tài khoản.');
      await _load();
    } catch (error) {
      if (mounted) _message('Không thể cập nhật tài khoản: $error');
    }
  }

  Future<void> _updateAppointment(
    Map<String, Object?> appointment,
    String status,
  ) async {
    final id = appointment['id']?.toString() ?? '';
    try {
      await MedicalScope.of(context)
          .updateAdminAppointmentOnline(id: id, status: status);
      if (!mounted) return;
      _message(
        status == 'cancelled' ? 'Đã hủy lịch hẹn.' : 'Đã cập nhật lịch hẹn.',
      );
      await _load();
    } catch (error) {
      if (mounted) _message('Không thể cập nhật lịch: $error');
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    if (!store.isAdminRole) {
      return Scaffold(
        appBar: AppBar(title: const Text('Không có quyền truy cập')),
        body: const Center(child: Text('Chỉ tài khoản admin được truy cập.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _adminNavy,
        foregroundColor: Colors.white,
        title: const Text('Điều hành tài khoản & lịch hẹn'),
        actions: [
          IconButton(
            tooltip: 'Tải lại dữ liệu',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            const Tab(icon: Icon(Icons.dashboard_outlined), text: 'Tổng quan'),
            Tab(
              icon: const Icon(Icons.people_outline),
              text: 'Tài khoản (${_users.length})',
            ),
            Tab(
              icon: const Icon(Icons.event_note_outlined),
              text: 'Lịch hẹn (${_appointments.length})',
            ),
            Tab(
              icon: const Icon(Icons.folder_shared_outlined),
              text: 'Lâm sàng (${_records.length})',
            ),
            Tab(
              icon: const Icon(Icons.security_outlined),
              text: 'Audit (${_auditLogs.length})',
            ),
            const Tab(icon: Icon(Icons.apps_outlined), text: 'Điều hành'),
            Tab(
              icon: const Icon(Icons.medical_services_outlined),
              text: 'Bác sĩ (${_doctors.length})',
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _errorView()
          : TabBarView(
              controller: _tabs,
              children: [
                _overviewView(),
                _usersView(),
                _appointmentsView(),
                _clinicalView(),
                _auditView(),
                _operationsView(),
                _doctorsView(),
              ],
            ),
    );
  }

  int _number(String key) => (_overview[key] as num?)?.toInt() ?? 0;

  Widget _overviewView() {
    final cards = [
      (
        'Bệnh nhân hôm nay',
        _number('todayPatients'),
        Icons.people_alt_outlined,
        Colors.blue,
      ),
      (
        'Doanh thu đã thu',
        _number('todayRevenue'),
        Icons.payments_outlined,
        Colors.green,
      ),
      (
        'Ca đã hoàn tất',
        _number('completedConsultations'),
        Icons.task_alt_outlined,
        Colors.orange,
      ),
      (
        'Đơn thuốc',
        _number('totalPrescriptions'),
        Icons.medication_outlined,
        Colors.purple,
      ),
      (
        'Bệnh án',
        _number('totalMedicalRecords'),
        Icons.folder_shared_outlined,
        Colors.teal,
      ),
      (
        'Thao tác lâm sàng',
        _number('totalClinicalActions'),
        Icons.timeline_outlined,
        Colors.indigo,
      ),
    ];
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Trung tâm điều hành MedCare',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Số liệu được đọc trực tiếp từ backend, cập nhật bằng nút tải lại.',
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cards.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              mainAxisExtent: 104,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (_, index) {
              final card = cards[index];
              final value = card.$1.contains('Doanh thu')
                  ? '${card.$2.toString().replaceAllMapped(RegExp(r'(?=(\\d{3})+(?!\\d))'), (_) => '.')}đ'
                  : '${card.$2}';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: card.$4.withValues(alpha: .12),
                        child: Icon(card.$3, color: card.$4),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(card.$1, style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              value,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Card(
            color: (_overview['emergencyLockdown'] == true)
                ? Colors.red.shade50
                : Colors.green.shade50,
            child: ListTile(
              leading: Icon(
                (_overview['emergencyLockdown'] == true)
                    ? Icons.lock
                    : Icons.verified_user_outlined,
              ),
              title: Text(
                (_overview['emergencyLockdown'] == true)
                    ? 'Hệ thống đang khóa khẩn cấp'
                    : 'Hệ thống đang hoạt động bình thường',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('Audit log: ${_number('totalAuditLogs')} bản ghi'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _clinicalView() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(
            'Bệnh án điện tử',
            _records.length,
            Icons.folder_shared_outlined,
          ),
          if (_records.isEmpty) _empty('Chưa có bệnh án trên backend.'),
          ..._records
              .take(30)
              .map((item) => _clinicalCard(item, Icons.description_outlined)),
          const SizedBox(height: 14),
          _sectionHeader(
            'Đơn thuốc đã ký',
            _prescriptions.length,
            Icons.medication_outlined,
          ),
          if (_prescriptions.isEmpty) _empty('Chưa có đơn thuốc trên backend.'),
          ..._prescriptions.take(30).map((item) => _prescriptionCard(item)),
          const SizedBox(height: 14),
          _sectionHeader(
            'Thao tác lâm sàng',
            _clinicalActions.length,
            Icons.timeline_outlined,
          ),
          if (_clinicalActions.isEmpty)
            _empty('Chưa có thao tác lâm sàng trên backend.'),
          ..._clinicalActions
              .take(30)
              .map(
                (item) =>
                    _clinicalCard(item, Icons.medical_information_outlined),
              ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, int count, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, color: _adminNavy),
        const SizedBox(width: 8),
        Text(
          '$title ($count)',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );

  Widget _clinicalCard(Map<String, Object?> item, IconData icon) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Icon(icon, color: _adminNavy),
      title: Text(
        item['diagnosis']?.toString() ??
            item['action']?.toString() ??
            'Bản ghi lâm sàng',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        'BN: ${item['patientId'] ?? 'Không rõ'} • ${item['createdAt'] ?? ''}',
      ),
      trailing: Text(item['status']?.toString() ?? 'completed'),
    ),
  );

  Widget _prescriptionCard(Map<String, Object?> item) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: const Icon(Icons.medication_outlined, color: _adminNavy),
      title: Text(item['diagnosis']?.toString() ?? 'Đơn thuốc'),
      subtitle: Text(
        'BN: ${item['patientId'] ?? 'Không rõ'} • BS: ${item['doctorId'] ?? 'Không rõ'}',
      ),
      trailing: const Icon(Icons.verified_outlined, color: _adminGreen),
    ),
  );

  Widget _auditView() {
    if (_auditLogs.isEmpty) return _empty('Chưa có audit log trên backend.');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _auditLogs.length,
        itemBuilder: (_, index) {
          final log = _auditLogs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.history, color: _adminNavy),
              title: Text(log['action']?.toString() ?? 'AUDIT'),
              subtitle: Text(
                '${log['resource'] ?? ''}\n${log['details'] ?? ''}\n${log['created_at'] ?? ''}',
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }

  Widget _doctorsView() => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _sectionHeader(
                'Danh mục bác sĩ',
                _doctors.length,
                Icons.medical_services_outlined,
              ),
            ),
            FilledButton.icon(
              onPressed: () => _editDoctor(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm'),
            ),
          ],
        ),
        const Text(
          'Dữ liệu được lưu trên backend. Tắt bác sĩ sẽ ẩn khỏi danh sách bệnh nhân nhưng không xóa lịch sử khám.',
        ),
        const SizedBox(height: 12),
        if (_doctors.isEmpty) _empty('Chưa có bác sĩ trên backend.'),
        ..._doctors.map(_doctorCard),
      ],
    ),
  );

  Widget _doctorCard(Map<String, Object?> doctor) {
    final active = doctor['active'] == true;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _adminNavy.withValues(alpha: .1),
          child: const Icon(Icons.medical_services_outlined, color: _adminNavy),
        ),
        title: Text(
          doctor['name']?.toString() ?? 'Bác sĩ',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${doctor['specialty'] ?? 'Chưa phân khoa'} • ${doctor['location'] ?? 'Chưa có phòng'}\n'
          'Phí khám: ${doctor['price'] ?? 0}đ • ${active ? 'Đang nhận lịch' : 'Đang khóa'}',
        ),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              tooltip: 'Sửa hồ sơ bác sĩ',
              onPressed: () => _editDoctor(doctor: doctor),
              icon: const Icon(Icons.edit_outlined),
            ),
            Switch(
              value: active,
              activeThumbColor: _adminGreen,
              onChanged: (_) => _toggleDoctor(doctor),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleDoctor(Map<String, Object?> doctor) async {
    try {
      await MedicalScope.of(context).updateAdminDoctorOnline(
        id: doctor['id']?.toString() ?? '',
        patch: {'active': doctor['active'] != true},
      );
      _message(
        doctor['active'] == true ? 'Đã khóa bác sĩ.' : 'Đã mở nhận lịch.',
      );
      await _load();
    } catch (error) {
      if (mounted) _message('Không thể cập nhật bác sĩ: $error');
    }
  }

  Future<void> _editDoctor({Map<String, Object?>? doctor}) async {
    final name = TextEditingController(text: doctor?['name']?.toString() ?? '');
    final specialty = TextEditingController(
      text: doctor?['specialty']?.toString() ?? '',
    );
    final experience = TextEditingController(
      text: doctor?['experience']?.toString() ?? '',
    );
    final location = TextEditingController(
      text: doctor?['location']?.toString() ?? '',
    );
    final price = TextEditingController(
      text: doctor?['price']?.toString() ?? '0',
    );
    final values = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(doctor == null ? 'Thêm bác sĩ' : 'Sửa hồ sơ bác sĩ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _doctorField(name, 'Họ tên bác sĩ'),
              _doctorField(specialty, 'Chuyên khoa'),
              _doctorField(experience, 'Kinh nghiệm'),
              _doctorField(location, 'Phòng khám'),
              _doctorField(
                price,
                'Phí khám',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, {
              'name': name.text.trim(),
              'specialty': specialty.text.trim(),
              'experience': experience.text.trim(),
              'location': location.text.trim(),
              'price': int.tryParse(price.text.trim()) ?? 0,
            }),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    name.dispose();
    specialty.dispose();
    experience.dispose();
    location.dispose();
    price.dispose();
    if (values == null ||
        values['name'].toString().isEmpty ||
        values['specialty'].toString().isEmpty ||
        !mounted) {
      return;
    }
    try {
      if (doctor == null) {
        await MedicalScope.of(context).createAdminDoctorOnline(values);
        _message('Đã thêm bác sĩ vào danh mục.');
      } else {
        await MedicalScope.of(context).updateAdminDoctorOnline(
          id: doctor['id']?.toString() ?? '',
          patch: values,
        );
        _message('Đã cập nhật hồ sơ bác sĩ.');
      }
      await _load();
    } catch (error) {
      if (mounted) _message('Không thể lưu hồ sơ bác sĩ: $error');
    }
  }

  Widget _doctorField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );

  Widget _operationsView() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _operationTile(
        'Quản lý Slot khám',
        'Mở ca, tăng giảm số chỗ, xem tải bác sĩ',
        Icons.calendar_month_outlined,
        AppRoutes.adminSlots,
      ),
      _operationTile(
        'Duyệt thanh toán & bảo lãnh',
        'Xác nhận tiền nạp, thanh toán và bảo lãnh viện phí',
        Icons.verified_outlined,
        AppRoutes.adminApprovals,
      ),
      _operationTile(
        'Đăng ký gói khám & tiêm chủng',
        'Tiếp nhận yêu cầu tầm soát, tiêm chủng và phản hồi cho bệnh nhân',
        Icons.vaccines_outlined,
        AppRoutes.support,
      ),
      _operationTile(
        'Bác sĩ & bệnh nhân',
        'Khóa/mở tài khoản, xem lịch hẹn và tình trạng sử dụng',
        Icons.manage_accounts_outlined,
        null,
      ),
      _operationTile(
        'Kiểm tra hệ thống',
        'Xem audit, bệnh án, đơn thuốc và thao tác lâm sàng',
        Icons.security_outlined,
        null,
      ),
    ],
  );

  Widget _operationTile(
    String title,
    String subtitle,
    IconData icon,
    String? route,
  ) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: _adminNavy.withValues(alpha: .1),
        child: Icon(icon, color: _adminNavy),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: route == null
          ? const Icon(Icons.check_circle_outline, color: _adminGreen)
          : const Icon(Icons.chevron_right),
      onTap: route == null ? null : () => Navigator.pushNamed(context, route),
    ),
  );

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    ),
  );

  Widget _usersView() {
    if (_users.isEmpty) return _empty('Chưa có tài khoản trên backend.');
    final query = _userSearch.trim().toLowerCase();
    final users = _users
        .where((user) {
          final role = user['role']?.toString() ?? 'patient';
          final haystack =
              '${user['displayName']} ${user['identifier']} ${user['phone']}'
                  .toLowerCase();
          return (_userRoleFilter == 'all' || role == _userRoleFilter) &&
              (query.isEmpty || haystack.contains(query));
        })
        .toList(growable: false);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Tìm bệnh nhân, bác sĩ, admin',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _userSearch = value),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _roleChip('all', 'Tất cả'),
              _roleChip('patient', 'Bệnh nhân'),
              _roleChip('doctor', 'Bác sĩ'),
              _roleChip('admin', 'Admin'),
            ],
          ),
          const SizedBox(height: 12),
          if (users.isEmpty) _empty('Không tìm thấy tài khoản phù hợp.'),
          ...users.map(_userCard),
        ],
      ),
    );
  }

  Widget _roleChip(String value, String label) => ChoiceChip(
    label: Text(label),
    selected: _userRoleFilter == value,
    onSelected: (_) => setState(() => _userRoleFilter = value),
  );

  Widget _appointmentsView() {
    if (_appointments.isEmpty) return _empty('Chưa có lịch hẹn trên backend.');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _appointments.length,
        itemBuilder: (_, index) => _appointmentCard(_appointments[index]),
      ),
    );
  }

  Widget _userCard(Map<String, Object?> user) {
    final role = user['role']?.toString() ?? 'patient';
    final active = user['active'] == true;
    final roleLabel = switch (role) {
      'admin' => 'Quản trị viên',
      'doctor' => 'Bác sĩ',
      _ => 'Bệnh nhân',
    };
    final roleColor = role == 'admin'
        ? _adminNavy
        : role == 'doctor'
        ? Colors.teal
        : Colors.indigo;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: roleColor.withValues(alpha: .12),
          child: Icon(
            role == 'doctor'
                ? Icons.medical_services_outlined
                : role == 'admin'
                ? Icons.admin_panel_settings_outlined
                : Icons.person_outline,
            color: roleColor,
          ),
        ),
        title: Text(
          user['displayName']?.toString() ?? 'Chưa có tên',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '$roleLabel • ${user['identifier']}\n${user['phone'] ?? 'Chưa có số điện thoại'}',
        ),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              tooltip: 'Đổi tên',
              onPressed: () => _renameUser(user),
              icon: const Icon(Icons.edit_outlined),
            ),
            Switch(
              value: active,
              onChanged:
                  role == 'admin' ||
                      user['identifier'] ==
                          MedicalScope.of(context).currentIdentifier
                  ? null
                  : (_) => _toggleUser(user),
              activeThumbColor: _adminGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _appointmentCard(Map<String, Object?> appointment) {
    final status = appointment['status']?.toString() ?? 'confirmed';
    final date =
        appointment['appointmentTime']?.toString() ?? 'Chưa có thời gian';
    final canAct = status != 'cancelled' && status != 'completed';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_note_outlined, color: _adminNavy),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appointment['doctorName']?.toString() ?? 'Bác sĩ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                _status(status),
              ],
            ),
            const SizedBox(height: 8),
            Text('Bệnh nhân: ${appointment['patientId'] ?? 'Chưa cập nhật'}'),
            Text('Thời gian: $date'),
            Text('Chuyên khoa: ${appointment['specialty'] ?? 'Chưa cập nhật'}'),
            if (canAct) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => _updateAppointment(appointment, 'cancelled'),
                  icon: const Icon(Icons.event_busy),
                  label: const Text('Hủy lịch'),
                  style: OutlinedButton.styleFrom(foregroundColor: _adminRed),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _status(String value) {
    final color = value == 'cancelled' ? _adminRed : _adminGreen;
    return Chip(
      label: Text(value),
      labelStyle: TextStyle(color: color, fontSize: 11),
      backgroundColor: color.withValues(alpha: .1),
    );
  }

  Widget _empty(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}

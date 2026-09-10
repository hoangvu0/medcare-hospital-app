import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../routes/app_routes.dart';
import '../state/medical_store.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});
  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  int _selectedDate = 0;
  String _selectedTime = '09:00';
  bool _isSelf = true;
  bool _useInsurance = false;
  final _reasonController = TextEditingController();
  static const _times = ['08:00', '09:00', '10:00', '14:00', '15:00', '16:00'];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final doctor = _doctorFromArguments(context, store);
    final dates = List.generate(
      7,
      (index) => DateTime.now().add(Duration(days: index + 1)),
    );
    final date = dates[_selectedDate];
    return Scaffold(
      appBar: AppBar(title: const Text('Đặt lịch khám')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _DoctorSummary(doctor: doctor),
          const SizedBox(height: 16),
          _CardSection(
            title: 'Chọn ngày khám',
            child: SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: dates.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final item = dates[index];
                  final selected = _selectedDate == index;
                  return ChoiceChip(
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedDate = index),
                    label: SizedBox(
                      width: 52,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_weekday(item)),
                          Text(
                            '${item.day}/${item.month}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          _CardSection(
            title: 'Khung giờ tiếp nhận',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _times
                  .map(
                    (time) => ChoiceChip(
                      label: Text(time),
                      selected: _selectedTime == time,
                      onSelected: (_) => setState(() => _selectedTime = time),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          _CardSection(
            title: 'Thông tin người khám',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('Bản thân'),
                      icon: Icon(Icons.person),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('Người thân'),
                      icon: Icon(Icons.people),
                    ),
                  ],
                  selected: {_isSelf},
                  onSelectionChanged: (value) =>
                      setState(() => _isSelf = value.first),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSelf
                      ? store.profile.name
                      : 'Người thân (cần bổ sung hồ sơ)',
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _useInsurance,
                  onChanged: (value) => setState(() => _useInsurance = value),
                  title: const Text('Áp dụng BHYT'),
                  subtitle: const Text(
                    'Mức tạm tính sẽ được xác nhận tại cơ sở khám.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CardSection(
            title: 'Lý do khám',
            child: TextField(
              controller: _reasonController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Mô tả triệu chứng hoặc nhu cầu khám.',
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _continueBooking(doctor, date),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Xem lại lịch hẹn'),
          ),
        ],
      ),
    );
  }

  DoctorProfile _doctorFromArguments(BuildContext context, MedicalStore store) {
    final argument = ModalRoute.of(context)?.settings.arguments;
    return argument is DoctorProfile ? argument : store.doctors[1];
  }

  void _continueBooking(DoctorProfile doctor, DateTime date) {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập lý do khám.')),
      );
      return;
    }
    final parts = _selectedTime.split(':');
    final draft = AppointmentDraft(
      doctor: doctor,
      dateTime: DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      ),
      patientName: _isSelf
          ? MedicalScope.of(context).profile.name
          : 'Người thân',
      reason: reason,
      useInsurance: _useInsurance,
    );
    Navigator.pushNamed(
      context,
      AppRoutes.confirmAppointment,
      arguments: draft,
    );
  }

  String _weekday(DateTime value) =>
      const ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'][value.weekday % 7];
}

class _DoctorSummary extends StatelessWidget {
  const _DoctorSummary({required this.doctor});
  final DoctorProfile doctor;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(doctor.name),
      subtitle: Text('${doctor.specialty}\n${doctor.location}'),
      isThreeLine: true,
      trailing: Text(
        '${doctor.price ~/ 1000}.000đ',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  );
}

class _CardSection extends StatelessWidget {
  const _CardSection({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

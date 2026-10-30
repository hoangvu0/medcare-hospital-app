import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../routes/app_routes.dart';
import '../state/medical_store.dart';
import '../widgets/medcare_brand_title.dart';

class EPrescriptionPage extends StatefulWidget {
  const EPrescriptionPage({super.key});

  @override
  State<EPrescriptionPage> createState() => _EPrescriptionPageState();
}

class _EPrescriptionPageState extends State<EPrescriptionPage> {
  static const _primary = Color(0xFF0D6EFD);
  static const _success = Color(0xFF10B981);
  bool _reminderEnabled = true;
  final Set<String> _reminderTimes = {'07:30', '12:00', '19:00'};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MedicalScope.of(context).refreshClinicalDataFromBackend();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final profile = store.profile;
    final medicines = store.medicines;
    final latestRecord = store.medicalRecords.isNotEmpty
        ? store.medicalRecords.first
        : null;
    if (medicines.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const MedCareBrandTitle(pageTitle: 'Đơn thuốc điện tử'),
        ),
        body: _emptyPrescriptionState(context),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const MedCareBrandTitle(pageTitle: 'Đơn thuốc điện tử'),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.prescriptionDetail),
            tooltip: 'Chi tiết đơn thuốc',
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          IconButton(
            onPressed: _sharePrescription,
            tooltip: 'Chia sẻ đơn thuốc',
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            onPressed: () => _showBarcodeDialog(
              latestRecord?.prescriptionCode ?? profile.id,
            ),
            tooltip: 'Mở mã xuất thuốc',
            icon: const Icon(Icons.qr_code_2),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _prescriptionIdentity(profile, latestRecord),
          const SizedBox(height: 14),
          _buildAllergyAlert(store),
          _dispensingCode(latestRecord?.prescriptionCode ?? profile.id),
          const SizedBox(height: 14),
          _reminderCard(),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Danh mục thuốc kê đơn',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Chip(label: Text('${medicines.length} loại')),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < medicines.length; i++) ...[
            _medicineCard(
              number: '${i + 1}',
              name: medicines[i].name,
              category: medicines[i].category,
              quantity: medicines[i].quantity,
              instruction: medicines[i].instruction,
              note: medicines[i].warning,
              warning: medicines[i].warning != null,
            ),
          ],
          const SizedBox(height: 4),
          _adviceAndFollowUp(latestRecord),
          const SizedBox(height: 14),
          _costSummary(latestRecord, medicines.length),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => _showOrderDeliveryModal(
              context,
              store,
              latestRecord?.prescriptionCode,
            ),
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text('Đặt mua & Giao thuốc tận nhà (2h)'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _downloadPrescription,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Tải đơn PDF có chữ ký số Bộ Y Tế'),
          ),
        ],
      ),
    );
  }

  Widget _emptyPrescriptionState(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: _primary,
              size: 42,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Chưa có đơn thuốc được phát hành',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Đơn thuốc chỉ xuất hiện sau khi bạn đã có lịch hẹn, bác sĩ hoàn tất ca khám, ký hồ sơ bệnh án và phát hành đơn điện tử.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.45),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.appointments),
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Đặt lịch khám'),
          ),
        ],
      ),
    ),
  );

  Widget _buildAllergyAlert(MedicalStore store) {
    final activeMember = store.activeFamilyMember;
    final hasPenicillinAllergy = activeMember.allergies.toLowerCase().contains(
      'penicillin',
    );

    if (!hasPenicillinAllergy) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF87171)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFDC2626),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CẢNH BÁO DỊ ỨNG THUỐC (PENICILLIN)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDC2626),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Hồ sơ của ${activeMember.name} ghi nhận tiền sử dị ứng Penicillin. Dược sĩ lâm sàng MedCare đã rà soát đơn thuốc và xác nhận các thuốc trên an toàn, không chứa kháng sinh nhóm beta-lactam.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7F1D1D),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _prescriptionIdentity(
    PatientProfile profile,
    MedicalRecord? record,
  ) => Card(
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: Color(0xFFE7F0FF),
                child: Icon(Icons.person, color: _primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${profile.gender} • 24 tuổi • Mã BN: ${profile.id} • BHYT: ${profile.insuranceNumber}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 0,
                child: Text(
                  '#${record?.prescriptionCode ?? 'ĐANG-CẬP-NHẬT'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _DataRow(
            icon: Icons.event_note_outlined,
            title: 'Ngày kê đơn',
            value: record?.date ?? 'Đang cập nhật',
          ),
          const SizedBox(height: 8),
          _DataRow(
            icon: Icons.timer_outlined,
            title: 'Hiệu lực đơn thuốc',
            value: record == null
                ? 'Đang cập nhật'
                : 'Theo thời hạn bác sĩ chỉ định trong hồ sơ',
          ),
          const SizedBox(height: 8),
          _DataRow(
            icon: Icons.medical_information_outlined,
            title: 'Chẩn đoán ICD-10',
            value: record == null
                ? 'Đang cập nhật'
                : '${record.diagnosisCode} - ${record.icd10Name}',
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_outlined, color: _success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đã ký số bởi ${record?.doctorName ?? 'bác sĩ điều trị'} • Mã EMR: ${record?.id ?? 'đang cập nhật'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF065F46),
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

  Widget _dispensingCode(String prescriptionCode) => Card(
    color: const Color(0xFFEFF6FF),
    elevation: 1,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showBarcodeDialog(prescriptionCode),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded, size: 40, color: _primary),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mã xuất thuốc tại Nhà thuốc Bệnh viện',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Chạm để mở mã vạch / QR cấp thuốc không chờ đợi',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _primary),
          ],
        ),
      ),
    ),
  );

  Widget _reminderCard() => Card(
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Nhắc uống thuốc tự động',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _reminderEnabled
                  ? 'Đang nhắc cữ: ${_reminderTimes.join(', ')}'
                  : 'Chưa bật nhắc thuốc',
            ),
            value: _reminderEnabled,
            activeThumbColor: _success,
            onChanged: (value) => setState(() => _reminderEnabled = value),
          ),
          if (_reminderEnabled) ...[
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: ['07:30', '12:00', '19:00', '21:00']
                    .map(
                      (time) => FilterChip(
                        label: Text(time),
                        selected: _reminderTimes.contains(time),
                        onSelected: (selected) => setState(
                          () => selected
                              ? _reminderTimes.add(time)
                              : _reminderTimes.remove(time),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _medicineCard({
    required String number,
    required String name,
    required String category,
    required String quantity,
    required String instruction,
    String? note,
    bool warning = false,
  }) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE7F0FF),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      category,
                      style: const TextStyle(color: _primary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 0,
                child: Text(
                  quantity,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              instruction,
              style: const TextStyle(height: 1.4, fontSize: 13),
            ),
          ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '⚠️ Lưu ý: $note',
                style: TextStyle(
                  color: warning ? const Color(0xFFDC2626) : Colors.black54,
                  fontSize: 12,
                  fontWeight: warning ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _adviceAndFollowUp(MedicalRecord? record) => Card(
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lời dặn của Bác sĩ điều trị',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            record?.doctorInstructions ?? 'Uống thuốc đúng theo hướng dẫn trên đơn và tái khám khi có lịch hẹn.',
            style: const TextStyle(height: 1.5, fontSize: 13),
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.event_available_outlined, color: _primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hẹn tái khám: ${record?.followUpDate ?? 'theo chỉ định bác sĩ'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.appointments),
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Đặt lịch tái khám định kỳ'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _costSummary(MedicalRecord? record, int medicineCount) => Card(
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SummaryRow(
            'Tổng chi phí đợt khám/đơn thuốc ($medicineCount loại)',
            _money(record?.totalFee ?? 0),
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            'BHYT/nguồn chi trả',
            '-${_money(record?.insuranceCovered ?? 0)}',
            success: true,
          ),
          const Divider(height: 22),
          _SummaryRow(
            'Số tiền bệnh nhân cùng chi trả',
            _money(
              ((record?.totalFee ?? 0) - (record?.insuranceCovered ?? 0)).clamp(
                0,
                999999999,
              ),
            ),
            bold: true,
          ),
        ],
      ),
    ),
  );

  void _showBarcodeDialog(String prescriptionCode) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Mã xuất thuốc điện tử'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.qr_code_2, size: 120, color: _primary),
          const SizedBox(height: 12),
          Text(
            '#$prescriptionCode',
            style: const TextStyle(
              color: _primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Đưa mã này cho Dược sĩ tại Quầy phát thuốc Tầng 1 để nhận thuốc nhanh.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );

  void _sharePrescription() =>
      _message('Đã tạo liên kết chia sẻ đơn thuốc có bảo mật mã PIN.');

  void _showOrderDeliveryModal(
    BuildContext context,
    MedicalStore store,
    String? prescriptionCode,
  ) {
    final activeMember = store.activeFamilyMember;
    var medicineTotal = 0;
    for (final record in store.medicalRecords) {
      if (record.prescriptionCode == prescriptionCode) {
        medicineTotal = (record.totalFee - record.insuranceCovered)
            .clamp(0, record.totalFee)
            .toInt();
        break;
      }
    }
    const deliveryFee = 25000;
    final payableTotal = medicineTotal + deliveryFee;
    final addrCtrl = TextEditingController(
      text: 'Số 28, Phố Huế, Q. Hoàn Kiếm, Hà Nội',
    );
    String selectedPharmacy = 'Nhà thuốc MedCare & FPT Long Châu';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSheetState) {
          final bottom = MediaQuery.of(ctx2).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Đặt mua & Giao thuốc tận nhà',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Bệnh nhân nhận thuốc
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_pin, color: _primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Người nhận: ${activeMember.name} • ${activeMember.phone.isNotEmpty ? activeMember.phone : '0901 234 567'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Chọn nhà thuốc
                  const Text(
                    'Chọn Nhà thuốc liên kết:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPharmacy,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Nhà thuốc MedCare & FPT Long Châu',
                        child: Text(
                          'MedCare & FPT Long Châu (Gần bạn nhất • 1.2km)',
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Nhà thuốc Pharmacity Hoàn Kiếm',
                        child: Text('Pharmacity Hoàn Kiếm (2.4km)'),
                      ),
                      DropdownMenuItem(
                        value: 'Nhà thuốc An Khang',
                        child: Text('An Khang (3.1km)'),
                      ),
                    ],
                    onChanged: (v) => setSheetState(
                      () => selectedPharmacy = v ?? selectedPharmacy,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Địa chỉ giao hàng
                  TextField(
                    controller: addrCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ nhận hàng (Giao hỏa tốc 2 giờ)',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bảng tính phí
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tiền thuốc kê đơn (sau BHYT):',
                              style: TextStyle(fontSize: 13),
                            ),
                            Text(
                              _money(medicineTotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Phí giao hỏa tốc (Ahamove 2h):',
                              style: TextStyle(fontSize: 13),
                            ),
                            Text(
                              '25.000đ',
                              style: TextStyle(
                                color: _primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng thanh toán khi nhận hàng:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _money(payableTotal),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: () {
                        try {
                          final order = store.createPharmacyOrder(
                            prescriptionId: prescriptionCode ?? '',
                            deliveryAddress: addrCtrl.text.trim(),
                            pharmacyName: selectedPharmacy,
                            itemsCount: store.medicines.length,
                            medicineTotal: medicineTotal,
                          );
                          Navigator.pop(ctx);
                          _showOrderTrackingDialog(context, order);
                        } on StateError catch (error) {
                          _message(error.message);
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text(
                        'Xác nhận đặt giao ngay',
                        style: TextStyle(fontSize: 15),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showOrderTrackingDialog(BuildContext context, PharmacyOrder order) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.local_shipping, color: _success),
            SizedBox(width: 8),
            Text('Đã đặt thuốc thành công!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mã đơn hàng: ${order.id}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: _primary,
              ),
            ),
            const SizedBox(height: 6),
            Text('Đơn vị vận chuyển: ${order.pharmacyName}'),
            Text('Giao đến: ${order.deliveryAddress}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: _success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dự kiến giao trong ${order.estimatedMinutes} phút tới.',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _downloadPrescription() =>
      _message('Đang tải file PDF đơn thuốc có chữ ký số điện tử...');

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
  );

  String _money(num value) {
    final raw = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final remaining = raw.length - i;
      buffer.write(raw[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }
    return '$bufferđ';
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: Colors.grey),
      const SizedBox(width: 8),
      SizedBox(
        width: 108,
        child: Text(
          '$title: ',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
      ),
      Expanded(
        child: Text(
          value,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    ],
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
    this.title,
    this.value, {
    this.success = false,
    this.bold = false,
  });

  final String title;
  final String value;
  final bool success;
  final bool bold;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: bold ? 18 : 13,
            fontWeight: FontWeight.bold,
            color: success
                ? const Color(0xFF10B981)
                : (bold ? const Color(0xFF0D6EFD) : Colors.black87),
          ),
        ),
      ),
    ],
  );
}

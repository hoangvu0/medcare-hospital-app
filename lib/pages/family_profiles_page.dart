import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../state/medical_store.dart';

const _kPrimary = Color(0xFF0057CD);
const _kSuccess = Color(0xFF10B981);
const _kWarning = Color(0xFFF59E0B);
const _kDanger = Color(0xFFEF4444);

/// Trang Quản lý Đa Hồ sơ Gia đình (Family Profiles Management).
/// Bệnh nhân có thể thêm con cái, bố mẹ già, vợ/chồng với mã BHYT và tiền sử bệnh lý riêng.
class FamilyProfilesPage extends StatefulWidget {
  const FamilyProfilesPage({super.key});

  @override
  State<FamilyProfilesPage> createState() => _FamilyProfilesPageState();
}

class _FamilyProfilesPageState extends State<FamilyProfilesPage> {
  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final members = store.familyMembers;
    final activeMember = store.activeFamilyMember;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hồ sơ Sức khỏe Gia đình',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Quản lý hồ sơ y tế & BHYT từng thành viên',
                style: TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Hướng dẫn liên thông hồ sơ',
            onPressed: () => _showGuide(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMemberModal(context, store),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Thêm người thân'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        children: [
          // Banner giải thích
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kPrimary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.family_restroom_rounded,
                    color: _kPrimary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đang chọn khám cho:',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                      Text(
                        '${activeMember.name} (${activeMember.relationLabel})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _kPrimary,
                        ),
                      ),
                      const Text(
                        'Lịch hẹn, đơn thuốc và thanh toán BHYT sẽ áp dụng cho hồ sơ này.',
                        style: TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DANH SÁCH THÀNH VIÊN (${members.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const Text(
                'Bấm vào thẻ để chọn',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ...members.map((m) {
            final isActive = m.id == activeMember.id;
            return _FamilyMemberCard(
              member: m,
              isActive: isActive,
              onSelect: () => store.switchFamilyProfile(m.id),
              onDelete: m.id == 'fam-01'
                  ? null
                  : () => _confirmDelete(context, store, m),
            );
          }),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, MedicalStore store, FamilyMemberProfile member) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa hồ sơ người thân?'),
        content: Text(
          'Bạn có chắc muốn xóa hồ sơ của "${member.name}" (${member.relationLabel}) khỏi tài khoản?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              store.deleteFamilyMember(member.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã xóa hồ sơ ${member.name}.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: _kDanger),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showAddMemberModal(BuildContext context, MedicalStore store) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddFamilyMemberSheet(store: store),
    );
  }

  void _showGuide(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hồ sơ sức khỏe gia đình',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              '• Mỗi tài khoản có thể liên kết tối đa 10 hồ sơ người thân (con cái, cha mẹ già, vợ/chồng).\n'
              '• Khi chuyển đổi hồ sơ, ứng dụng sẽ tự động áp dụng đúng thẻ BHYT, nhóm máu và tiền sử dị ứng khi đặt lịch hoặc mua thuốc.\n'
              '• Mọi kết quả xét nghiệm và lịch sử khám sẽ được lưu riêng biệt theo từng người.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đã hiểu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Thẻ hiển thị từng thành viên ───────────────────────────────────────────

class _FamilyMemberCard extends StatelessWidget {
  const _FamilyMemberCard({
    required this.member,
    required this.isActive,
    required this.onSelect,
    this.onDelete,
  });

  final FamilyMemberProfile member;
  final bool isActive;
  final VoidCallback onSelect;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? _kPrimary : Colors.grey.shade200,
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? _kPrimary.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isActive
                          ? _kPrimary.withValues(alpha: 0.12)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      member.avatarEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              member.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: _kPrimary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                member.relationLabel,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: _kPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Sinh: ${member.dateOfBirth} • Giới tính: ${member.gender} • Nhóm máu: ${member.bloodType}',
                          style: TextStyle(
                              fontSize: 11.5, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kSuccess.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: _kSuccess, size: 14),
                          SizedBox(width: 4),
                          Text('Đang chọn',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _kSuccess)),
                        ],
                      ),
                    )
                  else if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.grey, size: 20),
                      onPressed: onDelete,
                    ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined,
                          size: 14, color: _kSuccess),
                      const SizedBox(width: 5),
                      Text(
                        'BHYT: ${member.insuranceNumber}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 14, color: _kWarning),
                      const SizedBox(width: 4),
                      Text(
                        'Dị ứng: ${member.allergies}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: member.allergies == 'Không có'
                              ? Colors.grey.shade600
                              : _kDanger,
                          fontWeight: member.allergies == 'Không có'
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (member.medicalNotes.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Ghi chú: ${member.medicalNotes}',
                  style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade500),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Form thêm người thân mới ────────────────────────────────────────────────

class _AddFamilyMemberSheet extends StatefulWidget {
  const _AddFamilyMemberSheet({required this.store});
  final MedicalStore store;

  @override
  State<_AddFamilyMemberSheet> createState() => _AddFamilyMemberSheetState();
}

class _AddFamilyMemberSheetState extends State<_AddFamilyMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController(text: '01/01/2015');
  final _insuranceCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController(text: 'Không có');
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  FamilyRelation _relation = FamilyRelation.child;
  String _gender = 'Nam';
  String _bloodType = 'O+';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _insuranceCtrl.dispose();
    _allergiesCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final emoji = switch (_relation) {
      FamilyRelation.child => _gender == 'Nam' ? '👦' : '👧',
      FamilyRelation.parent => _gender == 'Nam' ? '👴' : '👵',
      FamilyRelation.spouse => _gender == 'Nam' ? '👨‍💼' : '👩‍💼',
      FamilyRelation.self => '👤',
    };

    final newMember = FamilyMemberProfile(
      id: 'fam-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      relation: _relation,
      dateOfBirth: _dobCtrl.text.trim(),
      gender: _gender,
      insuranceNumber: _insuranceCtrl.text.trim().isEmpty
          ? 'Chưa cập nhật'
          : _insuranceCtrl.text.trim(),
      bloodType: _bloodType,
      allergies: _allergiesCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      avatarEmoji: emoji,
      medicalNotes: _notesCtrl.text.trim(),
    );

    widget.store.addFamilyMember(newMember);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm hồ sơ "${newMember.name}" thành công!'),
        backgroundColor: _kSuccess,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 20),
      child: Form(
        key: _formKey,
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
                  const Text('Thêm Hồ sơ Người thân',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Chọn quan hệ
              const Text('Mối quan hệ với chủ tài khoản:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              SegmentedButton<FamilyRelation>(
                segments: const [
                  ButtonSegment(
                      value: FamilyRelation.child, label: Text('Con cái')),
                  ButtonSegment(
                      value: FamilyRelation.parent, label: Text('Bố / Mẹ')),
                  ButtonSegment(
                      value: FamilyRelation.spouse, label: Text('Vợ / Chồng')),
                ],
                selected: {_relation},
                onSelectionChanged: (v) => setState(() => _relation = v.first),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên người thân *',
                  hintText: 'VD: Nguyễn Bảo An',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dobCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Ngày sinh (DD/MM/YYYY)',
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(labelText: 'Giới tính'),
                      items: const [
                        DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                        DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                      ],
                      onChanged: (v) => setState(() => _gender = v ?? 'Nam'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _insuranceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Số thẻ BHYT (nếu có)',
                        hintText: 'VD: TE401...',
                        prefixIcon: Icon(Icons.shield_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      initialValue: _bloodType,
                      decoration: const InputDecoration(labelText: 'Nhóm máu'),
                      items: const ['O+', 'A+', 'B+', 'AB+', 'O-', 'A-']
                          .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                          .toList(),
                      onChanged: (v) => setState(() => _bloodType = v ?? 'O+'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _allergiesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tiền sử dị ứng (thuốc, thức ăn)',
                  hintText: 'VD: Hải sản, Penicillin hoặc Không có',
                  prefixIcon: Icon(Icons.warning_amber_rounded),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bệnh nền / Ghi chú y tế',
                  hintText: 'VD: Tăng huyết áp, Đái tháo đường...',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Lưu hồ sơ người thân',
                      style: TextStyle(fontSize: 15)),
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


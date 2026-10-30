import 'dart:async';

import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../routes/app_routes.dart';
import '../state/medical_store.dart';

const _kPrimary = Color(0xFF0057CD);
const _kSuccess = Color(0xFF10B981);
const _kDanger = Color(0xFFEF4444);

/// Phòng Khám từ xa Telemedicine (Video Consultation Room).
/// Bệnh nhân khám bệnh trực tuyến với Bác sĩ qua video call chuẩn bảo mật y tế.
class TelemedicinePage extends StatefulWidget {
  const TelemedicinePage({super.key});

  @override
  State<TelemedicinePage> createState() => _TelemedicinePageState();
}

class _TelemedicinePageState extends State<TelemedicinePage> {
  Timer? _callTimer;
  int _seconds = 0;

  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isFrontCamera = true;
  bool _showChat = false;
  bool _sessionStarting = true;
  String? _sessionError;

  final _chatCtrl = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'sender': 'doctor',
      'text': 'Chào bạn, tôi là PGS.TS.BS Trần Minh Đức. Hôm nay bạn thấy sức khỏe thế nào?',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startBackendSession());
    _callTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _seconds++);
    });
  }

  Future<void> _startBackendSession() async {
    try {
      await MedicalScope.of(context).startTeleconsultationOnlineFirst();
    } catch (error) {
      if (mounted) setState(() => _sessionError = error.toString());
    } finally {
      if (mounted) setState(() => _sessionStarting = false);
    }
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _chatCtrl.dispose();
    super.dispose();
  }

  String _formatTime(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final doctor = store.doctors.first;
    final patient = store.activeFamilyMember;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Doctor Main Video View (Simulated)
            _buildDoctorVideo(doctor),

            // 2. Patient PiP Camera (Góc dưới bên phải)
            if (!_isVideoOff) _buildPatientPip(patient),

            // 3. Top Header: Call info & Timer
            _buildTopBar(doctor),

            // 4. Chat Overlay (khi bấm mở chat)
            if (_showChat) _buildChatOverlay(),

            // 5. Bottom Call Controls
            _buildBottomControls(store),
          ],
        ),
      ),
    );
  }

  // ── Màn hình Bác sĩ (Doctor View) ──────────────────────────────────────────

  Widget _buildDoctorVideo(DoctorProfile doctor) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF1E293B),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _kSuccess, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: _kSuccess.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const CircleAvatar(
                backgroundColor: Color(0xFF0057CD),
                child: Icon(Icons.person, size: 75, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              doctor.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${doctor.specialty} • ${doctor.experience}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _kSuccess.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kSuccess.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: _kSuccess, size: 8),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _sessionStarting
                          ? 'Đang mở phiên khám trên backend…'
                          : _sessionError == null
                          ? 'Phiên đã tạo; đang chờ kết nối WebRTC'
                          : 'Chưa mở được phiên khám thật',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _kSuccess, fontSize: 11),
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

  // ── Patient PiP (Góc phải) ────────────────────────────────────────────────

  Widget _buildPatientPip(FamilyMemberProfile patient) {
    return Positioned(
      right: 16,
      top: 90,
      child: Container(
        width: 105,
        height: 145,
        decoration: BoxDecoration(
          color: const Color(0xFF334155),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white38, width: 1.5),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(patient.avatarEmoji, style: const TextStyle(fontSize: 34)),
                const SizedBox(height: 4),
                Text(
                  patient.name.split(' ').last,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_isMuted)
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: _kDanger,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mic_off,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            Positioned(
              top: 4,
              left: 4,
              child: GestureDetector(
                onTap: () => setState(() => _isFrontCamera = !_isFrontCamera),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.flip_camera_ios,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(DoctorProfile doctor) {
    return Positioned(
      top: 10,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 14, color: _kSuccess),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'TeleHealth 256-bit • ${_formatTime(_seconds)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _showChat ? Icons.chat : Icons.chat_bubble_outline,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _showChat = !_showChat),
          ),
        ],
      ),
    );
  }

  // ── Chat Overlay ──────────────────────────────────────────────────────────

  Widget _buildChatOverlay() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 120,
      height: 250,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hộp thoại trong cuộc gọi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.white60,
                  ),
                  onPressed: () => setState(() => _showChat = false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(color: Colors.white12),
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (_, i) {
                  final msg = _messages[i];
                  final isDoc = msg['sender'] == 'doctor';
                  return Align(
                    alignment: isDoc
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDoc
                            ? const Color(0xFF334155)
                            : const Color(0xFF0057CD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        msg['text'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Nhập triệu chứng gửi bác sĩ...',
                      hintStyle: TextStyle(color: Colors.white38),
                      isDense: true,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: _kPrimary, size: 20),
                  onPressed: () {
                    if (_chatCtrl.text.trim().isEmpty) return;
                    setState(() {
                      _messages.add({
                        'sender': 'patient',
                        'text': _chatCtrl.text.trim(),
                      });
                      _chatCtrl.clear();
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Call Controls ──────────────────────────────────────────────────

  Widget _buildBottomControls(MedicalStore store) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute mic
            _controlBtn(
              icon: _isMuted ? Icons.mic_off : Icons.mic,
              color: _isMuted ? _kDanger : Colors.white24,
              iconColor: Colors.white,
              onTap: () => setState(() => _isMuted = !_isMuted),
            ),

            // Video toggle
            _controlBtn(
              icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
              color: _isVideoOff ? _kDanger : Colors.white24,
              iconColor: Colors.white,
              onTap: () => setState(() => _isVideoOff = !_isVideoOff),
            ),

            // Chat
            _controlBtn(
              icon: Icons.chat_bubble_outline,
              color: _showChat ? _kPrimary : Colors.white24,
              iconColor: Colors.white,
              onTap: () => setState(() => _showChat = !_showChat),
            ),

            // End Call (Red button)
            _controlBtn(
              icon: Icons.call_end,
              color: _kDanger,
              iconColor: Colors.white,
              onTap: () => _endConsultation(context, store),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlBtn({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }

  // ── Kết thúc khám & Tóm tắt tư vấn ────────────────────────────────────

  void _endConsultation(BuildContext context, MedicalStore store) {
    _callTimer?.cancel();
    store.endTelemedicine(
      doctorNotes: 'Bệnh nhân ổn định trong buổi tư vấn từ xa. Bác sĩ khuyến nghị đặt lịch khám trực tiếp nếu cần đơn thuốc hoặc cận lâm sàng.',
    );

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: _kSuccess),
            SizedBox(width: 8),
            Text('Hoàn tất buổi khám'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thời gian tư vấn: ${_formatTime(_seconds)}'),
            const SizedBox(height: 8),
            const Text(
              'Bác sĩ đã lưu tóm tắt tư vấn. Đơn thuốc điện tử chỉ được phát hành sau khi bác sĩ hoàn tất và ký EMR.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    color: _kPrimary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nếu cần kê đơn, hãy đặt lịch khám để bác sĩ xác nhận hồ sơ và phát hành đơn thuốc hợp lệ.',
                      style: TextStyle(fontSize: 12, color: _kPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Về trang chủ'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.appointments);
            },
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Đặt lịch khám'),
          ),
        ],
      ),
    );
  }
}

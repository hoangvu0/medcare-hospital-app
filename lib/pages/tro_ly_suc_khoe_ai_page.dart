import 'dart:async';

import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../routes/app_routes.dart';
import '../state/medical_store.dart';

class _ChatMessage {
  const _ChatMessage({
    required this.isUser,
    required this.text,
    this.suggestedSpecialty,
    this.suggestedDoctorId,
    this.quickReplies,
    this.createdAt,
    this.priorityLabel,
    this.priorityColor,
  });

  final bool isUser;
  final String text;
  final String? suggestedSpecialty;
  final String? suggestedDoctorId;
  final List<String>? quickReplies;
  final DateTime? createdAt;
  final String? priorityLabel;
  final Color? priorityColor;
}

class AiHealthAssistantPage extends StatefulWidget {
  const AiHealthAssistantPage({super.key});

  @override
  State<AiHealthAssistantPage> createState() => _AiHealthAssistantPageState();
}

class _AiHealthAssistantPageState extends State<AiHealthAssistantPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _replyTimer;
  bool _isTyping = false;

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      isUser: false,
      text: 'Xin chào bạn! Tôi là Trợ lý Sức khỏe AI của MedCare Hospital. 🏥\n\nTôi có thể hỗ trợ bạn:\n1. Sàng lọc triệu chứng lâm sàng sơ bộ\n2. Hướng dẫn xử trí ban đầu\n3. Gợi ý chuyên khoa và bác sĩ phù hợp nhất\n\nHãy mô tả triệu chứng hoặc chọn một tình huống dưới đây:',
      quickReplies: [
        'Đau quặn dạ dày, ợ chua',
        'Đau thắt ngực, khó thở',
        'Sốt cao 38.5°C, đau rát họng',
        'Đau khớp gối khi leo cầu thang',
        'Nổi mẩn đỏ ngứa rát da',
      ],
    ),
  ];

  @override
  void dispose() {
    _replyTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    final cleanText = text.trim();
    if (cleanText.isEmpty || _isTyping) return;

    setState(() {
      _messages.add(
        _ChatMessage(isUser: true, text: cleanText, createdAt: DateTime.now()),
      );
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    final delay = Duration(
      milliseconds: (650 + cleanText.length * 18).clamp(700, 1600).toInt(),
    );
    _replyTimer?.cancel();
    _replyTimer = Timer(delay, () async {
      if (!mounted) return;
      final reply = await _generateAiResponse(cleanText);
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(reply);
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<_ChatMessage> _generateAiResponse(String rawQuery) async {
    // Đây là ý định điều hướng trong app, không gửi sang engine chẩn đoán.
    // Nhờ vậy câu "Đặt khám Tim mạch" vẫn mở đúng luồng đặt lịch.
    if (_isBookingIntent(rawQuery)) {
      return _generateLocalAiResponse(rawQuery);
    }
    String? onlineText;
    try {
      onlineText = await MedicalScope.of(context)
          .askAiAssistant(message: rawQuery, history: _recentChatHistory());
    } catch (_) {
      onlineText = null;
    }
    if (onlineText == null || onlineText.trim().isEmpty) {
      return _ChatMessage(
        isUser: false,
        createdAt: DateTime.now(),
        priorityLabel: 'Chưa kết nối AI',
        priorityColor: const Color(0xFFF59E0B),
        text:
            'Chatbot chưa nhận được phản hồi từ dịch vụ AI thật. '
            'Vui lòng kiểm tra kết nối backend và cấu hình Infermedica/Gemini, '
            'hoặc liên hệ bệnh viện nếu cần tư vấn ngay.',
        quickReplies: const ['Mở SOS cấp cứu', 'Tìm bác sĩ'],
      );
    }
    return _ChatMessage(
      isUser: false,
      text: onlineText.trim(),
      createdAt: DateTime.now(),
      priorityLabel: 'AI y tế',
      priorityColor: const Color(0xFF0057CD),
    );
  }

  bool _isBookingIntent(String text) {
    final query = text.toLowerCase();
    return query.contains('đặt khám') ||
        query.contains('đặt lịch') ||
        query.contains('đặt hẹn') ||
        query.contains('hẹn khám');
  }

  List<Map<String, String>> _recentChatHistory() => _messages
      .where((message) => message.text.trim().isNotEmpty)
      .skip(_messages.length > 8 ? _messages.length - 8 : 0)
      .map(
        (message) => {
          'role': message.isUser ? 'user' : 'model',
          'text': message.text,
        },
      )
      .toList(growable: false);

  _ChatMessage _generateLocalAiResponse(String rawQuery) {
    final query = rawQuery.toLowerCase();

    if (_looksEmergency(query)) {
      return _ChatMessage(
        isUser: false,
        createdAt: DateTime.now(),
        priorityLabel: 'Cần xử trí ngay',
        priorityColor: const Color(0xFFDC2626),
        text:
            'Mình ghi nhận triệu chứng có dấu hiệu cần được nhân viên y tế đánh giá ngay.\n\n'
            'Bạn nên ngồi nghỉ, tránh tự di chuyển xa, gọi người thân hoặc liên hệ cấp cứu/nội viện nếu triệu chứng đang nặng lên.\n\n'
            'Trong app, bạn có thể mở SOS để xem thông tin cấp cứu và bệnh viện gần nhất.',
        quickReplies: const [
          'Mở SOS cấp cứu',
          'Tìm bệnh viện',
          'Đặt khám Tim mạch',
        ],
        suggestedSpecialty: 'Tim mạch',
        suggestedDoctorId: 'doc-01',
      );
    }

    // Kiểm tra ý định đặt lịch trước các từ khóa triệu chứng. Nếu không,
    // câu "Đặt khám Tim mạch" sẽ bị hiểu nhầm thành câu mô tả đau tim.
    if (query.contains('đặt khám') ||
        query.contains('đặt lịch') ||
        query.contains('đặt hẹn') ||
        query.contains('hẹn khám')) {
      final specialty = _specialtyFromText(query);
      return _ChatMessage(
        isUser: false,
        createdAt: DateTime.now(),
        priorityLabel: 'Sẵn sàng đặt lịch',
        priorityColor: const Color(0xFF10B981),
        text: specialty == null
            ? 'Bạn muốn đặt khám chuyên khoa nào? Mình có thể mở nhanh danh sách bác sĩ hoặc chuyển thẳng sang màn đặt lịch.'
            : 'Mình đã hiểu bạn muốn đặt khám $specialty. Bạn có thể bấm nút bên dưới để chọn bác sĩ, ngày khám và khung giờ.',
        suggestedSpecialty: specialty,
        suggestedDoctorId: _doctorIdForSpecialty(specialty),
        quickReplies: const [
          'Đặt khám Tim mạch',
          'Đặt khám Tiêu hóa',
          'Danh sách bác sĩ',
        ],
      );
    }

    if (query.contains('dạ dày') ||
        query.contains('ợ chua') ||
        query.contains('thượng vị') ||
        query.contains('bụng') ||
        query.contains('tiêu hóa')) {
      return _ChatMessage(
        isUser: false,
        createdAt: DateTime.now(),
        priorityLabel: 'Nên đặt khám',
        priorityColor: const Color(0xFF0D6EFD),
        text:
            'Phân tích sơ bộ:\n'
            'Triệu chứng đau vùng thượng vị kèm ợ chua thường gặp trong nhóm bệnh tiêu hóa như viêm dạ dày, trào ngược hoặc rối loạn tiêu hóa.\n\n'
            'Bạn có thể làm ngay:\n'
            '- Tránh đồ cay nóng, cà phê và nước có gas.\n'
            '- Không nằm ngay sau khi ăn no.\n'
            '- Ghi lại thời điểm đau, bữa ăn liên quan và thuốc đã dùng.\n\n'
            'Khuyến nghị: khám chuyên khoa Tiêu hóa để bác sĩ đánh giá và chỉ định xét nghiệm nếu cần.',
        suggestedSpecialty: 'Tiêu hóa',
        suggestedDoctorId: 'doc-05',
        quickReplies: const [
          'Đặt khám Tiêu hóa',
          'Xem đơn thuốc',
          'Tôi bị đau bao lâu rồi?',
        ],
      );
    } else if (query.contains('ngực') ||
        query.contains('tim') ||
        query.contains('khó thở') ||
        query.contains('hồi hộp')) {
      return _ChatMessage(
        isUser: false,
        createdAt: DateTime.now(),
        priorityLabel: 'Ưu tiên cao',
        priorityColor: const Color(0xFFF59E0B),
        text:
            'Đánh giá tim mạch sơ bộ:\n'
            'Đau ngực, hồi hộp hoặc khó thở là nhóm triệu chứng cần theo dõi kỹ. Nếu đang đau nhiều, khó thở tăng, choáng hoặc vã mồ hôi, hãy liên hệ cấp cứu ngay.\n\n'
            'Bạn có thể làm ngay:\n'
            '- Ngồi nghỉ ở nơi thoáng.\n'
            '- Đo huyết áp/nhịp tim nếu có thiết bị.\n'
            '- Không tự dùng thuốc tim mạch nếu chưa được bác sĩ kê.\n\n'
            'Khuyến nghị: khám Tim mạch sớm để được đo điện tim và đánh giá nguy cơ.',
        suggestedSpecialty: 'Tim mạch',
        suggestedDoctorId: 'doc-01',
        quickReplies: const [
          'Mở SOS cấp cứu',
          'Đặt khám Tim mạch',
          'Theo dõi chỉ số',
        ],
      );
    } else if (query.contains('khớp') ||
        query.contains('gối') ||
        query.contains('lưng') ||
        query.contains('xương')) {
      return _ChatMessage(
        isUser: false,
        createdAt: DateTime.now(),
        priorityLabel: 'Theo dõi và đặt khám',
        priorityColor: const Color(0xFF0D6EFD),
        text:
            'Đánh giá cơ xương khớp sơ bộ:\n'
            'Đau khớp gối, lưng hoặc đau khi vận động có thể liên quan đến căng cơ, viêm khớp, thoái hóa khớp hoặc chấn thương phần mềm.\n\n'
            'Bạn có thể làm ngay:\n'
            '- Hạn chế leo cầu thang, chạy nhảy hoặc mang nặng.\n'
            '- Nghỉ ngơi và theo dõi mức đau.\n'
            '- Đi khám sớm nếu đau tăng, sưng nóng đỏ hoặc hạn chế vận động.\n\n'
            'Khuyến nghị: khám Cơ xương khớp để bác sĩ kiểm tra vận động và hình ảnh nếu cần.',
        suggestedSpecialty: 'Cơ xương khớp',
        suggestedDoctorId: 'doc-03',
        quickReplies: const [
          'Đặt khám Cơ xương khớp',
          'Tôi đau khi vận động',
          'Tôi bị sưng khớp',
        ],
      );
    } else if (query.contains('sốt') ||
        query.contains('họng') ||
        query.contains('ho') ||
        query.contains('tai')) {
      return _ChatMessage(
        isUser: false,
        createdAt: DateTime.now(),
        priorityLabel: 'Nên theo dõi',
        priorityColor: const Color(0xFF10B981),
        text:
            'Đánh giá tai mũi họng sơ bộ:\n'
            'Sốt, ho hoặc đau rát họng thường gặp khi viêm đường hô hấp trên, viêm họng hoặc cảm cúm.\n\n'
            'Bạn có thể làm ngay:\n'
            '- Uống đủ nước, nghỉ ngơi.\n'
            '- Súc họng bằng nước muối sinh lý.\n'
            '- Theo dõi nhiệt độ và các triệu chứng đi kèm.\n\n'
            'Khuyến nghị: khám Tai Mũi Họng nếu sốt kéo dài, đau họng nhiều, ho tăng hoặc khó nuốt.',
        suggestedSpecialty: 'Tai Mũi Họng',
        suggestedDoctorId: 'doc-06',
        quickReplies: const [
          'Đặt khám Tai Mũi Họng',
          'Tôi sốt bao nhiêu độ?',
          'Có ho nhiều',
        ],
      );
    } else if (query.contains('da') ||
        query.contains('ngứa') ||
        query.contains('dị ứng') ||
        query.contains('mẩn')) {
      return _ChatMessage(
        isUser: false,
        createdAt: DateTime.now(),
        priorityLabel: 'Nên khám Da liễu',
        priorityColor: const Color(0xFF0D6EFD),
        text:
            'Đánh giá da liễu sơ bộ:\n'
            'Mẩn đỏ, ngứa hoặc nghi dị ứng có thể liên quan đến viêm da tiếp xúc, mề đay hoặc kích ứng với thuốc/thực phẩm/mỹ phẩm.\n\n'
            'Bạn có thể làm ngay:\n'
            '- Không gãi mạnh.\n'
            '- Tạm ngưng sản phẩm lạ mới dùng.\n'
            '- Ghi lại thuốc/thức ăn/mỹ phẩm đã dùng gần đây.\n\n'
            'Khuyến nghị: khám Da liễu để xác định nguyên nhân và dùng thuốc phù hợp.',
        suggestedSpecialty: 'Da liễu',
        suggestedDoctorId: 'doc-04',
        quickReplies: const [
          'Đặt khám Da liễu',
          'Tôi nghi dị ứng thuốc',
          'Nổi mẩn sau ăn',
        ],
      );
    }

    return _ChatMessage(
      isUser: false,
      createdAt: DateTime.now(),
      priorityLabel: 'Cần thêm thông tin',
      priorityColor: const Color(0xFF64748B),
      text:
          'Cảm ơn bạn đã chia sẻ. Để gợi ý đúng hơn, bạn cho mình biết thêm:\n\n'
          '- Triệu chứng bắt đầu từ khi nào?\n'
          '- Mức độ khó chịu nhẹ, vừa hay nhiều?\n'
          '- Có sốt, khó thở, đau ngực, nôn ói, dị ứng thuốc hoặc bệnh nền không?\n\n'
          'Bạn cũng có thể chọn nhanh một chuyên khoa bên dưới để đặt lịch khám.',
      quickReplies: const [
        'Khoa Tiêu hóa',
        'Khoa Tim mạch',
        'Khoa Nhi',
        'Khoa Cơ xương khớp',
        'Khoa Tai Mũi Họng',
      ],
    );
  }

  bool _looksEmergency(String query) {
    final emergencyTerms = [
      'đau ngực dữ dội',
      'khó thở nặng',
      'ngất',
      'co giật',
      'mất ý thức',
      'liệt',
      'nói khó',
      'chảy máu nhiều',
    ];
    return emergencyTerms.any(query.contains);
  }

  String? _specialtyFromText(String query) {
    if (query.contains('tim')) return 'Tim mạch';
    if (query.contains('tiêu hóa') || query.contains('dạ dày')) {
      return 'Tiêu hóa';
    }
    if (query.contains('nhi')) return 'Nhi khoa';
    if (query.contains('xương') || query.contains('khớp')) {
      return 'Cơ xương khớp';
    }
    if (query.contains('tai') ||
        query.contains('mũi') ||
        query.contains('họng')) {
      return 'Tai Mũi Họng';
    }
    if (query.contains('da')) return 'Da liễu';
    return null;
  }

  String? _doctorIdForSpecialty(String? specialty) => switch (specialty) {
    'Tim mạch' => 'doc-01',
    'Tiêu hóa' => 'doc-05',
    'Nhi khoa' => 'doc-02',
    'Cơ xương khớp' => 'doc-03',
    'Tai Mũi Họng' => 'doc-06',
    'Da liễu' => 'doc-04',
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF0057CD),
              child: Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MedCare AI Health',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Trợ lý y tế thông minh 24/7',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE7F0FF),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Color(0xFF0057CD)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI đưa ra phân tích tham khảo, không thay thế chẩn đoán bác sĩ.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF0057CD)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return const _TypingIndicator();
                }
                final msg = _messages[index];
                return _buildMessageItem(msg);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageItem(_ChatMessage msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final store = MedicalScope.of(context);

    DoctorProfile? doctor;
    if (msg.suggestedDoctorId != null) {
      doctor = store.doctors.cast<DoctorProfile?>().firstWhere(
        (d) => d?.id == msg.suggestedDoctorId,
        orElse: () => null,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: msg.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: msg.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!msg.isUser) ...[
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF0057CD),
                  child: Icon(Icons.smart_toy, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: msg.isUser
                        ? const Color(0xFF0057CD)
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                      bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!msg.isUser && msg.priorityLabel != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (msg.priorityColor ?? const Color(0xFF64748B))
                                    .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            msg.priorityLabel!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color:
                                  msg.priorityColor ?? const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        msg.text,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.42,
                          color: msg.isUser
                              ? Colors.white
                              : (isDark
                                    ? Colors.white
                                    : const Color(0xFF1B1B1F)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _formatMessageTime(msg.createdAt),
                          style: TextStyle(
                            fontSize: 10.5,
                            color: msg.isUser
                                ? Colors.white70
                                : (isDark ? Colors.white54 : Colors.black45),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (msg.isUser) ...[
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFFE2E7FF),
                  child: Icon(Icons.person, size: 16, color: Color(0xFF0057CD)),
                ),
              ],
            ],
          ),

          // Suggest doctor card if applicable
          if (doctor != null) ...[
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.only(left: 40, right: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF263238)
                    : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: const Icon(
                      Icons.medical_services,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${doctor.specialty} • ${doctor.location}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${doctor.price ~/ 1000}.000đ / lượt',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.appointments,
                        arguments: doctor,
                      );
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      'Đặt khám',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Quick replies
          if (msg.quickReplies != null && msg.quickReplies!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: msg.quickReplies!
                    .map(
                      (q) => ActionChip(
                        label: Text(q, style: const TextStyle(fontSize: 12)),
                        onPressed: () => _handleQuickReply(q),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleQuickReply(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('sos') || lower.contains('cấp cứu')) {
      Navigator.pushNamed(context, AppRoutes.emergencySos);
      return;
    }
    if (lower.contains('bệnh viện') || lower.contains('bản đồ')) {
      Navigator.pushNamed(context, AppRoutes.hospitalMap);
      return;
    }
    if (lower.contains('đơn thuốc')) {
      Navigator.pushNamed(context, AppRoutes.prescription);
      return;
    }
    if (lower.contains('chỉ số')) {
      Navigator.pushNamed(context, AppRoutes.vitalsTracker);
      return;
    }
    if (lower.contains('danh sách bác sĩ')) {
      Navigator.pushNamed(context, AppRoutes.doctors);
      return;
    }
    if (text.startsWith('Khoa ')) {
      _sendMessage('Đặt khám ${text.replaceFirst('Khoa ', '')}');
      return;
    }
    _sendMessage(text);
  }

  String _formatMessageTime(DateTime? value) {
    final time = value ?? DateTime.now();
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildInputBar() {
    final canSend = _controller.text.trim().isNotEmpty && !_isTyping;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: _isTyping
                        ? 'MedCare AI đang trả lời...'
                        : 'Nhập triệu chứng của bạn...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Xóa nội dung',
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _controller.clear();
                              setState(() {});
                            },
                          ),
                  ),
                  enabled: !_isTyping,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.send_rounded,
                color: canSend ? const Color(0xFF0057CD) : Colors.grey,
              ),
              onPressed: canSend ? () => _sendMessage(_controller.text) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF0057CD),
            child: Icon(Icons.smart_toy, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(delay: 0),
                const SizedBox(width: 4),
                _TypingDot(delay: 120),
                const SizedBox(width: 4),
                _TypingDot(delay: 240),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  const _TypingDot({required this.delay});

  final int delay;

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _opacity = Tween<double>(
      begin: 0.35,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Color(0xFF0057CD),
        shape: BoxShape.circle,
      ),
    ),
  );
}

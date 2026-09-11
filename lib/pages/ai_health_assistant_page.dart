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
  });

  final bool isUser;
  final String text;
  final String? suggestedSpecialty;
  final String? suggestedDoctorId;
  final List<String>? quickReplies;
}

class AiHealthAssistantPage extends StatefulWidget {
  const AiHealthAssistantPage({super.key});

  @override
  State<AiHealthAssistantPage> createState() => _AiHealthAssistantPageState();
}

class _AiHealthAssistantPageState extends State<AiHealthAssistantPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      isUser: false,
      text:
          'Xin chào bạn! Tôi là Trợ lý Sức khỏe AI của MedCare Hospital. 🏥\n\nTôi có thể hỗ trợ bạn:\n1. Sàng lọc triệu chứng lâm sàng sơ bộ\n2. Hướng dẫn xử trí ban đầu\n3. Gợi ý chuyên khoa và bác sĩ phù hợp nhất\n\nHãy mô tả triệu chứng hoặc chọn một tình huống dưới đây:',
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
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: text.trim()));
    });
    _controller.clear();
    _scrollToBottom();

    // AI thinking delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final reply = _generateAiResponse(text.toLowerCase());
      setState(() {
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

  _ChatMessage _generateAiResponse(String query) {
    if (query.contains('dạ dày') ||
        query.contains('ợ chua') ||
        query.contains('thượng vị') ||
        query.contains('bụng') ||
        query.contains('tiêu hóa')) {
      return const _ChatMessage(
        isUser: false,
        text:
            '🔍 **Phân tích lâm sàng sơ bộ:**\nTriệu chứng đau quặn vùng thượng vị kèm ợ chua nhiều khả năng là dấu hiệu của **Viêm loét dạ dày - tá tràng hoặc trào ngược dạ dày thực quản (GERD)**, có thể liên quan đến vi khuẩn Helicobacter Pylori.\n\n💡 **Lời khuyên ban đầu:**\n• Tránh ăn đồ cay nóng, cà phê, rượu bia.\n• Không nằm ngay sau khi ăn no.\n• Uống nước ấm từng ngụm nhỏ.\n\n👉 **Khuyến nghị:** Bạn nên thăm khám chuyên khoa **Tiêu hóa** để được nội soi chẩn đoán chính xác.',
        suggestedSpecialty: 'Tiêu hóa',
        suggestedDoctorId: 'doc-05',
      );
    } else if (query.contains('ngực') ||
        query.contains('tim') ||
        query.contains('khó thở') ||
        query.contains('hồi hộp')) {
      return const _ChatMessage(
        isUser: false,
        text:
            '⚠️ **Cảnh báo Tim mạch:**\nCơn đau thắt ngực, đè nặng sau xương ức hoặc hồi hộp khó thở là triệu chứng cần đặc biệt chú ý, có thể liên quan đến **Thiếu máu cơ tim hoặc rối loạn nhịp tim**.\n\n💡 **Hướng dẫn tức thì:**\n• Ngồi nghỉ ngơi tại chỗ, nới lỏng cổ áo.\n• Đo lại huyết áp và nhịp tim.\n• Nếu đau ngực lan lên cằm/tay trái kéo dài >15 phút, hãy gọi ngay Cấp cứu 1900 8899!\n\n👉 **Khuyến nghị:** Bạn nên khám chuyên khoa **Tim mạch** sớm nhất.',
        suggestedSpecialty: 'Tim mạch',
        suggestedDoctorId: 'doc-01',
      );
    } else if (query.contains('khớp') ||
        query.contains('gối') ||
        query.contains('lưng') ||
        query.contains('xương')) {
      return const _ChatMessage(
        isUser: false,
        text:
            '🦴 **Đánh giá Cơ Xương Khớp:**\nĐau nhức khớp gối hoặc cột sống khi vận động thường là biểu hiện của **Thoái hóa khớp hoặc tổn thương dây chằng, sụn chêm**.\n\n💡 **Lời khuyên:**\n• Tránh mang vác nặng hoặc leo cầu thang dốc.\n• Chườm ấm nếu đau mỏi mạn tính.\n\n👉 **Khuyến nghị:** Chuyên khoa **Cơ xương khớp**.',
        suggestedSpecialty: 'Cơ xương khớp',
        suggestedDoctorId: 'doc-03',
      );
    } else if (query.contains('sốt') ||
        query.contains('họng') ||
        query.contains('ho') ||
        query.contains('tai')) {
      return const _ChatMessage(
        isUser: false,
        text:
            '🌡️ **Đánh giá Tai Mũi Họng & Hô Hấp:**\nSốt kèm đau rát họng là phản ứng viêm đường hô hấp trên cấp tính (Viêm họng cấp, Viêm Amidan hoặc cảm cúm).\n\n💡 **Lời khuyên:**\n• Súc họng bằng nước muối sinh lý 0.9% 3-4 lần/ngày.\n• Uống nhiều nước ấm, có thể dùng Paracetamol hạ sốt nếu sốt trên 38.5°C.\n\n👉 **Khuyến nghị:** Chuyên khoa **Tai Mũi Họng**.',
        suggestedSpecialty: 'Tai Mũi Họng',
        suggestedDoctorId: 'doc-06',
      );
    } else if (query.contains('da') ||
        query.contains('ngứa') ||
        query.contains('dị ứng') ||
        query.contains('mẩn')) {
      return const _ChatMessage(
        isUser: false,
        text:
            '🩺 **Đánh giá Da Liễu:**\nNổi mề đay, mẩn đỏ ngứa rát là biểu hiện của viêm da tiếp xúc hoặc dị ứng thời tiết/thực phẩm.\n\n💡 **Lời khuyên:**\n• Không gãi mạnh tránh trầy xước nhiễm trùng.\n• Tạm ngưng các mỹ phẩm hoặc thực phẩm lạ vừa sử dụng.\n\n👉 **Khuyến nghị:** Chuyên khoa **Da liễu**.',
        suggestedSpecialty: 'Da liễu',
        suggestedDoctorId: 'doc-04',
      );
    }

    return const _ChatMessage(
      isUser: false,
      text:
          'Cảm ơn bạn đã chia sẻ. Triệu chứng của bạn cần được bác sĩ chuyên khoa thăm khám trực tiếp để làm xét nghiệm chẩn đoán chính xác.\n\nBạn có thể mô tả cụ thể hơn: Triệu chứng xuất hiện bao lâu rồi? Có đau nhiều không? Hoặc chọn một chuyên khoa bên dưới để đặt lịch khám:',
      quickReplies: [
        'Khoa Tiêu hóa',
        'Khoa Tim mạch',
        'Khoa Nhi',
        'Khoa Cơ xương khớp',
        'Khoa Tai Mũi Họng',
      ],
    );
  }

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MedCare AI Health', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Trợ lý y tế thông minh 24/7', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
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
              itemCount: _messages.length,
              itemBuilder: (context, index) {
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
        crossAxisAlignment:
            msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: msg.isUser
                          ? Colors.white
                          : (isDark ? Colors.white : const Color(0xFF1B1B1F)),
                    ),
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
                color: isDark ? const Color(0xFF263238) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: const Icon(Icons.medical_services, color: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          '${doctor.specialty} • ${doctor.location}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Đặt khám', style: TextStyle(fontSize: 12)),
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
                        onPressed: () => _sendMessage(q),
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

  Widget _buildInputBar() {
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
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Nhập triệu chứng của bạn...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: Color(0xFF0057CD)),
              onPressed: () => _sendMessage(_controller.text),
            ),
          ],
        ),
      ),
    );
  }
}

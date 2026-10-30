import 'dart:async';

import 'package:flutter/material.dart';

class MentalHealthPage extends StatefulWidget {
  const MentalHealthPage({super.key});

  @override
  State<MentalHealthPage> createState() => _MentalHealthPageState();
}

class _MentalHealthPageState extends State<MentalHealthPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  Timer? _phaseTimer;

  int _phaseIndex = 0; // 0: Hít vào, 1: Giữ hơi, 2: Thở ra, 3: Thư giãn
  final List<String> _phases = [
    'Hít vào sâu bằng mũi (4s)...',
    'Giữ hơi trong phổi (4s)...',
    'Thở ra từ từ bằng miệng (4s)...',
    'Thư giãn cơ thể (4s)...',
  ];

  bool _isBreathingActive = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _phaseTimer?.cancel();
    super.dispose();
  }

  void _toggleBreathing() {
    if (_isBreathingActive) {
      _animController.stop();
      _phaseTimer?.cancel();
      setState(() {
        _isBreathingActive = false;
        _phaseIndex = 0;
      });
    } else {
      setState(() => _isBreathingActive = true);
      _startNextPhase();
    }
  }

  void _startNextPhase() {
    if (!_isBreathingActive) return;

    if (_phaseIndex == 0) {
      _animController.forward(from: 0.0);
    } else if (_phaseIndex == 2) {
      _animController.reverse(from: 1.0);
    }

    _phaseTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || !_isBreathingActive) return;
      setState(() {
        _phaseIndex = (_phaseIndex + 1) % 4;
      });
      _startNextPhase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Sức khỏe Tinh thần & Thư giãn')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Box breathing header
          Text(
            'BÀI TẬP THỞ ĐIỀU HÒA (BOX BREATHING 4-4-4-4)',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0057CD),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Giảm căng thẳng thần kinh, hạ nhịp tim và làm dịu cơn co thắt dạ dày.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Breathing circle animation
          Center(
            child: SizedBox(
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      final scale = _isBreathingActive
                          ? _scaleAnimation.value
                          : 1.0;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF0057CD).withValues(alpha: 0.2),
                                const Color(0xFF0057CD).withValues(alpha: 0.05),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF0057CD),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x400057CD),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _isBreathingActive
                            ? Icons.spa
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Phase text
          Center(
            child: Text(
              _isBreathingActive
                  ? _phases[_phaseIndex]
                  : 'Nhấn nút bên dưới để bắt đầu bài tập thở',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),

          Center(
            child: FilledButton.icon(
              onPressed: _toggleBreathing,
              icon: Icon(_isBreathingActive ? Icons.stop : Icons.play_arrow),
              label: Text(
                _isBreathingActive ? 'Dừng bài tập' : 'Bắt đầu thư giãn',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Psychological screening card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology, color: Color(0xFF0057CD)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'BỘ TRẮC NGHIỆM TÂM LÝ CHUẨN WHO (PHQ-9 & GAD-7)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Thang đo Trầm cảm PHQ-9 và Lo âu GAD-7 được Bộ Y Tế và Tổ chức Y tế Thế giới (WHO) khuyến nghị để đánh giá sức khỏe tinh thần.',
                  style: TextStyle(fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _startPhq9Test(context),
                        icon: const Icon(
                          Icons.assignment_turned_in_outlined,
                          size: 18,
                        ),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Làm bài test PHQ-9 (9 câu)',
                            style: TextStyle(fontSize: 12.5),
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0057CD),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startPhq9Test(BuildContext context) {
    int totalScore = 0;
    const questions = [
      '1. Ít hứng thú hoặc không tìm thấy niềm vui trong công việc / sinh hoạt?',
      '2. Cảm thấy chán nản, buồn bã hoặc tuyệt vọng?',
      '3. Khó ngủ, ngủ chập chờn hoặc ngủ quá nhiều?',
      '4. Cảm thấy mệt mỏi hoặc thiếu năng lượng?',
      '5. Ăn không ngon miệng hoặc ăn quá mức?',
      '6. Cảm thấy bản thân tệ hại hoặc làm gia đình thất vọng?',
      '7. Khó tập trung khi đọc sách hoặc xem TV?',
      '8. Di chuyển hoặc nói chuyện chậm chạp, hoặc bồn chồn?',
      '9. Có suy nghĩ tiêu cực về bản thân?',
    ];

    showDialog<void>(
      context: context,
      builder: (ctx) {
        var currentQ = 0;
        return StatefulBuilder(
          builder: (ctx2, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(Icons.psychology, color: Color(0xFF0057CD)),
                  const SizedBox(width: 8),
                  Text(
                    'PHQ-9: Câu ${currentQ + 1}/9',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    questions[currentQ],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Trong 2 tuần qua, mức độ xảy ra thế nào?',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  _phqOption('Không có (0 điểm)', () {
                    totalScore += 0;
                    _nextOrFinish(
                      ctx,
                      setDialogState,
                      () => currentQ++,
                      questions.length,
                      currentQ,
                      totalScore,
                    );
                  }),
                  _phqOption('Vài ngày (1 điểm)', () {
                    totalScore += 1;
                    _nextOrFinish(
                      ctx,
                      setDialogState,
                      () => currentQ++,
                      questions.length,
                      currentQ,
                      totalScore,
                    );
                  }),
                  _phqOption('Hơn nửa số ngày (2 điểm)', () {
                    totalScore += 2;
                    _nextOrFinish(
                      ctx,
                      setDialogState,
                      () => currentQ++,
                      questions.length,
                      currentQ,
                      totalScore,
                    );
                  }),
                  _phqOption('Gần như mỗi ngày (3 điểm)', () {
                    totalScore += 3;
                    _nextOrFinish(
                      ctx,
                      setDialogState,
                      () => currentQ++,
                      questions.length,
                      currentQ,
                      totalScore,
                    );
                  }),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _phqOption(String text, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
      ),
    );
  }

  void _nextOrFinish(
    BuildContext ctx,
    StateSetter setDialogState,
    VoidCallback increment,
    int totalQ,
    int currentQ,
    int score,
  ) {
    if (currentQ < totalQ - 1) {
      setDialogState(increment);
    } else {
      Navigator.pop(ctx);
      _showClinicalResult(score);
    }
  }

  void _showClinicalResult(int score) {
    final String level;
    final Color color;
    final String advice;

    if (score <= 4) {
      level = 'Bình thường / Tối ưu ($score/27 điểm)';
      color = const Color(0xFF10B981);
      advice = 'Sức khỏe tinh thần của bạn rất tốt. Hãy tiếp tục duy trì vận động thể thao và ngủ đủ 7-8 tiếng.';
    } else if (score <= 9) {
      level = 'Căng thẳng nhẹ ($score/27 điểm)';
      color = const Color(0xFFF59E0B);
      advice = 'Bạn có dấu hiệu mệt mỏi nhẹ. Hãy thực hành bài tập thở sâu Box Breathing 2 lần mỗi ngày.';
    } else if (score <= 14) {
      level = 'Mức độ vừa ($score/27 điểm)';
      color = const Color(0xFFF97316);
      advice = 'Nên sắp xếp lịch hẹn với Chuyên gia Tâm lý lâm sàng hoặc Bác sĩ Thần kinh để được tư vấn sớm.';
    } else {
      level = 'Mức độ nặng ($score/27 điểm)';
      color = const Color(0xFFEF4444);
      advice = 'Khuyến nghị đến ngay Khoa Tâm lý - Thần kinh Bệnh viện MedCare để được bác sĩ chuyên khoa thăm khám.';
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.verified, color: color),
            const SizedBox(width: 8),
            const Expanded(child: Text('Kết quả Đánh giá PHQ-9')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mức độ: $level',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            Text(advice, style: const TextStyle(fontSize: 13, height: 1.4)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.support_agent_rounded, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đường dây nóng hỗ trợ tâm lý 24/7: 1900 6868 (Miễn phí)',
                      style: TextStyle(fontSize: 11),
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
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}

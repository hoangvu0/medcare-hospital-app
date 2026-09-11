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
      appBar: AppBar(
        title: const Text('Sức khỏe Tinh thần & Thư giãn'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Box breathing header
          Text(
            'BÀI TẬP THỞ ĐIỀU HÒA (BOX BREATHING 4-4-4-4)',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0057CD), letterSpacing: 0.5),
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
                      final scale = _isBreathingActive ? _scaleAnimation.value : 1.0;
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
                        _isBreathingActive ? Icons.spa : Icons.play_arrow_rounded,
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
              _isBreathingActive ? _phases[_phaseIndex] : 'Nhấn nút bên dưới để bắt đầu bài tập thở',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),

          Center(
            child: FilledButton.icon(
              onPressed: _toggleBreathing,
              icon: Icon(_isBreathingActive ? Icons.stop : Icons.play_arrow),
              label: Text(_isBreathingActive ? 'Dừng bài tập' : 'Bắt đầu thư giãn'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology, color: Color(0xFF0057CD)),
                    SizedBox(width: 8),
                    Text(
                      'SÀNG LỌC MỨC ĐỘ STRESS (PHQ-4)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Trong 2 tuần qua, bạn có thường xuyên cảm thấy căng thẳng, mất ngủ hoặc lo lắng quá mức?',
                  style: TextStyle(fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Không bao giờ'),
                      onPressed: () => _showStressResult(context, 'Tâm lý rất tốt (0/12 điểm) - Tiếp tục duy trì lối sống lành mạnh!'),
                    ),
                    ActionChip(
                      label: const Text('Thỉnh thoảng vài ngày'),
                      onPressed: () => _showStressResult(context, 'Căng thẳng nhẹ (3/12 điểm) - Hãy thực hiện bài tập thở Box Breathing và ngủ đủ giấc.'),
                    ),
                    ActionChip(
                      label: const Text('Thường xuyên hơn nửa số ngày'),
                      onPressed: () => _showStressResult(context, 'Căng thẳng vừa (7/12 điểm) - Nên tham khảo ý kiến bác sĩ chuyên khoa Thần kinh/Tâm lý.'),
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

  void _showStressResult(BuildContext context, String msg) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kết quả đánh giá tâm lý'),
        content: Text(msg),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}


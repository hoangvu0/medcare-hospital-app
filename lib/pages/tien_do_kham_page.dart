import 'package:flutter/material.dart';

import '../models/medical_models.dart';
import '../state/medical_store.dart';

class ClinicalPathwayPage extends StatelessWidget {
  const ClinicalPathwayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final steps = store.clinicalPathway;
    final currentStep = store.currentPathwayStep;
    final progress = store.pathwayProgressPercentage;
    final completedCount = store.completedStepsCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quy Trình & Lộ Trình Khám Bệnh',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Các bước cần làm theo chỉ định của Bác sĩ',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0057CD),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Đặt lại lộ trình',
            onPressed: () {
              store.resetPathway();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã đặt lại quy trình khám bệnh ban đầu.'),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── HERO PROGRESS BANNER ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF003882), Color(0xFF0057CD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x330057CD),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.route_rounded,
                              color: Colors.amberAccent,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'HÀNH TRÌNH KHÁM KHÉP KÍN',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '$completedCount/${steps.length} Bước xong',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF10B981),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'BƯỚC CẦN THỰC HIỆN NGAY BÂY GIỜ:',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bước ${currentStep.stepNumber}: ${currentStep.title}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            currentStep.location,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (currentStep.etaMinutes != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: Colors.amber.shade200,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Ước tính: ${currentStep.etaMinutes} phút',
                              style: TextStyle(
                                color: Colors.amber.shade200,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bác sĩ dặn: ${currentStep.doctorInstruction}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (currentStep.actionRoute != null)
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            currentStep.actionRoute!,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF003882),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text(
                            currentStep.actionText ?? 'Đi đến bước này',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        store.advancePathwayStep(currentStep.stepNumber);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✅ Đã hoàn tất Bước ${currentStep.stepNumber}! Chuyển sang bước tiếp theo.',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        'Đã xong ✓',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── DANH SÁCH CHI TIẾT 6 BƯỚC QUY TRÌNH (TIMELINE) ──
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'LỘ TRÌNH KHÁM CHI TIẾT TỪNG BƯỚC',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0057CD),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Tổng: ${steps.length} bước',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ...steps.map(
            (step) => _buildTimelineStep(context, store, step, isDark),
          ),

          const SizedBox(height: 16),

          // ── HỘP LƯU Ý Y TẾ QUAN TRỌNG ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.help_outline_rounded,
                  color: Colors.amber.shade800,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CẦN HỖ TRỢ TRONG QUÁ TRÌNH KHÁM?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Nếu bạn bị lạc phòng khám hoặc có thắc mắc về chỉ định xét nghiệm, hãy đến Bàn Hướng dẫn tại Sảnh Tầng 1 hoặc gọi Hotline nội viện 1900 8899 để được nhân viên y tế hỗ trợ trực tiếp.',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: Color(0xFF78350F),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(
    BuildContext context,
    MedicalStore store,
    ClinicalPathwayStep step,
    bool isDark,
  ) {
    final isDone = step.status == ClinicalStepStatus.completed;
    final isCurrent = step.status == ClinicalStepStatus.inProgress;

    Color badgeBg;
    Color badgeFg;
    IconData badgeIcon;

    if (isDone) {
      badgeBg = const Color(0xFF10B981);
      badgeFg = Colors.white;
      badgeIcon = Icons.check;
    } else if (isCurrent) {
      badgeBg = const Color(0xFF0057CD);
      badgeFg = Colors.white;
      badgeIcon = Icons.play_arrow_rounded;
    } else {
      badgeBg = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
      badgeFg = isDark ? Colors.white60 : Colors.grey;
      badgeIcon = Icons.circle_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? const Color(0xFF0057CD)
              : (isDone
                    ? const Color(0xFF10B981).withValues(alpha: 0.3)
                    : const Color(0xFFE2E8F0)),
          width: isCurrent ? 1.8 : 1.0,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: const Color(0xFF0057CD).withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                const BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: badgeBg,
                child: Icon(badgeIcon, color: badgeFg, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'BƯỚC ${step.stepNumber}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDone
                                ? const Color(0xFF10B981)
                                : (isCurrent
                                      ? const Color(0xFF0057CD)
                                      : Colors.grey),
                          ),
                        ),
                        if (isDone && step.completedTime != null) ...[
                          Text(
                            '• Xong lúc ${step.completedTime}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (isCurrent) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Đang thực hiện',
                              style: TextStyle(
                                fontSize: 9,
                                color: Color(0xFF0057CD),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDone ? Colors.grey : null,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: Color(0xFF0057CD),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        step.location,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0057CD),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.medical_information_outlined,
                        size: 13,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Yêu cầu bác sĩ: ${step.doctorInstruction}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            height: 1.3,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (step.actionRoute != null || isCurrent) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (step.actionRoute != null)
                        TextButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, step.actionRoute!),
                          icon: const Icon(Icons.arrow_forward, size: 14),
                          label: Text(
                            step.actionText ?? 'Mở chi tiết',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      if (isCurrent)
                        TextButton(
                          onPressed: () {
                            store.advancePathwayStep(step.stepNumber);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '✅ Đã hoàn thành Bước ${step.stepNumber}!',
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Đánh dấu xong ✓',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

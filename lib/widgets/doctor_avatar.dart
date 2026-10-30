import 'package:flutter/material.dart';

import '../models/medical_models.dart';

/// Ảnh hồ sơ bác sĩ dùng nguồn ảnh công khai, luôn có fallback để giao diện
/// không bị ô trống khi thiết bị đang offline hoặc CDN không phản hồi.
class DoctorAvatar extends StatelessWidget {
  const DoctorAvatar({
    super.key,
    required this.doctor,
    this.size = 64,
    this.borderRadius = 16,
  });

  final DoctorProfile doctor;
  final double size;
  final double borderRadius;

  static const _images = <String, String>{
    'doc-01': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=320&auto=format&fit=crop&q=80',
    'doc-02': 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?w=320&auto=format&fit=crop&q=80',
    'doc-03': 'https://images.unsplash.com/photo-1582750433449-648ed127bb54?w=320&auto=format&fit=crop&q=80',
    'doc-04': 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=320&auto=format&fit=crop&q=80',
    'doc-05': 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=320&auto=format&fit=crop&q=80',
    'doc-06': 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=320&auto=format&fit=crop&q=80',
    'doc-07': 'https://images.unsplash.com/photo-1598256989800-fe5f95da9787?w=320&auto=format&fit=crop&q=80',
    'doc-08': 'https://images.unsplash.com/photo-1618498082410-b4aa22193b38?w=320&auto=format&fit=crop&q=80',
  };

  String get _url =>
      doctor.imageUrl ?? _images[doctor.id] ?? _images['doc-01']!;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          _url,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : _fallback(),
          errorBuilder: (context, error, stackTrace) => _fallback(),
        ),
      ),
    );
  }

  Widget _fallback() => Container(
    color: const Color(0xFFE2E7FF),
    alignment: Alignment.center,
    child: Icon(Icons.person, size: size * .52, color: const Color(0xFF0057CD)),
  );
}

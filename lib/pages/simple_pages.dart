import 'package:flutter/material.dart';

class SpecialtyPage extends StatelessWidget {
  const SpecialtyPage({super.key, required this.specialty});
  final String specialty;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(specialty)),
    body: Center(
      child: Text(
        'Thông tin lịch khám và bác sĩ thuộc chuyên khoa $specialty.',
      ),
    ),
  );
}

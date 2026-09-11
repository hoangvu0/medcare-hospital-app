import 'package:flutter/material.dart';

import '../state/app_settings_store.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  String _enteredPin = '';
  String? _errorMessage;

  void _handleNumberPress(String digit) {
    if (_enteredPin.length >= 4) return;
    setState(() {
      _enteredPin += digit;
      _errorMessage = null;
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _handleBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _verifyPin() {
    final settings = AppSettingsScope.of(context);
    final success = settings.unlockWithPin(_enteredPin);
    if (!success) {
      setState(() {
        _errorMessage = 'Mã PIN không chính xác. Vui lòng thử lại!';
        _enteredPin = '';
      });
    }
  }

  void _biometricUnlock() {
    final settings = AppSettingsScope.of(context);
    // Simulate biometric authentication (FaceID/Fingerprint)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Xác thực sinh trắc học thành công!'),
        duration: Duration(seconds: 1),
      ),
    );
    settings.unlockWithPin(settings.pinCode ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0057CD).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 48,
                color: Color(0xFF0057CD),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'MedCare Security Lock',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhập mã PIN 4 số để truy cập hồ sơ y tế',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 28),
            // 4 dots indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final filled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? const Color(0xFF0057CD) : Colors.transparent,
                    border: Border.all(
                      color: filled ? const Color(0xFF0057CD) : Colors.grey,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const Spacer(flex: 2),
            // Numeric Keypad
            _keypad(isDark),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Bypass for testing/demo
                settings.setPinCode(null);
              },
              child: const Text('Bỏ qua mã khóa (Chế độ Demo)'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _keypad(bool isDark) {
    return Column(
      children: [
        for (var row = 0; row < 3; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var col = 1; col <= 3; col++)
                  _keyButton('${row * 3 + col}', isDark),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _biometricUnlock,
                iconSize: 32,
                tooltip: 'Vân tay / FaceID',
                icon: const Icon(Icons.fingerprint, color: Color(0xFF0057CD)),
              ),
              _keyButton('0', isDark),
              IconButton(
                onPressed: _handleBackspace,
                iconSize: 28,
                tooltip: 'Xóa',
                icon: const Icon(Icons.backspace_outlined),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _keyButton(String text, bool isDark) {
    return InkWell(
      onTap: () => _handleNumberPress(text),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}


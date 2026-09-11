import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_translations.dart';

class AppSettingsStore extends ChangeNotifier {
  AppSettingsStore() {
    _loadPreferences();
  }

  static const _prefThemeMode = 'medcare.settings.theme_mode';
  static const _prefLocale = 'medcare.settings.locale';
  static const _prefLargeText = 'medcare.settings.large_text';
  static const _prefHighContrast = 'medcare.settings.high_contrast';
  static const _prefHaptics = 'medcare.settings.haptics';
  static const _prefMaskData = 'medcare.settings.mask_data';
  static const _prefPinCode = 'medcare.settings.pin_code';

  ThemeMode _themeMode = ThemeMode.light;
  String _locale = 'vi';
  bool _isLargeText = false;
  bool _isHighContrast = false;
  bool _hapticsEnabled = true;
  bool _isMaskingSensitiveData = true;
  String? _pinCode;
  bool _isAppLocked = false;
  bool _isOfflineSimulated = false;
  int _simulatedCacheBytes = 1845200; // ~1.8 MB

  ThemeMode get themeMode => _themeMode;
  String get locale => _locale;
  bool get isLargeText => _isLargeText;
  bool get isHighContrast => _isHighContrast;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get isMaskingSensitiveData => _isMaskingSensitiveData;
  String? get pinCode => _pinCode;
  bool get isAppLocked => _isAppLocked;
  bool get isOfflineSimulated => _isOfflineSimulated;
  int get simulatedCacheBytes => _simulatedCacheBytes;

  String tr(String key) => AppTranslations.tr(key, _locale);

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_prefThemeMode);
      if (themeIndex != null && themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[themeIndex];
      }
      _locale = prefs.getString(_prefLocale) ?? 'vi';
      _isLargeText = prefs.getBool(_prefLargeText) ?? false;
      _isHighContrast = prefs.getBool(_prefHighContrast) ?? false;
      _hapticsEnabled = prefs.getBool(_prefHaptics) ?? true;
      _isMaskingSensitiveData = prefs.getBool(_prefMaskData) ?? true;
      _pinCode = prefs.getString(_prefPinCode);
      if (_pinCode != null && _pinCode!.isNotEmpty) {
        _isAppLocked = true;
      }
    } catch (_) {
      // SharedPreferences failure fallback
    } finally {
      notifyListeners();
    }
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
    _saveInt(_prefThemeMode, mode.index);
  }

  void setLocale(String lang) {
    if (_locale == lang) return;
    _locale = lang;
    triggerHaptic();
    notifyListeners();
    _saveString(_prefLocale, lang);
  }

  void setLargeText(bool enabled) {
    _isLargeText = enabled;
    triggerHaptic();
    notifyListeners();
    _saveBool(_prefLargeText, enabled);
  }

  void setHighContrast(bool enabled) {
    _isHighContrast = enabled;
    triggerHaptic();
    notifyListeners();
    _saveBool(_prefHighContrast, enabled);
  }

  void setHapticsEnabled(bool enabled) {
    _hapticsEnabled = enabled;
    notifyListeners();
    _saveBool(_prefHaptics, enabled);
  }

  void setMaskingSensitiveData(bool enabled) {
    _isMaskingSensitiveData = enabled;
    triggerHaptic();
    notifyListeners();
    _saveBool(_prefMaskData, enabled);
  }

  void setPinCode(String? pin) {
    _pinCode = pin;
    _isAppLocked = false;
    triggerHaptic();
    notifyListeners();
    if (pin == null) {
      _remove(_prefPinCode);
    } else {
      _saveString(_prefPinCode, pin);
    }
  }

  bool unlockWithPin(String enteredPin) {
    if (_pinCode == null || _pinCode == enteredPin) {
      _isAppLocked = false;
      triggerHaptic();
      notifyListeners();
      return true;
    }
    return false;
  }

  void lockApp() {
    if (_pinCode != null && _pinCode!.isNotEmpty) {
      _isAppLocked = true;
      notifyListeners();
    }
  }

  void toggleOfflineSimulation() {
    _isOfflineSimulated = !_isOfflineSimulated;
    triggerHaptic();
    notifyListeners();
  }

  Future<void> clearCache() async {
    _simulatedCacheBytes = 0;
    triggerHaptic();
    notifyListeners();
  }

  void triggerHaptic() {
    if (!_hapticsEnabled) return;
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  String maskText(String text, {int visiblePrefix = 3, int visibleSuffix = 3}) {
    if (!_isMaskingSensitiveData) return text;
    if (text.length <= (visiblePrefix + visibleSuffix)) return '***';
    final prefix = text.substring(0, visiblePrefix);
    final suffix = text.substring(text.length - visibleSuffix);
    final stars = '*' * (text.length - visiblePrefix - visibleSuffix);
    return '$prefix$stars$suffix';
  }

  Future<void> _saveInt(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, value);
    } catch (_) {}
  }

  Future<void> _saveString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}
  }

  Future<void> _saveBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {}
  }

  Future<void> _remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }
}

class AppSettingsScope extends InheritedNotifier<AppSettingsStore> {
  const AppSettingsScope({
    super.key,
    required AppSettingsStore store,
    required super.child,
  }) : super(notifier: store);

  static AppSettingsStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'No AppSettingsScope found in context');
    return scope!.notifier!;
  }
}


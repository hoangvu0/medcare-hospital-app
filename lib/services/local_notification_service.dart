import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

/// Lập lịch nhắc thuốc trên thiết bị. Dữ liệu thuốc vẫn lấy từ đơn thuốc
/// đã phát hành; service này chỉ chịu trách nhiệm hiển thị thông báo nền.
class LocalNotificationService {
  LocalNotificationService._();

  static final instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    timezone_data.initializeTimeZones();
    timezone.setLocalLocation(timezone.getLocation('Asia/Ho_Chi_Minh'));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    _initialized = true;
  }

  Future<void> scheduleMedication({
    required String id,
    required String medicineName,
    required String dosage,
    required String timeSlot,
  }) async {
    final slots = timeSlot
        .split('&')
        .map((value) => value.trim())
        .where((value) => RegExp(r'^\d{1,2}:\d{2}$').hasMatch(value));

    for (final slot in slots) {
      final time = slot.split(':');
      await scheduleDaily(
        id: stableId('$id-$slot'),
        title: 'Đến giờ uống thuốc',
        body: '$medicineName — $dosage',
        time: TimeOfDay(hour: int.parse(time[0]), minute: int.parse(time[1])),
        payload: id,
      );
    }
  }

  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
  }) async {
    await initialize();

    final now = timezone.TZDateTime.now(timezone.local);
    var scheduled = timezone.TZDateTime(
      timezone.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'medication_reminders',
        'Nhắc uống thuốc',
        channelDescription: 'Nhắc lịch uống thuốc theo đơn đã phát hành',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> cancelMedication({
    required String id,
    required String timeSlot,
  }) async {
    await initialize();
    for (final slot in timeSlot.split('&').map((value) => value.trim())) {
      if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(slot)) {
        await _plugin.cancel(id: stableId('$id-$slot'));
      }
    }
  }

  int stableId(String value) {
    var hash = 7;
    for (final codeUnit in value.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash;
  }
}

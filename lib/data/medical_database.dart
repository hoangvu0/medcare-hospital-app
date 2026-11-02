import 'dart:async';
import 'dart:io' show Platform;

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/medical_models.dart';

class MedicalDatabase {
  MedicalDatabase._();

  static final MedicalDatabase instance = MedicalDatabase._();

  static const _databaseName = 'medcare.sqlite';
  static const _databaseVersion = 6;
  static const _authKey = 'authenticated';
  static const _roleKey = 'current_role';
  static const _currentIdentifierKey = 'current_identifier';
  static const _backendAccessTokenKey = 'backend_access_token';
  static const _backendRefreshTokenKey = 'backend_refresh_token';

  Database? _database;
  Future<Database>? _opening;
  Future<void> _writeTail = Future<void>.value();
  bool _ffiReady = false;

  Future<T> _serializeWrite<T>(Future<T> Function(Database db) action) {
    final operation = _writeTail.then((_) async => action(await _db));
    // Keep the queue alive after an individual write fails so later writes can
    // still proceed and the original error is returned to its caller.
    _writeTail = operation.then<void>(
      (_) {},
      onError: (error, stackTrace) {},
    );
    return operation;
  }

  Future<Database> get _db async {
    if (_database != null) return _database!;
    if (_opening != null) return _opening!;

    _opening = _open();
    _database = await _opening!;
    _opening = null;
    return _database!;
  }

  Future<Database> _open() async {
    if ((Platform.isWindows || Platform.isLinux || Platform.isMacOS) &&
        !_ffiReady) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _ffiReady = true;
    }

    final dbDir = await getDatabasesPath();
    final dbPath = p.join(dbDir, _databaseName);

    return openDatabase(
      dbPath,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA busy_timeout = 15000');
        await db.execute('PRAGMA journal_mode = WAL');
      },
      onCreate: (db, version) async => _createTables(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createTables(db);
        }
        if (oldVersion < 3) {
          await _createTables(db);
        }
        if (oldVersion < 4) {
          await _createTables(db);
        }
        if (oldVersion < 5) {
          await _createTables(db);
        }
        if (oldVersion < 6) {
          await _createTables(db);
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
          CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
    await db.execute('''
          CREATE TABLE IF NOT EXISTS patient_profile (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            email TEXT NOT NULL,
            date_of_birth TEXT NOT NULL,
            insurance_number TEXT NOT NULL,
            blood_type TEXT NOT NULL,
            gender TEXT NOT NULL,
            address TEXT NOT NULL,
            allergies TEXT NOT NULL
          )
        ''');
    await db.execute('''
          CREATE TABLE IF NOT EXISTS appointments (
            id TEXT PRIMARY KEY,
            doctor_id TEXT NOT NULL,
            doctor_name TEXT NOT NULL,
            specialty TEXT NOT NULL,
            location TEXT NOT NULL,
            date_time TEXT NOT NULL,
            patient_name TEXT NOT NULL,
            reason TEXT NOT NULL,
            insurance_applied INTEGER NOT NULL,
            status TEXT NOT NULL,
            fee INTEGER NOT NULL,
            ticket_number TEXT
          )
        ''');
    await db.execute('''
          CREATE TABLE IF NOT EXISTS vital_signs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            systolic INTEGER NOT NULL,
            diastolic INTEGER NOT NULL,
            heart_rate INTEGER NOT NULL,
            blood_glucose REAL NOT NULL,
            weight_kg REAL NOT NULL,
            height_cm REAL NOT NULL,
            note TEXT,
            patient_id TEXT
          )
        ''');
    await db.execute('''
          CREATE TABLE IF NOT EXISTS medicine_schedule (
            id TEXT PRIMARY KEY,
            medicine_name TEXT NOT NULL,
            dosage TEXT NOT NULL,
            time_slot TEXT NOT NULL,
            period TEXT NOT NULL,
            instruction TEXT NOT NULL,
            is_taken INTEGER NOT NULL,
            taken_at TEXT
          )
        ''');
    await db.execute('''
          CREATE TABLE IF NOT EXISTS user_accounts (
            identifier TEXT PRIMARY KEY,
            password TEXT NOT NULL,
            role TEXT NOT NULL,
            display_name TEXT NOT NULL,
            patient_id TEXT
          )
        ''');
    await db.execute('''
          CREATE TABLE IF NOT EXISTS live_queue (
            id TEXT PRIMARY KEY,
            department TEXT NOT NULL,
            room TEXT NOT NULL,
            doctor_name TEXT NOT NULL,
            current_number INTEGER NOT NULL,
            patient_number INTEGER NOT NULL,
            ticket_code TEXT NOT NULL,
            estimated_minutes INTEGER NOT NULL
          )
        ''');
    await db.execute('''
          CREATE TABLE IF NOT EXISTS slot_configs (
            key TEXT PRIMARY KEY,
            doctor_id TEXT NOT NULL,
            date TEXT NOT NULL,
            time TEXT NOT NULL,
            capacity INTEGER NOT NULL,
            booked INTEGER NOT NULL
          )
        ''');
    await db.execute('''
          CREATE TABLE IF NOT EXISTS security_audit_logs (
            id TEXT PRIMARY KEY,
            actor TEXT NOT NULL,
            action TEXT NOT NULL,
            target_resource TEXT NOT NULL,
            ip_address TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            severity TEXT NOT NULL,
            status_description TEXT NOT NULL
          )
        ''');
    await db.execute('''
          CREATE TABLE IF NOT EXISTS active_sessions (
            id TEXT PRIMARY KEY,
            device_name TEXT NOT NULL,
            client_type TEXT NOT NULL,
            ip_address TEXT NOT NULL,
            last_active TEXT NOT NULL,
            is_current INTEGER NOT NULL
          )
        ''');
    await db.execute('''
          CREATE TABLE IF NOT EXISTS medical_records (
            id TEXT PRIMARY KEY,
            date TEXT NOT NULL,
            department TEXT NOT NULL,
            doctor_name TEXT NOT NULL,
            diagnosis TEXT NOT NULL,
            symptoms TEXT NOT NULL,
            treatment_plan TEXT NOT NULL,
            follow_up_date TEXT NOT NULL,
            prescription_code TEXT NOT NULL,
            total_fee INTEGER NOT NULL,
            insurance_covered INTEGER NOT NULL,
            diagnosis_code TEXT NOT NULL,
            icd10_name TEXT NOT NULL,
            differential_diagnosis TEXT,
            physical_exam_notes TEXT NOT NULL,
            lab_summary TEXT,
            xray_findings TEXT,
            doctor_instructions TEXT NOT NULL,
            digital_signature_token TEXT NOT NULL,
            risk_level TEXT NOT NULL,
            prescribed_medicines_summary TEXT
          )
        ''');
    await db.execute('''
          CREATE TABLE IF NOT EXISTS prescription_medicines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            dosage TEXT NOT NULL,
            quantity TEXT NOT NULL,
            instruction TEXT NOT NULL,
            warning TEXT
          )
        ''');
    await db.execute('''
          CREATE TABLE IF NOT EXISTS app_notifications (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            created_at TEXT NOT NULL,
            read INTEGER NOT NULL
          )
        ''');
    await db.execute('''
          CREATE TABLE IF NOT EXISTS payment_transactions (
            id TEXT PRIMARY KEY,
            visit_code TEXT NOT NULL,
            description TEXT NOT NULL,
            gross_amount INTEGER NOT NULL,
            insurance_amount INTEGER NOT NULL,
            net_amount INTEGER NOT NULL,
            method TEXT NOT NULL,
            status TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            wallet_name TEXT,
            invoice_email TEXT,
            receipt_code TEXT
          )
        ''');
    await db.execute('''
          CREATE TABLE IF NOT EXISTS pharmacy_orders (
            id TEXT PRIMARY KEY,
            prescription_id TEXT NOT NULL,
            patient_name TEXT NOT NULL,
            phone TEXT NOT NULL,
            delivery_address TEXT NOT NULL,
            pharmacy_name TEXT NOT NULL,
            items_count INTEGER NOT NULL,
            medicine_total INTEGER NOT NULL,
            shipping_fee INTEGER NOT NULL,
            status TEXT NOT NULL,
            ordered_at TEXT NOT NULL,
            estimated_minutes INTEGER NOT NULL,
            patient_id TEXT
          )
        ''');
    await db.execute('''
          CREATE TABLE IF NOT EXISTS backend_sync_state (
            id TEXT PRIMARY KEY,
            pending_changes INTEGER NOT NULL,
            last_local_change_at TEXT,
            last_synced_at TEXT,
            last_error TEXT
          )
        ''');
  }

  Future<bool?> loadAuthenticated() async {
    final rows = await (await _db).query(
      'settings',
      columns: const ['value'],
      where: 'key = ?',
      whereArgs: const [_authKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] == 'true';
  }

  Future<String?> loadSetting(String key) async {
    final rows = await (await _db).query(
      'settings',
      columns: const ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> saveSetting(String key, String? value) async {
    await _serializeWrite((db) async {
      if (value == null) {
        await db.delete('settings', where: 'key = ?', whereArgs: [key]);
        return;
      }
      await db.insert('settings', {
        'key': key,
        'value': value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> saveAuthenticated(bool authenticated) async {
    await _serializeWrite((db) => db.insert('settings', {
      'key': _authKey,
      'value': authenticated.toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace));
  }

  Future<UserRole?> loadCurrentRole() async {
    final rows = await (await _db).query(
      'settings',
      columns: const ['value'],
      where: 'key = ?',
      whereArgs: const [_roleKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _roleByName(rows.first['value'] as String?);
  }

  Future<void> saveCurrentRole(UserRole role) async {
    await _serializeWrite((db) => db.insert('settings', {
      'key': _roleKey,
      'value': role.name,
    }, conflictAlgorithm: ConflictAlgorithm.replace));
  }

  Future<String?> loadCurrentIdentifier() async {
    final rows = await (await _db).query(
      'settings',
      columns: const ['value'],
      where: 'key = ?',
      whereArgs: const [_currentIdentifierKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> saveCurrentIdentifier(String? identifier) async {
    await _serializeWrite((db) async {
      if (identifier == null || identifier.isEmpty) {
        await db.delete(
          'settings',
          where: 'key = ?',
          whereArgs: const [_currentIdentifierKey],
        );
        return;
      }
      await db.insert('settings', {
        'key': _currentIdentifierKey,
        'value': identifier,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<String?> loadBackendAccessToken() =>
      _loadSetting(_backendAccessTokenKey);

  Future<void> saveBackendAccessToken(String? token) =>
      _saveNullableSetting(_backendAccessTokenKey, token);

  Future<String?> loadBackendRefreshToken() =>
      _loadSetting(_backendRefreshTokenKey);

  Future<void> saveBackendRefreshToken(String? token) =>
      _saveNullableSetting(_backendRefreshTokenKey, token);

  Future<String?> _loadSetting(String key) async {
    final rows = await (await _db).query(
      'settings',
      columns: const ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> _saveNullableSetting(String key, String? value) async {
    await _serializeWrite((db) async {
      if (value == null || value.trim().isEmpty) {
        await db.delete('settings', where: 'key = ?', whereArgs: [key]);
        return;
      }
      await db.insert('settings', {
        'key': key,
        'value': value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<BackendSyncState?> loadBackendSyncState() async {
    final rows = await (await _db).query(
      'backend_sync_state',
      where: 'id = ?',
      whereArgs: const ['main'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _backendSyncStateFromRow(rows.first);
  }

  Future<void> saveBackendSyncState(BackendSyncState state) async {
    await _serializeWrite((db) => db.insert(
      'backend_sync_state',
      _backendSyncStateToRow(state),
      conflictAlgorithm: ConflictAlgorithm.replace,
    ));
  }

  Future<List<AuthAccount>> loadAccounts() async {
    final rows = await (await _db).query('user_accounts');
    return rows.map(_accountFromRow).toList();
  }

  Future<void> upsertAccount(AuthAccount account) async {
    await _serializeWrite((db) => db.insert(
      'user_accounts',
      _accountToRow(account),
      conflictAlgorithm: ConflictAlgorithm.replace,
    ));
  }

  Future<void> replaceAccounts(List<AuthAccount> accounts) async {
    await _serializeWrite((db) async {
      await db.transaction((txn) async {
        final batch = txn.batch();
        batch.delete('user_accounts');
        for (final account in accounts) {
          batch.insert(
            'user_accounts',
            _accountToRow(account),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    });
  }

  Future<PatientProfile?> loadProfile() async {
    final rows = await (await _db).query('patient_profile', limit: 1);
    if (rows.isEmpty) return null;
    return _profileFromRow(rows.first);
  }

  Future<void> saveProfile(PatientProfile profile) async {
    await _serializeWrite((db) => db.insert(
      'patient_profile',
      _profileToRow(profile),
      conflictAlgorithm: ConflictAlgorithm.replace,
    ));
  }

  Future<void> _replaceTable(
    String table,
    Iterable<Map<String, Object?>> rows,
  ) async {
    await _serializeWrite((db) async {
      await db.transaction((txn) async {
        final batch = txn.batch();
        batch.delete(table);
        for (final row in rows) {
          batch.insert(
            table,
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    });
  }

  Future<List<Appointment>> loadAppointments() async {
    final rows = await (await _db).query(
      'appointments',
      orderBy: 'date_time ASC',
    );
    return rows.map(_appointmentFromRow).toList();
  }

  Future<void> replaceAppointments(List<Appointment> appointments) async {
    await _replaceTable(
      'appointments',
      appointments.map(_appointmentToRow),
    );
  }

  Future<List<VitalSignRecord>> loadVitals() async {
    final rows = await (await _db).query(
      'vital_signs',
      orderBy: 'timestamp DESC, id DESC',
    );
    return rows.map(_vitalFromRow).toList();
  }

  Future<void> replaceVitals(List<VitalSignRecord> vitals) async {
    await _replaceTable('vital_signs', vitals.map(_vitalToRow));
  }

  Future<List<MedicineScheduleItem>> loadMedicineSchedule() async {
    final rows = await (await _db).query('medicine_schedule');
    return rows.map(_medicineScheduleFromRow).toList();
  }

  Future<void> replaceMedicineSchedule(
    List<MedicineScheduleItem> schedule,
  ) async {
    await _replaceTable(
      'medicine_schedule',
      schedule.map(_medicineScheduleToRow),
    );
  }

  Future<LiveQueueInfo?> loadQueue() async {
    final rows = await (await _db).query(
      'live_queue',
      where: 'id = ?',
      whereArgs: const ['main'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _queueFromRow(rows.first);
  }

  Future<void> saveQueue(LiveQueueInfo queue) async {
    await _serializeWrite((db) => db.insert(
      'live_queue',
      _queueToRow(queue),
      conflictAlgorithm: ConflictAlgorithm.replace,
    ));
  }

  Future<List<SlotConfig>> loadSlotConfigs() async {
    final rows = await (await _db).query('slot_configs');
    return rows.map(_slotConfigFromRow).toList();
  }

  Future<void> replaceSlotConfigs(List<SlotConfig> slots) async {
    await _replaceTable('slot_configs', slots.map(_slotConfigToRow));
  }

  Future<List<SecurityAuditLog>> loadSecurityAuditLogs() async {
    final rows = await (await _db).query(
      'security_audit_logs',
      orderBy: 'timestamp DESC',
    );
    return rows.map(_securityAuditFromRow).toList();
  }

  Future<void> replaceSecurityAuditLogs(List<SecurityAuditLog> logs) async {
    await _replaceTable(
      'security_audit_logs',
      logs.map(_securityAuditToRow),
    );
  }

  Future<List<ActiveSessionInfo>> loadActiveSessions() async {
    final rows = await (await _db).query(
      'active_sessions',
      orderBy: 'is_current DESC, last_active DESC',
    );
    return rows.map(_activeSessionFromRow).toList();
  }

  Future<void> replaceActiveSessions(List<ActiveSessionInfo> sessions) async {
    await _replaceTable('active_sessions', sessions.map(_activeSessionToRow));
  }

  Future<List<MedicalRecord>> loadMedicalRecords() async {
    final rows = await (await _db).query(
      'medical_records',
      orderBy: 'date DESC',
    );
    return rows.map(_medicalRecordFromRow).toList();
  }

  Future<void> replaceMedicalRecords(List<MedicalRecord> records) async {
    await _replaceTable('medical_records', records.map(_medicalRecordToRow));
  }

  Future<List<MedicineItem>> loadPrescriptionMedicines() async {
    final rows = await (await _db).query(
      'prescription_medicines',
      orderBy: 'id DESC',
    );
    return rows.map(_medicineItemFromRow).toList();
  }

  Future<void> replacePrescriptionMedicines(
    List<MedicineItem> medicines,
  ) async {
    await _replaceTable(
      'prescription_medicines',
      medicines.reversed.map(_medicineItemToRow),
    );
  }

  Future<List<AppNotification>> loadNotifications() async {
    final rows = await (await _db).query(
      'app_notifications',
      orderBy: 'created_at DESC',
    );
    return rows.map(_notificationFromRow).toList();
  }

  Future<void> replaceNotifications(List<AppNotification> notifications) async {
    await _replaceTable(
      'app_notifications',
      notifications.map(_notificationToRow),
    );
  }

  Future<List<PaymentTransaction>> loadPaymentTransactions() async {
    final rows = await (await _db).query(
      'payment_transactions',
      orderBy: 'timestamp DESC',
    );
    return rows.map(_paymentTransactionFromRow).toList();
  }

  Future<void> replacePaymentTransactions(
    List<PaymentTransaction> transactions,
  ) async {
    await _replaceTable(
      'payment_transactions',
      transactions.map(_paymentTransactionToRow),
    );
  }

  Future<List<PharmacyOrder>> loadPharmacyOrders() async {
    final rows = await (await _db).query(
      'pharmacy_orders',
      orderBy: 'ordered_at DESC',
    );
    return rows.map(_pharmacyOrderFromRow).toList();
  }

  Future<void> replacePharmacyOrders(List<PharmacyOrder> orders) async {
    await _replaceTable('pharmacy_orders', orders.map(_pharmacyOrderToRow));
  }

  Map<String, Object?> _backendSyncStateToRow(BackendSyncState value) => {
    'id': 'main',
    'pending_changes': value.pendingChanges,
    'last_local_change_at': value.lastLocalChangeAt?.toIso8601String(),
    'last_synced_at': value.lastSyncedAt?.toIso8601String(),
    'last_error': value.lastError,
  };

  BackendSyncState _backendSyncStateFromRow(Map<String, Object?> row) =>
      BackendSyncState(
        pendingChanges: row['pending_changes'] as int? ?? 0,
        lastLocalChangeAt: row['last_local_change_at'] == null
            ? null
            : DateTime.parse(row['last_local_change_at'] as String),
        lastSyncedAt: row['last_synced_at'] == null
            ? null
            : DateTime.parse(row['last_synced_at'] as String),
        lastError: row['last_error'] as String?,
      );

  Map<String, Object?> _profileToRow(PatientProfile value) => {
    'id': value.id,
    'name': value.name,
    'phone': value.phone,
    'email': value.email,
    'date_of_birth': value.dateOfBirth,
    'insurance_number': value.insuranceNumber,
    'blood_type': value.bloodType,
    'gender': value.gender,
    'address': value.address,
    'allergies': value.allergies,
  };

  PatientProfile _profileFromRow(Map<String, Object?> row) => PatientProfile(
    id: row['id'] as String? ?? 'MC-89241',
    name: row['name'] as String? ?? 'Unknown',
    phone: row['phone'] as String? ?? '',
    email: row['email'] as String? ?? '',
    dateOfBirth: row['date_of_birth'] as String? ?? '',
    insuranceNumber: row['insurance_number'] as String? ?? '',
    bloodType: row['blood_type'] as String? ?? 'O+',
    gender: row['gender'] as String? ?? 'Nam',
    address: row['address'] as String? ?? '',
    allergies: row['allergies'] as String? ?? '',
  );

  Map<String, Object?> _appointmentToRow(Appointment value) => {
    'id': value.id,
    'doctor_id': value.doctorId,
    'doctor_name': value.doctorName,
    'specialty': value.specialty,
    'location': value.location,
    'date_time': value.dateTime.toIso8601String(),
    'patient_name': value.patientName,
    'reason': value.reason,
    'insurance_applied': value.insuranceApplied ? 1 : 0,
    'status': value.status.name,
    'fee': value.fee,
    'ticket_number': value.ticketNumber,
  };

  Appointment _appointmentFromRow(Map<String, Object?> row) => Appointment(
    id: row['id'] as String,
    doctorId: row['doctor_id'] as String,
    doctorName: row['doctor_name'] as String,
    specialty: row['specialty'] as String,
    location: row['location'] as String,
    dateTime: DateTime.parse(row['date_time'] as String),
    patientName: row['patient_name'] as String,
    reason: row['reason'] as String,
    insuranceApplied: row['insurance_applied'] == 1,
    status: _appointmentStatusByName(row['status'] as String?),
    fee: row['fee'] as int? ?? 0,
    ticketNumber: row['ticket_number'] as String?,
  );

  AppointmentStatus _appointmentStatusByName(String? name) {
    for (final status in AppointmentStatus.values) {
      if (status.name == name) return status;
    }
    return AppointmentStatus.confirmed;
  }

  Map<String, Object?> _vitalToRow(VitalSignRecord value) => {
    'timestamp': value.timestamp.toIso8601String(),
    'systolic': value.systolic,
    'diastolic': value.diastolic,
    'heart_rate': value.heartRate,
    'blood_glucose': value.bloodGlucose,
    'weight_kg': value.weightKg,
    'height_cm': value.heightCm,
    'note': value.note,
    'patient_id': value.patientId,
  };

  VitalSignRecord _vitalFromRow(Map<String, Object?> row) => VitalSignRecord(
    timestamp: DateTime.parse(row['timestamp'] as String),
    systolic: row['systolic'] as int,
    diastolic: row['diastolic'] as int,
    heartRate: row['heart_rate'] as int,
    bloodGlucose: (row['blood_glucose'] as num).toDouble(),
    weightKg: (row['weight_kg'] as num).toDouble(),
    heightCm: (row['height_cm'] as num).toDouble(),
    note: row['note'] as String?,
    patientId: row['patient_id'] as String?,
  );

  Map<String, Object?> _medicineScheduleToRow(MedicineScheduleItem value) => {
    'id': value.id,
    'medicine_name': value.medicineName,
    'dosage': value.dosage,
    'time_slot': value.timeSlot,
    'period': value.period,
    'instruction': value.instruction,
    'is_taken': value.isTaken ? 1 : 0,
    'taken_at': value.takenAt?.toIso8601String(),
  };

  MedicineScheduleItem _medicineScheduleFromRow(Map<String, Object?> row) =>
      MedicineScheduleItem(
        id: row['id'] as String,
        medicineName: row['medicine_name'] as String,
        dosage: row['dosage'] as String,
        timeSlot: row['time_slot'] as String,
        period: row['period'] as String,
        instruction: row['instruction'] as String,
        isTaken: row['is_taken'] == 1,
        takenAt: row['taken_at'] == null
            ? null
            : DateTime.parse(row['taken_at'] as String),
      );

  Map<String, Object?> _accountToRow(AuthAccount value) => {
    'identifier': value.identifier,
    'password': value.passwordHash,
    'role': value.role.name,
    'display_name': value.displayName,
    'patient_id': value.patientId,
  };

  AuthAccount _accountFromRow(Map<String, Object?> row) => AuthAccount(
    identifier: row['identifier'] as String,
    passwordHash: row['password'] as String,
    role: _roleByName(row['role'] as String?) ?? UserRole.patient,
    displayName: row['display_name'] as String? ?? '',
    patientId: row['patient_id'] as String?,
  );

  UserRole? _roleByName(String? name) {
    for (final role in UserRole.values) {
      if (role.name == name) return role;
    }
    return null;
  }

  Map<String, Object?> _queueToRow(LiveQueueInfo value) => {
    'id': 'main',
    'department': value.department,
    'room': value.room,
    'doctor_name': value.doctorName,
    'current_number': value.currentNumber,
    'patient_number': value.patientNumber,
    'ticket_code': value.ticketCode,
    'estimated_minutes': value.estimatedMinutes,
  };

  LiveQueueInfo _queueFromRow(Map<String, Object?> row) => LiveQueueInfo(
    department: row['department'] as String,
    room: row['room'] as String,
    doctorName: row['doctor_name'] as String,
    currentNumber: row['current_number'] as int,
    patientNumber: row['patient_number'] as int,
    ticketCode: row['ticket_code'] as String,
    estimatedMinutes: row['estimated_minutes'] as int,
  );

  Map<String, Object?> _slotConfigToRow(SlotConfig value) => {
    'key': value.key,
    'doctor_id': value.doctorId,
    'date': value.date,
    'time': value.time,
    'capacity': value.capacity,
    'booked': value.booked,
  };

  SlotConfig _slotConfigFromRow(Map<String, Object?> row) => SlotConfig(
    doctorId: row['doctor_id'] as String,
    date: row['date'] as String,
    time: row['time'] as String,
    capacity: row['capacity'] as int,
    booked: row['booked'] as int,
  );

  Map<String, Object?> _securityAuditToRow(SecurityAuditLog value) => {
    'id': value.id,
    'actor': value.actor,
    'action': value.action,
    'target_resource': value.targetResource,
    'ip_address': value.ipAddress,
    'timestamp': value.timestamp.toIso8601String(),
    'severity': value.severity.name,
    'status_description': value.statusDescription,
  };

  SecurityAuditLog _securityAuditFromRow(Map<String, Object?> row) =>
      SecurityAuditLog(
        id: row['id'] as String,
        actor: row['actor'] as String,
        action: row['action'] as String,
        targetResource: row['target_resource'] as String,
        ipAddress: row['ip_address'] as String,
        timestamp: DateTime.parse(row['timestamp'] as String),
        severity: _securitySeverityByName(row['severity'] as String?),
        statusDescription: row['status_description'] as String,
      );

  SecuritySeverity _securitySeverityByName(String? name) {
    for (final severity in SecuritySeverity.values) {
      if (severity.name == name) return severity;
    }
    return SecuritySeverity.info;
  }

  Map<String, Object?> _activeSessionToRow(ActiveSessionInfo value) => {
    'id': value.id,
    'device_name': value.deviceName,
    'client_type': value.clientType,
    'ip_address': value.ipAddress,
    'last_active': value.lastActive,
    'is_current': value.isCurrent ? 1 : 0,
  };

  ActiveSessionInfo _activeSessionFromRow(Map<String, Object?> row) =>
      ActiveSessionInfo(
        id: row['id'] as String,
        deviceName: row['device_name'] as String,
        clientType: row['client_type'] as String,
        ipAddress: row['ip_address'] as String,
        lastActive: row['last_active'] as String,
        isCurrent: row['is_current'] == 1,
      );

  Map<String, Object?> _medicalRecordToRow(MedicalRecord value) => {
    'id': value.id,
    'date': value.date,
    'department': value.department,
    'doctor_name': value.doctorName,
    'diagnosis': value.diagnosis,
    'symptoms': value.symptoms,
    'treatment_plan': value.treatmentPlan,
    'follow_up_date': value.followUpDate,
    'prescription_code': value.prescriptionCode,
    'total_fee': value.totalFee,
    'insurance_covered': value.insuranceCovered,
    'diagnosis_code': value.diagnosisCode,
    'icd10_name': value.icd10Name,
    'differential_diagnosis': value.differentialDiagnosis,
    'physical_exam_notes': value.physicalExamNotes,
    'lab_summary': value.labSummary,
    'xray_findings': value.xrayFindings,
    'doctor_instructions': value.doctorInstructions,
    'digital_signature_token': value.digitalSignatureToken,
    'risk_level': value.riskLevel,
    'prescribed_medicines_summary': value.prescribedMedicinesSummary,
  };

  MedicalRecord _medicalRecordFromRow(Map<String, Object?> row) =>
      MedicalRecord(
        id: row['id'] as String,
        date: row['date'] as String,
        department: row['department'] as String,
        doctorName: row['doctor_name'] as String,
        diagnosis: row['diagnosis'] as String,
        symptoms: row['symptoms'] as String,
        treatmentPlan: row['treatment_plan'] as String,
        followUpDate: row['follow_up_date'] as String,
        prescriptionCode: row['prescription_code'] as String,
        totalFee: row['total_fee'] as int,
        insuranceCovered: row['insurance_covered'] as int,
        diagnosisCode: row['diagnosis_code'] as String? ?? 'I10',
        icd10Name: row['icd10_name'] as String? ?? 'Tăng huyết áp nguyên phát',
        differentialDiagnosis: row['differential_diagnosis'] as String?,
        physicalExamNotes: row['physical_exam_notes'] as String? ?? '',
        labSummary: row['lab_summary'] as String?,
        xrayFindings: row['xray_findings'] as String?,
        doctorInstructions: row['doctor_instructions'] as String? ?? '',
        digitalSignatureToken: row['digital_signature_token'] as String? ?? '',
        riskLevel: row['risk_level'] as String? ?? 'Theo dõi định kỳ',
        prescribedMedicinesSummary:
            row['prescribed_medicines_summary'] as String?,
      );

  Map<String, Object?> _medicineItemToRow(MedicineItem value) => {
    'name': value.name,
    'category': value.category,
    'dosage': value.dosage,
    'quantity': value.quantity,
    'instruction': value.instruction,
    'warning': value.warning,
    'patient_id': value.patientId,
  };

  MedicineItem _medicineItemFromRow(Map<String, Object?> row) => MedicineItem(
    name: row['name'] as String,
    category: row['category'] as String,
    dosage: row['dosage'] as String,
    quantity: row['quantity'] as String,
    instruction: row['instruction'] as String,
    warning: row['warning'] as String?,
    patientId: row['patient_id'] as String?,
  );

  Map<String, Object?> _notificationToRow(AppNotification value) => {
    'id': value.id,
    'title': value.title,
    'body': value.body,
    'created_at': value.createdAt.toIso8601String(),
    'read': value.read ? 1 : 0,
  };

  AppNotification _notificationFromRow(Map<String, Object?> row) =>
      AppNotification(
        id: row['id'] as String,
        title: row['title'] as String,
        body: row['body'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
        read: row['read'] == 1,
      );

  Map<String, Object?> _paymentTransactionToRow(PaymentTransaction value) => {
    'id': value.id,
    'visit_code': value.visitCode,
    'description': value.description,
    'gross_amount': value.grossAmount,
    'insurance_amount': value.insuranceAmount,
    'net_amount': value.netAmount,
    'method': value.method.name,
    'status': value.status.name,
    'timestamp': value.timestamp.toIso8601String(),
    'wallet_name': value.walletName,
    'invoice_email': value.invoiceEmail,
    'receipt_code': value.receiptCode,
  };

  PaymentTransaction _paymentTransactionFromRow(Map<String, Object?> row) =>
      PaymentTransaction(
        id: row['id'] as String,
        visitCode: row['visit_code'] as String,
        description: row['description'] as String,
        grossAmount: row['gross_amount'] as int,
        insuranceAmount: row['insurance_amount'] as int,
        netAmount: row['net_amount'] as int,
        method: _paymentMethodByName(row['method'] as String?),
        status: _paymentStatusByName(row['status'] as String?),
        timestamp: DateTime.parse(row['timestamp'] as String),
        walletName: row['wallet_name'] as String?,
        invoiceEmail: row['invoice_email'] as String?,
        receiptCode: row['receipt_code'] as String?,
      );

  PaymentMethod _paymentMethodByName(String? name) {
    for (final method in PaymentMethod.values) {
      if (method.name == name) return method;
    }
    return PaymentMethod.vietQr;
  }

  PaymentStatus _paymentStatusByName(String? name) {
    for (final status in PaymentStatus.values) {
      if (status.name == name) return status;
    }
    return PaymentStatus.pending;
  }

  Map<String, Object?> _pharmacyOrderToRow(PharmacyOrder value) => {
    'id': value.id,
    'prescription_id': value.prescriptionId,
    'patient_name': value.patientName,
    'phone': value.phone,
    'delivery_address': value.deliveryAddress,
    'pharmacy_name': value.pharmacyName,
    'items_count': value.itemsCount,
    'medicine_total': value.medicineTotal,
    'shipping_fee': value.shippingFee,
    'status': value.status.name,
    'ordered_at': value.orderedAt.toIso8601String(),
    'estimated_minutes': value.estimatedMinutes,
    'patient_id': value.patientId,
  };

  PharmacyOrder _pharmacyOrderFromRow(Map<String, Object?> row) =>
      PharmacyOrder(
        id: row['id'] as String,
        prescriptionId: row['prescription_id'] as String,
        patientName: row['patient_name'] as String,
        phone: row['phone'] as String,
        deliveryAddress: row['delivery_address'] as String,
        pharmacyName: row['pharmacy_name'] as String,
        itemsCount: row['items_count'] as int,
        medicineTotal: row['medicine_total'] as int,
        shippingFee: row['shipping_fee'] as int,
        status: _pharmacyStatusByName(row['status'] as String?),
        orderedAt: DateTime.parse(row['ordered_at'] as String),
        estimatedMinutes: row['estimated_minutes'] as int,
        patientId: row['patient_id'] as String?,
      );

  PharmacyOrderStatus _pharmacyStatusByName(String? name) {
    for (final status in PharmacyOrderStatus.values) {
      if (status.name == name) return status;
    }
    return PharmacyOrderStatus.packing;
  }
}

class AuthAccount {
  const AuthAccount({
    required this.identifier,
    required this.passwordHash,
    required this.role,
    required this.displayName,
    this.patientId,
  });

  final String identifier;
  final String passwordHash;
  final UserRole role;
  final String displayName;
  final String? patientId;
}

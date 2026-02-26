import 'package:absensi_greenliving/models/attedance_models.dart';
import 'package:absensi_greenliving/models/leave_models.dart';
import 'package:absensi_greenliving/models/user_models.dart';
import 'package:absensi_greenliving/models/shift_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===========================================================================
  // 🔥 FITUR AUTO JADWAL (BATCH GENERATOR) - NEW!
  // ===========================================================================

  /// Generate Jadwal Banyak Sekaligus (Sebulan)
  /// shiftId: ID dari Master Shift (misal: 'shift_pagi', 'shift_flexi')
  Future<void> generateBulkSchedule({
    required String uid,
    required DateTime startDate,
    required DateTime endDate,
    required String shiftId, // ID Master Shift yang dipilih Admin
    List<int> offDays = const [], // Hari libur (1=Senin ... 7=Minggu)
  }) async {
    WriteBatch batch = _db.batch();
    
    DateTime current = startDate;
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      // Cek apakah hari ini libur
      if (!offDays.contains(current.weekday)) {
        String dateStr = DateFormat('yyyy-MM-dd').format(current);
        String docId = "$uid-$dateStr"; // Format: UID-TANGGAL
        
        DocumentReference docRef = _db.collection('shift_schedule').doc(docId);

        // Kita simpan referensi ke Master Shift
        batch.set(docRef, {
          'uid': uid,
          'date': dateStr,
          'shiftId': shiftId, // Nanti getTodayShift bakal baca detailnya dari sini
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      // Lanjut besok
      current = current.add(const Duration(days: 1));
    }

    // Kirim paket ke Firebase (Sekali jalan)
    await batch.commit();
  }

  /// Hapus Jadwal (Reset)
  Future<void> clearScheduleRange(String uid, DateTime start, DateTime end) async {
    WriteBatch batch = _db.batch();
    
    // Karena query range string tanggal agak tricky, kita loop aja generate ID-nya
    // Ini lebih aman dan hemat read cost (karena kita tau ID pastinya)
    DateTime current = start;
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      String dateStr = DateFormat('yyyy-MM-dd').format(current);
      String docId = "$uid-$dateStr";
      
      DocumentReference docRef = _db.collection('shift_schedule').doc(docId);
      batch.delete(docRef);
      
      current = current.add(const Duration(days: 1));
    }

    await batch.commit();
  }


  // ===========================================================================
  // ⚙️ ATTENDANCE & SHIFT LOGIC (UPDATED)
  // ===========================================================================

  // Ambil Shift Hari Ini (Updated support Flexi)
  Future<ShiftModel?> getTodayShift(String uid) async {
    try {
      // 1. Format ID: UID-YYYY-MM-DD
      String dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String scheduleDocId = "$uid-$dateStr";

      // 2. Cek di tabel jadwal user ('shift_schedule')
      DocumentSnapshot scheduleDoc = await _db
          .collection('shift_schedule')
          .doc(scheduleDocId)
          .get();

      if (!scheduleDoc.exists) {
        return null; // Gak ada jadwal / Libur
      }

      // 3. Ambil ID Master Shift (misal: 'pagi', 'flexi')
      Map<String, dynamic> scheduleData = scheduleDoc.data() as Map<String, dynamic>;
      String shiftId = scheduleData['shiftId'] ?? 'Libur'; 

      if (shiftId.toLowerCase() == 'libur') return null;

      // 4. Ambil Detail Jam dari Master 'shifts'
      DocumentSnapshot shiftMasterDoc = await _db
          .collection('shifts')
          .doc(shiftId)
          .get();

      if (shiftMasterDoc.exists) {
        Map<String, dynamic> masterData = shiftMasterDoc.data() as Map<String, dynamic>;
        
        // Parsing Jam (Handle format "08.00" atau "08:00")
        String startStr = (masterData['startTime'] as String).replaceAll('.', ':');
        String endStr = (masterData['endTime'] as String).replaceAll('.', ':');
        int tolerance = masterData['Tolerance'] ?? masterData['toleranceMinutes'] ?? 0;
        
        // 🔥 AMBIL DATA FLEXI (PENTING BUAT TUKANG SAMPAH)
        bool isFlexi = masterData['isFlexi'] ?? false;

        return ShiftModel(
          uid: uid,
          date: DateTime.now(),
          type: shiftId, // "Pagi", "Flexi", dll
          startTime: _parseTime(startStr),
          endTime: _parseTime(endStr),
          toleranceMinutes: tolerance,
          isFlexi: isFlexi, // Pass ke Model
        );
      }
      return null;
    } catch (e) {
      print("Error ambil shift: $e");
      return null;
    }
  }

  // Helper Parsing Jam String -> DateTime Hari Ini
  DateTime _parseTime(String timeString) {
    DateTime now = DateTime.now();
    try {
      String cleanTime = timeString.replaceAll('.', ':');
      List<String> parts = cleanTime.split(':');
      return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
    } catch (e) {
      // Fallback kalau format error/kosong
      return now;
    }
  }

  // Config Kantor
  Future<Map<String, dynamic>?> getOfficeConfig() async {
    try {
      DocumentSnapshot doc = await _db.collection('settings').doc('office_config').get();
      if (doc.exists) return doc.data() as Map<String, dynamic>;
      return null;
    } catch (e) {
      return null;
    }
  }

  // Config Buffer (Toleransi Waktu Absen)
  Future<int> getAttendanceBuffer() async {
    try {
      // Cek settings global
      var doc = await _db.collection('settings').doc('attendance_rules').get(); 
      if (doc.exists && doc.data() != null) {
        return doc.data()!['buffer_minutes'] ?? 60;
      }
      return 60; // Default 1 jam sebelum shift
    } catch (e) {
      return 60;
    }
  }


  // ===========================================================================
  // 📝 LOG ABSENSI (CHECK-IN / OUT)
  // ===========================================================================

  // Submit Check-In
  Future<String> submitCheckIn({required String userId, required double lat, required double lng}) async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    DocumentReference docRef = await _db.collection('attendance_logs').add({
      'uid': userId,     // Konsisten pakai 'uid' biar sama kayak user model
      'userId': userId,  // Backup field (kalau ada query lama yg pake userId)
      'date': today,
      'checkInTime': FieldValue.serverTimestamp(), // Field baru
      'checkIn': FieldValue.serverTimestamp(),     // Field lama (backup)
      'checkOut': null,
      'latitude': lat,
      'longitude': lng,
      'status': 'Hadir',
    });
    return docRef.id;
  }

  // Submit Check-Out
  Future<void> submitCheckOut({required String docId, required double lat, required double lng}) async {
    await _db.collection('attendance_logs').doc(docId).update({
      'checkOut': FieldValue.serverTimestamp(),
      'latitude_out': lat,
      'longitude_out': lng,
    });
  }

  // Cek Apakah Sudah Absen Hari Ini
  Future<DateTime?> fetchTodayCheckInTime(String uid) async {
    try {
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      var snap = await _db.collection('attendance_logs')
          .where('uid', isEqualTo: uid)
          .where('date', isEqualTo: today)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        var data = snap.docs.first.data();
        // Cek field baru dulu, kalau null cek field lama
        Timestamp? ts = data['checkInTime'] ?? data['checkIn'];
        if (ts != null) return ts.toDate();
      }
    } catch (e) {
      print("Error fetch checkin: $e");
    }
    return null;
  }

  // Cek Detail Absen (Return Map Full)
  Future<Map<String, dynamic>?> getTodayAttendanceDetail(String userId) async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      var snapshot = await _db.collection('attendance_logs')
          .where('uid', isEqualTo: userId)
          .where('date', isEqualTo: today)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var data = snapshot.docs.first.data();
        data['docId'] = snapshot.docs.first.id;
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // History Absen (Range Tanggal)
  Future<List<AttendanceModel>> getAttendanceRange(String uid, DateTime start, DateTime end) async {
    try {
      // Query raw dulu baru filter di klien (karena query range + where kadang butuh index ribet)
      final query = await _db.collection('attendance_logs')
          .where('uid', isEqualTo: uid)
          .get(); 

      List<AttendanceModel> allLogs = query.docs.map((doc) => _parseAttendance(doc)).toList();

      var filteredLogs = allLogs.where((log) {
        return log.timestamp.isAfter(start.subtract(const Duration(seconds: 1))) && 
               log.timestamp.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();

      return filteredLogs;
    } catch (e) {
      print("Error getAttendanceRange: $e");
      return [];
    }
  }

  // History User (All Time)
  Future<List<AttendanceModel>> getUserHistory(String uid, {bool newest = true}) async {
    try {
      var query = await _db.collection('attendance_logs')
          .where('uid', isEqualTo: uid) 
          .get();
      
      var list = query.docs.map((doc) => _parseAttendance(doc)).toList();

      list.sort((a, b) => newest 
          ? b.timestamp.compareTo(a.timestamp) 
          : a.timestamp.compareTo(b.timestamp));

      return list;
    } catch (e) {
      return [];
    }
  }


  // ===========================================================================
  // 👥 USERS & ADMIN FEATURES
  // ===========================================================================

  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      return null;
    } catch (e) { return null; }
  }

  Future<List<UserModel>> getAllEmployees() async {
    try {
      // Ambil selain admin (Security & Cleaner)
      var query = await _db.collection('users')
          .where('role', whereIn: ['security', 'cleaner']) 
          .get();
      return query.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  // Ambil Semua Master Shift (Buat Dropdown di Admin Panel)
  Future<List<Map<String, dynamic>>> getAllMasterShifts() async {
    try {
      QuerySnapshot snapshot = await _db.collection('shifts').get();
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; 
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Live Monitoring (Dashboard Admin)
  Future<List<Map<String, dynamic>>> getTodayScheduleWithStatus() async {
    try {
      String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // 1. Ambil Pegawai
      List<UserModel> employees = await getAllEmployees();

      // 2. Ambil Log Absen Hari Ini
      var logQuery = await _db.collection('attendance_logs')
          .where('date', isEqualTo: todayStr)
          .get();
      
      Map<String, AttendanceModel> attendanceMap = {};
      for (var doc in logQuery.docs) {
        var log = _parseAttendance(doc);
        attendanceMap[log.userId] = log;
      }

      List<Map<String, dynamic>> result = [];

      // 3. Loop Pegawai & Cek Jadwal
      for (var user in employees) {
        // Cek ID Shift dari tabel 'shift_schedule'
        String shiftDocId = "${user.uid}-$todayStr";
        var shiftDoc = await _db.collection('shift_schedule').doc(shiftDocId).get();
        
        String shiftType = "Libur";
        if (shiftDoc.exists) {
           shiftType = shiftDoc.data()?['shiftId'] ?? "Libur";
        }

        AttendanceModel? log = attendanceMap[user.uid];

        result.add({
          'user': user,
          'shift': shiftType, // ex: 'shift_pagi'
          'log': log,
        });
      }
      return result;
    } catch (e) {
      print("Error Live Monitoring: $e");
      return [];
    }
  }

  Future<Map<String, int>> getLiveMonitoringStats() async {
    try {
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Hitung total pegawai aktif (bukan admin)
      var userQuery = await _db.collection('users')
          .where('role', whereIn: ['security', 'cleaner'])
          .get();
      int totalPersonil = userQuery.docs.length;

      // Hitung yang sudah checkin tapi belum checkout (Sedang Bertugas)
      var logQuery = await _db.collection('attendance_logs')
          .where('date', isEqualTo: today)
          .get();

      int activeCount = logQuery.docs.where((doc) {
        var data = doc.data();
        return data['checkOut'] == null; // Masih aktif
      }).length;

      return {'active': activeCount, 'total': totalPersonil};
    } catch (e) {
      return {'active': 0, 'total': 0};
    }
  }


  // ===========================================================================
  // 🍃 LEAVE REQUESTS (CUTI)
  // ===========================================================================

  Future<void> submitLeaveRequest(LeaveModel request) async {
    try {
      await _db.collection('leave_requests').add(request.toMap());
    } catch (e) {
      throw Exception("Gagal kirim izin: $e");
    }
  }

  Future<List<LeaveModel>> getPendingLeaveRequests() async {
    try {
      var query = await _db.collection('leave_requests')
          .where('status', isEqualTo: 'Pending')
          .get();

      if (query.docs.isEmpty) return [];

      var list = query.docs.map((doc) => _parseLeave(doc)).toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt)); // FIFO
      return list;
    } catch (e) {
      return [];
    }
  }

  Future<void> updateLeaveStatus(String docId, String newStatus) async {
    await _db.collection('leave_requests').doc(docId).update({
      'status': newStatus
    });
  }

  Future<List<LeaveModel>> getHistoryLeaveRequests() async {
    try {
      var query = await _db.collection('leave_requests')
          .where('status', whereIn: ['Approved', 'Rejected'])
          .get();

      var list = query.docs.map((doc) => _parseLeave(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      return [];
    }
  }

  Future<int> getPendingLeaveCount() async {
    try {
      var query = await _db.collection('leave_requests')
          .where('status', isEqualTo: 'Pending')
          .get();
      return query.docs.length;
    } catch (e) { return 0; }
  }

  Future<int> getUserApprovedLeaveDays(String uid) async {
    try {
      var query = await _db.collection('leave_requests')
          .where('uid', isEqualTo: uid)
          .where('status', isEqualTo: 'Approved')
          .get();

      int totalDays = 0;
      for (var doc in query.docs) {
        var data = doc.data();
        DateTime start = (data['startDate'] as Timestamp).toDate();
        DateTime end = (data['endDate'] as Timestamp).toDate();
        int days = end.difference(start).inDays + 1;
        totalDays += days;
      }
      return totalDays;
    } catch (e) { return 0; }
  }


  LeaveModel _parseLeave(QueryDocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    DateTime safeDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return LeaveModel(
      id: doc.id, 
      uid: data['uid']?.toString() ?? '', 
      name: data['name']?.toString() ?? 'Tanpa Nama',
      type: data['type']?.toString() ?? 'Izin',
      reason: data['reason']?.toString() ?? '-',
      status: data['status']?.toString() ?? 'Pending',
      startDate: safeDate(data['startDate']),
      endDate: safeDate(data['endDate']),
      createdAt: safeDate(data['createdAt']),
    );
  }

  AttendanceModel _parseAttendance(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Prioritas: field baru 'checkInTime', lalu 'checkIn', lalu 'timestamp'
    Timestamp ts = data['checkInTime'] ?? data['checkIn'] ?? data['timestamp'] ?? Timestamp.now();
    
    return AttendanceModel(
      userId: data['uid'] ?? data['userId'] ?? '', // Handle 2 kemungkinan nama field
      timestamp: ts.toDate(),
      lat: (data['latitude'] ?? 0.0) as double,
      lng: (data['longitude'] ?? 0.0) as double,
      status: data['status'] ?? 'Hadir',
      id: doc.id,
    );
  }

//Excel Report
  Future<QuerySnapshot> getShiftsByDateRange(String startDate, String endDate) async {
    return await _db.collection('shift_schedule')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .get();
  }

  Future<QuerySnapshot> getAttendanceByDateRange(String startDate, String endDate) async {
    return await _db.collection('attendance_logs')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .get();
  }

Future<QuerySnapshot> getApprovedLeaves() async {
  return await _db.collection('leave_requests')
      .where('status', isEqualTo: 'Approved') 
      .get();
}
}
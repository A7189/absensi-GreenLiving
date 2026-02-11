import 'package:absensi_greenliving/models/attedance_models.dart';
import 'package:absensi_greenliving/models/leave_models.dart';
import 'package:absensi_greenliving/models/user_models.dart';
import 'package:absensi_greenliving/models/shift_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getOfficeConfig() async {
    try {
      DocumentSnapshot doc = await _db.collection('settings').doc('office_config').get();
      if (doc.exists) return doc.data() as Map<String, dynamic>;
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<AttendanceModel>> getAttendanceRange(String uid, DateTime start, DateTime end) async {
    try {
      final query = await _db.collection('attendance_logs')
          .where('userId', isEqualTo: uid)
          .get(); 

      List<AttendanceModel> allLogs = query.docs.map((doc) {
        final data = doc.data();
        Timestamp ts = data['checkIn'] ?? data['timestamp'];

        return AttendanceModel(
          userId: data['userId'],
          timestamp: ts.toDate(),
          lat: (data['latitude'] ?? 0.0) as double,
          lng: (data['longitude'] ?? 0.0) as double,
          status: data['status'] ?? 'Hadir', 
          id: doc.id,
        );
      }).toList();

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

  // Cek Status Absen Hari Ini (Detail)
  Future<Map<String, dynamic>?> getTodayAttendanceDetail(String userId) async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      var snapshot = await _db.collection('attendance_logs')
          .where('userId', isEqualTo: userId)
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

  // Submit Check-In
  Future<String> submitCheckIn({required String userId, required double lat, required double lng}) async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    DocumentReference docRef = await _db.collection('attendance_logs').add({
      'userId': userId,
      'date': today,
      'checkIn': FieldValue.serverTimestamp(),
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

  // History Per User
  Future<List<AttendanceModel>> getUserHistory(String uid, {bool newest = true}) async {
    try {
      var query = await _db.collection('attendance_logs')
          .where('userId', isEqualTo: uid) 
          .get();
      
      var list = query.docs.map((doc) => _parseAttendance(doc)).toList();

      list.sort((a, b) => newest 
          ? b.timestamp.compareTo(a.timestamp) 
          : a.timestamp.compareTo(b.timestamp));

      return list;
    } catch (e) {
      print("Error user history: $e");
      return [];
    }
  }

  // All History (Admin)
  Future<List<AttendanceModel>> getAllAttendanceLogs({bool isDescending = true}) async {
    try {
      var query = await _db.collection('attendance_logs').get();
      var list = query.docs.map((doc) => _parseAttendance(doc)).toList();
      
      list.sort((a, b) => isDescending 
          ? b.timestamp.compareTo(a.timestamp) 
          : a.timestamp.compareTo(b.timestamp));

      return list;
    } catch (e) {
      return [];
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      return null;
    } catch (e) { return null; }
  }

  Future<List<UserModel>> getAllEmployees() async {
    try {
      var query = await _db.collection('users')
          .where('role', isEqualTo: 'security') 
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

  // === INI FUNGSI GET TODAY SHIFT ASLI LU (Pake shift_schedule) ===
  Future<ShiftModel?> getTodayShift(String uid) async {
    try {
      // 1. Format ID: UID-YYYY-MM-DD
      String dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String scheduleDocId = "$uid-$dateStr";

      // 2. Tembak Collection Root 'shift_schedule'
      DocumentSnapshot scheduleDoc = await _db
          .collection('shift_schedule')
          .doc(scheduleDocId)
          .get();

      if (!scheduleDoc.exists) {
        return null; // Libur / Gak ada jadwal
      }

      // 3. Ambil shiftId
      Map<String, dynamic> scheduleData = scheduleDoc.data() as Map<String, dynamic>;
      String shiftId = scheduleData['shiftId'] ?? 'Libur'; 

      if (shiftId.toLowerCase() == 'libur') return null;

      // 4. Ambil Detail dari Master 'shifts'
      DocumentSnapshot shiftMasterDoc = await _db
          .collection('shifts')
          .doc(shiftId)
          .get();

      if (shiftMasterDoc.exists) {
        Map<String, dynamic> masterData = shiftMasterDoc.data() as Map<String, dynamic>;
        
        // Handle format jam pake titik (.) jadi titik dua (:)
        String startStr = (masterData['startTime'] as String).replaceAll('.', ':');
        String endStr = (masterData['endTime'] as String).replaceAll('.', ':');
        int tolerance = masterData['Tolerance'] ?? 0;

        return ShiftModel(
          uid: uid,
          date: DateTime.now(),
          type: shiftId,
          startTime: _parseTime(startStr),
          endTime: _parseTime(endStr),
          toleranceMinutes: tolerance, 
        );
      }
      return null;
    } catch (e) {
      print("Error ambil shift: $e");
      return null;
    }
  }

  // Cek ID Shift Harian (Simple return String)
  Future<String?> getDailyShift(String uid, DateTime date) async {
    try {
      String dateStr = DateFormat('yyyy-MM-dd').format(date);
      String docId = "$uid-$dateStr"; 
      
      var doc = await _db.collection('shift_schedule').doc(docId).get();
      
      if (doc.exists) {
        return doc.data()?['shiftId']; 
      }
      return null; 
    } catch (e) {
      return null;
    }
  }

  // Ambil Semua Master Shift (Pagi, Siang, Malam)
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

  // Live Monitoring
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

      // 3. Loop Pegawai & Cek Jadwal Baru
      for (var user in employees) {
        // Cek Jadwal Harian via getDailyShift
        String? shiftId = await getDailyShift(user.uid, DateTime.now());
        String shiftType = shiftId ?? "Libur";

        if (shiftType == 'Libur') continue;

        AttendanceModel? log = attendanceMap[user.uid];

        result.add({
          'user': user,
          'shift': shiftType,
          'log': log,
        });
      }
      return result;
    } catch (e) {
      print("Error Live Monitoring: $e");
      return [];
    }
  }

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

  Future<Map<String, int>> getLiveMonitoringStats() async {
    try {
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      var userQuery = await _db.collection('users').where('role', isEqualTo: 'security').get();
      int totalPersonil = userQuery.docs.length;

      var logQuery = await _db.collection('attendance_logs')
          .where('date', isEqualTo: today)
          .get();

      int activeCount = logQuery.docs.where((doc) {
        var data = doc.data();
        return data['checkOut'] == null;
      }).length;

      return {'active': activeCount, 'total': totalPersonil};
    } catch (e) {
      return {'active': 0, 'total': 0};
    }
  }

  // --- HELPER FUNCTIONS ---

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
    Timestamp ts = data['checkIn'] ?? data['timestamp'] ?? Timestamp.now();
    
    return AttendanceModel(
      userId: data['userId'] ?? '',
      timestamp: ts.toDate(),
      lat: (data['latitude'] ?? 0.0) as double,
      lng: (data['longitude'] ?? 0.0) as double,
      status: data['status'] ?? 'Hadir',
      id: doc.id,
    );
  }

  DateTime _parseTime(String timeString) {
    DateTime now = DateTime.now();
    try {
      String cleanTime = timeString.replaceAll('.', ':');
      List<String> parts = cleanTime.split(':');
      return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
    } catch (e) {
      return now;
    }
  }

  // 🔥 FUNGSI BUFFER INI GUA MASUKIN KE DALAM BIAR GAK ERROR
  Future<int> getAttendanceBuffer() async {
    try {
      var doc = await _db.collection('settings').doc('attendance_rules').get(); 
      if (doc.exists && doc.data() != null) {
        return doc.data()!['buffer_minutes'] ?? 60;
      }
      return 60; 
    } catch (e) {
      print("Error getAttendanceBuffer: $e");
      return 60;
    }
  }

}
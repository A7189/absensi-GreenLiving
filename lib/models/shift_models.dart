import 'package:cloud_firestore/cloud_firestore.dart';

class ShiftModel {
  final String uid;       // ID Satpam
  final DateTime date;    // Tanggal Jadwal (Base Date)
  final String type;      // "Pagi", "Siang", "Malam", "Libur"
  
  // 🔥 FIELD BARU: TOLERANSI (Menit)
  final int toleranceMinutes; 
  
  // Jam Spesifik
  final DateTime startTime; 
  final DateTime endTime;

  ShiftModel({
    required this.uid,
    required this.date,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.toleranceMinutes, 
  });


  factory ShiftModel.fromMap(Map<String, dynamic> data) {
    return ShiftModel(
      uid: data['uid'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      type: data['type'] ?? 'Libur',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      
    
      toleranceMinutes: data['toleranceMinutes'] ?? data['Tolerance'] ?? 0,
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'date': Timestamp.fromDate(date),
      'type': type,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'toleranceMinutes': toleranceMinutes, 
    };
  }
}
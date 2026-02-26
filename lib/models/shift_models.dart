import 'package:cloud_firestore/cloud_firestore.dart';

class ShiftModel {
  final String uid;      
  final DateTime date;   
  final String type;   
  
  final int toleranceMinutes; 
  
  // Jam Spesifik
  final DateTime startTime; 
  final DateTime endTime;

  final bool isFlexi; 

  ShiftModel({
    required this.uid,
    required this.date,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.toleranceMinutes,
    this.isFlexi = false, 
  });

  factory ShiftModel.fromMap(Map<String, dynamic> data) {
    return ShiftModel(
      uid: data['uid'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      type: data['type'] ?? 'Libur',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      toleranceMinutes: data['toleranceMinutes'] ?? data['Tolerance'] ?? 0,
      
      isFlexi: data['isFlexi'] ?? false, 
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
      'isFlexi': isFlexi, 
    };
  }
}
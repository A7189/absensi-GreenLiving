import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String userId;
  final DateTime timestamp;
  final double lat;
  final double lng;
  final String status;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.lat,
    required this.lng,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'lat': lat,
      'lng': lng,
      'status': status,
    };
  }
}
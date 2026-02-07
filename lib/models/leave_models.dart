

class LeaveModel {
  String? id;
  final String uid;    // Sesuai SS
  final String name;   // Sesuai SS
  final String type;
  final String reason;
  final String status;
  final DateTime startDate; // Sesuai SS
  final DateTime endDate;   // Sesuai SS
  final DateTime createdAt;

  LeaveModel({
    this.id,
    required this.uid,
    required this.name,
    required this.type,
    required this.reason,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id, // Bisa null kalau auto-generated
      'uid': uid,
      'name': name,
      'type': type,
      'reason': reason,
      'status': status,
      'startDate': startDate, // Firestore otomatis convert DateTime ke Timestamp
      'endDate': endDate,
      'createdAt': createdAt,
    };
  }
}
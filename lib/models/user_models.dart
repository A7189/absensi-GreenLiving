import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 Import ini penting buat Timestamp

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final DateTime joinDate;
  // 🔥 Field officeLat & officeLng DIHAPUS

  static const String roleAdmin = 'admin';
  static const String roleSecurity = 'security';
  static const String roleCleaner = 'cleaner';

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.joinDate,
  });

  String get roleDisplayName {
    switch (role) {
      case roleSecurity: return 'Satpam';
      case roleCleaner:  return 'Petugas Kebersihan';
      case roleAdmin:    return 'Administrator';
      default:           return 'Karyawan';
    }
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // 🔥 LOGIC PARSING TANGGAL ANTI-ERROR
    DateTime parsedDate;
    try {
      if (map['joinDate'] is Timestamp) {
        parsedDate = (map['joinDate'] as Timestamp).toDate();
      } else if (map['joinDate'] is String) {
        parsedDate = DateTime.parse(map['joinDate']);
      } else {
        parsedDate = DateTime.now(); // Default kalau null/error
      }
    } catch (e) {
      parsedDate = DateTime.now();
    }

    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? 'No Name',
      email: map['email'] ?? '',
      role: map['role'] ?? 'employee',
      joinDate: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'joinDate': joinDate.toIso8601String(),
    };
  }
}
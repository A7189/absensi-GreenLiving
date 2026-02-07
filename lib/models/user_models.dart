class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final DateTime joinDate;
  final double officeLat;
  final double officeLng;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.joinDate,
    required this.officeLat,
    required this.officeLng,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      name: map['name'],
      email: map['email'] ?? '',
      role: map['role'],
      joinDate: map['joinDate'] is String 
          ? DateTime.parse(map['joinDate']) 
          : (map['joinDate'] as DateTime),
      officeLat: (map['officeLat'] as num).toDouble(),
      officeLng: (map['officeLng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'joinDate': joinDate.toIso8601String(),
      'officeLat': officeLat,
      'officeLng': officeLng,
    };
  }
}
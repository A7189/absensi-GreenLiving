import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Gunakan r kecil: register
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      // 1. Buat user di Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Simpan profil tambahan ke Firestore
      if (userCredential.user != null) {
        await _db.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'name': name,
          'email': email,
          'role': role, // 'admin' atau 'security'
          'joinDate': DateTime.now().toIso8601String(), // Penting buat hitung siklus 2-2-2-1
          'officeLat': -7.9666, // Default Malang (Ganti sesuai lokasi proyek)
          'officeLng': 112.6326,
        });
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Fungsi login yang sudah kita bahas sebelumnya
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      rethrow;
    }
  }
}
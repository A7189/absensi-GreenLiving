import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart'; 

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔥 REGISTER UPDATED (Terima Parameter joinDate)
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String role,
    required DateTime joinDate, // <--- TAMBAHAN: Tanggal Bergabung
  }) async {
    FirebaseApp? secondaryApp;

    try {
      // 1. Inisialisasi App Bayangan (Biar Admin Gak Ke-Logout)
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options, 
      );

      // 2. Create User di Auth Secondary
      UserCredential userCredential = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 3. Simpan Data ke Firestore
      if (userCredential.user != null) {
        String uid = userCredential.user!.uid;

        await _db.collection('users').doc(uid).set({
          'uid': uid,
          'name': name,
          'email': email,
          'role': role, 
          
          // 🔥 PENTING: Simpan Tanggal Pilihan Admin
          'joinDate': joinDate.toIso8601String(), 
        });
      }

      // 4. Bersih-bersih
      await secondaryApp.delete();

    } catch (e) {
      await secondaryApp?.delete();
      rethrow;
    }
  }

  // ... Login & Logout sama aja
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

  Future<void> logout() async {
    await _auth.signOut();
  }
}
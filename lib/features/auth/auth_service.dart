import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lamsa/features/owner_dashboard/model/bank_account_model.dart';
import 'package:lamsa/features/owner_dashboard/model/salon_model.dart';
import 'package:lamsa/features/owner_dashboard/model/service_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();


  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
    required String salonName,    // اسم الصالون
    required String phone,        // رقم الهاتف
    required String location,     // الموقع
    required String workingHours, // ساعات العمل
    required List<Service> services,  // الخدمات المقدمة
    required List<BankAccount> bankAccounts, // الحسابات البنكية
  }) async {
    try {
      // إنشاء المستخدم في Firebase Authentication
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        // تخزين بيانات المستخدم في Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // إضافة بيانات الصالون إلى Firestore وربطها بالـ uid الخاص بالمالك
        final salonDocRef = _firestore.collection('salons').doc(user.uid);

        // إضافة بيانات الصالون إلى مستند الصالون
        await salonDocRef.set({
          'salonName': salonName,
          'phone': phone,
          'email': email,
          'location': location,
          'workingHours': workingHours,
          'ownerUid': user.uid, // ربط الصالون بالمالك باستخدام الـ uid
          'createdAt': FieldValue.serverTimestamp(),
        });

        // تخزين الخدمات كـ subcollection
        for (var service in services) {
          await salonDocRef.collection('services').add(service.toMap());
        }

        // تخزين الحسابات البنكية كـ subcollection
        for (var account in bankAccounts) {
          await salonDocRef.collection('bankAccounts').add(account.toMap());
        }

      }
    } catch (e) {
      print("Error during sign up: $e");
      throw Exception("Sign up failed. Please try again.");
    }
  }


  Future<void> signIn({ required String email, required String password }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      String errorMessage = 'حدث خطأ أثناء تسجيل الدخول. حاول مرة أخرى.';

      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          errorMessage = 'البريد الإلكتروني غير مسجل';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'كلمة المرور غير صحيحة';
        }
      }

      throw Exception(errorMessage);  // هنا نرمي الاستثناء برسالة مفهومة للمستخدم
    }
  }


  Future<String?> getUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return doc.data()?['role'];
  }


  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<SalonModel?> getSalonData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('salons').doc(user.uid).get();
      if (!doc.exists) return null;

      return SalonModel.fromMap(doc.data()!);
    } catch (e) {
      print("Error retrieving salon data: $e");
      return null;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error sending password reset email: $e');
      // يمكنك معالجة الخطأ هنا أو إظهار رسالة للمستخدم
    }
  }

  Future<void> updateSalonPhone(String newPhone) async {
    // هنا يتم تحديث الرقم في قاعدة بيانات Firebase
    try {
      // رمز تحديث الرقم في Firebase
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final salonRef = FirebaseFirestore.instance.collection('salons').doc(userId);
      await salonRef.update({
        'phone': newPhone,
      });
    } catch (e) {
      print("Error updating phone number: $e");
    }
  }

}


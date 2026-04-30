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

  String get currentUserEmail => currentUser?.email ?? "";

  Future<void> customerSignUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'role': 'customer',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (e) {
      throw Exception('Customer sign up failed: $e');
    }
  }

  // =========================
  // Owner Sign Up
  // =========================
  Future<void> ownerSignUp({
    required String name,
    required String email,
    required String password,
    required String salonName,
    required String phone,
    required String location,
    required String workingHours,
    required List<Service> services,
    required List<BankAccount> bankAccounts,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'role': 'owner',
          'createdAt': FieldValue.serverTimestamp(),
        });

        final salonDocRef = _firestore.collection('salons').doc(user.uid);

        await salonDocRef.set({
          'ownerUid': user.uid,
          'salonName': salonName,
          'phone': phone,
          'location': location,
          'workingHours': workingHours,
          'createdAt': FieldValue.serverTimestamp(),
        });

        for (var service in services) {
          await salonDocRef.collection('services').add(service.toMap());
        }

        for (var account in bankAccounts) {
          await salonDocRef.collection('bank_accounts').add(account.toMap());
        }
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (e) {
      throw Exception('Owner sign up failed: $e');
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      default:
        return e.message ?? 'Authentication error occurred.';
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
        } else if (e.code == 'invalid-credential') {
          errorMessage = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'صيغة البريد الإلكتروني غير صحيحة';
        }
      }

      throw Exception(errorMessage);  // هنا نرمي الاستثناء برسالة مفهومة للمستخدم
    }
  }


  Future<String?> getUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    print("UID: ${user.uid}");

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    print("DOC EXISTS: ${doc.exists}");
    print("DATA: ${doc.data()}");

    return doc.data()?['role'];
  }


  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<SalonModel?> getSalonData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final salonDoc = await _firestore.collection('salons').doc(user.uid).get();

      if (!salonDoc.exists) {
        print("Salon document does not exist");
        return null;
      }

      final servicesSnapshot = await _firestore
          .collection('salons')
          .doc(user.uid)
          .collection('services')
          .get();

      final bankAccountsSnapshot = await _firestore
          .collection('salons')
          .doc(user.uid)
          .collection('bank_accounts')
          .get();

      final services = servicesSnapshot.docs
          .map((doc) => Service.fromMap(doc.id, doc.data()))
          .toList();

      final bankAccounts = bankAccountsSnapshot.docs
          .map((doc) => BankAccount.fromMap(doc.id, doc.data()))
          .toList();

      final data = salonDoc.data()!;

      // print("Salon data: $data");
      // print("Services count: ${services.length}");
      // print("Bank accounts count: ${bankAccounts.length}");

      return SalonModel(
        id: salonDoc.id,
        salonName: data['salonName'] ?? '',
        phone: data['phone'] ?? '',
        email: data['email'] ?? '',
        location: data['location'] ?? '',
        workingHours: data['workingHours'] ?? '',
        ownerUid: data['ownerUid'] ?? user.uid,
        services: services,
        bankAccounts: bankAccounts,
      );
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


  Future<void> updateSalonField({
    required String fieldName,
    required String newValue,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception("User not logged in");

      final salonRef = FirebaseFirestore.instance.collection('salons').doc(userId);

      await salonRef.update({
        fieldName: newValue,
      });
    } catch (e) {
      print("Error updating salon field: $e");
    }
  }

  Future<void> addSingleService({
    required String name,
    required double price,
  }) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception("User not logged in.");
      }

      final salonDocRef = _firestore.collection('salons').doc(user.uid);

      await salonDocRef.collection('services').add({
        'name': name,
        'price': price,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error adding service: $e");
      throw Exception("فشل في إضافة الخدمة");
    }
  }

  Future<void> updateServiceById({
    required String docId,
    required String newName,
    required double newPrice,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception("User not logged in");

      final serviceRef = FirebaseFirestore.instance
          .collection('salons')
          .doc(userId)
          .collection('services')
          .doc(docId);

      await serviceRef.update({
        'name': newName,
        'price': newPrice,
      });
    } catch (e) {
      print("Error updating service: $e");
    }
  }


  Future<void> addSingleBankAccount({
    required String bankName,
    required int accountNumber,
    required String accountHolder,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("User not logged in.");
      }

      final salonDocRef =
      FirebaseFirestore.instance.collection('salons').doc(user.uid);

      await salonDocRef.collection('bank_accounts').add({
        'bankName': bankName,
        'accountNumber': accountNumber,
        'accountHolder': accountHolder,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error adding bank account: $e");
      throw Exception("فشل في إضافة الحساب البنكي");
    }
  }

  Future<void> updateBankAccountById({
    required String docId,
    required String bankName,
    required int accountNumber,
    required String accountHolder,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception("User not logged in");

      final bankAccountRef = FirebaseFirestore.instance
          .collection('salons')
          .doc(userId)
          .collection('bank_accounts')
          .doc(docId);

      await bankAccountRef.update({
        'bankName': bankName,
        'accountNumber': accountNumber,
        'accountHolder': accountHolder,
      });
    } catch (e) {
      print("Error updating bank account: $e");
    }
  }



  // دالة لإضافة بيانات الصالون في Firestore
  Future<void> addSalonData({
    required String salonName,
    required String phone,
    required String location,
    required String workingHours,
    required List<Service> services,
    required List<BankAccount> bankAccounts,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in.");
      }

      // إضافة بيانات الصالون إلى Firestore
      final salonDocRef = _firestore.collection('salons').doc(user.uid);

      // تخزين بيانات الصالون
      await salonDocRef.set({
        'salonName': salonName,
        'phone': phone,
        'email': user.email ?? '',
        'location': location,
        'workingHours': workingHours,
        'ownerUid': user.uid,  // ربط الصالون بالمالك باستخدام الـ uid
        'createdAt': FieldValue.serverTimestamp(),
      });

      // تخزين الخدمات كـ subcollection
      for (var service in services) {
        await salonDocRef.collection('services').add(service.toMap());
      }

      // تخزين الحسابات البنكية كـ subcollection
      for (var account in bankAccounts) {
        await salonDocRef.collection('bank_accounts').add(account.toMap());
      }

    } catch (e) {
      print("Error during salon data addition: $e");
      throw Exception("Failed to add salon data. Please try again.");
    }
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lamsa/features/customer_dashboard/view/pages/customer_navigation_screen.dart';
import 'package:lamsa/features/owner_dashboard/model/bank_account_model.dart';

class PaymentController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController receiptController =
  TextEditingController();

  final GlobalKey<FormState> formKey =
  GlobalKey<FormState>();

  bool isLoading = false;

  String? selectedBankAccountId;
  BankAccount? selectedBankAccount;

  DocumentReference<Map<String, dynamic>> bookingRef(
      String bookingId,
      ) {
    return _firestore
        .collection('bookings')
        .doc(bookingId);
  }

  Stream<List<BankAccount>> bankAccountsStream(
      String salonId,
      ) {
    return _firestore
        .collection('salons')
        .doc(salonId)
        .collection('bank_accounts')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) {
        final data = doc.data();
        return data['isActive'] != false;
      })
          .map((doc) {
        return BankAccount.fromMap(
          doc.id,
          doc.data(),
        );
      })
          .toList();
    });
  }

  void selectBankAccount(BankAccount account) {
    selectedBankAccountId = account.id;
    selectedBankAccount = account;

    notifyListeners();
  }

  Future<void> uploadReceiptNumber({
    required BuildContext context,
    required String bookingId,
  }) async {

    // تحقق من أن المستخدم صاحب الحجز
    final doc = await bookingRef(bookingId).get();
    if (!doc.exists) {
      throw Exception('الحجز غير موجود');
    }
    if (doc.data()!['customerId'] != FirebaseAuth.instance.currentUser!.uid) {
      throw Exception('ليس لديك صلاحية تعديل هذا الحجز');
    }

    FocusScope.of(context).unfocus();

    if (!formKey.currentState!.validate()) return;

    if (selectedBankAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار الحساب البنكي'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      // تعريف بيانات التحديث
      Map<String, dynamic> updateData = {
        'paymentMethod': 'Bank Accounts',
        'paymentStatus': 'paid',
        'bankReceiptNumber': receiptController.text.trim(),
        'selectedBankAccountId': selectedBankAccount!.id,
        'selectedBankName': selectedBankAccount!.bankName,
        'selectedAccountNumber': selectedBankAccount!.accountNumber,
        'selectedAccountHolder': selectedBankAccount!.accountHolder,
        'receiptUploadedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // استخدام set مع merge لتجنب مشاكل diff
      await bookingRef(bookingId).set(updateData, SetOptions(merge: true));

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تأكيد الدفع بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 700));

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const CustomerNavigationScreen(initialIndex: 1),
        ),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء رفع رقم السند: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    receiptController.dispose();
    super.dispose();
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lamsa/features/customer_dashboard/view/pages/customer_navigation_screen.dart';
import 'package:lamsa/features/customer_dashboard/view/pages/my_bookings.dart';

// غيّر هذا المسار حسب مكان ملف BankAccount عندك
import 'package:lamsa/features/owner_dashboard/model/bank_account_model.dart';

class PaymentPage extends StatefulWidget {
  final String bookingId;

  const PaymentPage({
    super.key,
    required this.bookingId,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const String bookingsCollection = 'bookings';
  static const String salonsCollection = 'salons';
  static const String bankAccountsSubCollection = 'bank_accounts';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _receiptController = TextEditingController();

  bool _isLoading = false;

  String? _selectedBankAccountId;
  BankAccount? _selectedBankAccount;

  @override
  void dispose() {
    _receiptController.dispose();
    super.dispose();
  }

  DocumentReference<Map<String, dynamic>> get _bookingRef {
    return FirebaseFirestore.instance
        .collection(bookingsCollection)
        .doc(widget.bookingId);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _bookingStream() {
    return _bookingRef.snapshots();
  }

  Stream<List<BankAccount>> _bankAccountsStream(String salonId) {
    return FirebaseFirestore.instance
        .collection(salonsCollection)
        .doc(salonId)
        .collection(bankAccountsSubCollection)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) {
        final data = doc.data();

        // إذا عندك isActive في Firestore سيستخدمها
        // وإذا غير موجودة سيعرض الحساب طبيعي
        return data['isActive'] != false;
      })
          .map((doc) {
        return BankAccount.fromMap(doc.id, doc.data());
      })
          .toList();
    });
  }

  Future<void> _uploadReceiptNumber({
    required String salonId,
  }) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBankAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار الحساب البنكي'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _bookingRef.update({
        'paymentMethod': 'Bank Accounts',
        'paymentStatus': 'pending',
        'bankReceiptNumber': _receiptController.text.trim(),
        'selectedBankAccountId': _selectedBankAccount!.id,
        'selectedBankName': _selectedBankAccount!.bankName,
        'selectedAccountNumber': _selectedBankAccount!.accountNumber,
        'selectedAccountHolder': _selectedBankAccount!.accountHolder,
        'receiptUploadedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تأكيد الدفع بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const CustomerNavigationScreen(initialIndex: 1),
        ),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء رفع رقم السند: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _bankAccountsSection(String salonId) {
    return StreamBuilder<List<BankAccount>>(
      stream: _bankAccountsStream(salonId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'حدث خطأ أثناء تحميل الحسابات البنكية',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final bankAccounts = snapshot.data ?? [];

        if (bankAccounts.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'لا توجد حسابات بنكية لهذا الصالون حالياً',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          );
        }

        return Column(
          children: bankAccounts.map((account) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: RadioListTile<String>(
                value: account.id,
                groupValue: _selectedBankAccountId,
                onChanged: (value) {
                  setState(() {
                    _selectedBankAccountId = value;
                    _selectedBankAccount = account;
                  });
                },
                title: Text(
                  account.bankName.isEmpty ? 'حساب بنكي' : account.bankName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (account.accountHolder.isNotEmpty)
                        _bankInfoRow(
                          title: 'صاحب الحساب',
                          value: account.accountHolder,
                        ),
                      _bankInfoRow(
                        title: 'رقم الحساب',
                        value: account.accountNumber.toString(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _bankInfoRow({
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptTextField() {
    return TextFormField(
      controller: _receiptController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'رقم السند',
        hintText: 'اكتب رقم السند هنا',
        prefixIcon: const Icon(Icons.receipt_long),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      validator: (value) {
        final receiptNumber = value?.trim() ?? '';

        if (receiptNumber.isEmpty) {
          return 'الرجاء كتابة رقم السند';
        }

        if (receiptNumber.length < 9) {
          return 'رقم السند قصير جداً';
        }

        return null;
      },
    );
  }

  Widget _confirmButton(String salonId) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () {
          _uploadReceiptNumber(salonId: salonId);
        },
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Text(
          'تأكيد الدفع',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _paymentBody(String salonId) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'الحسابات البنكية',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'قومي بتحويل المبلغ إلى أحد حسابات الصالون التالية، ثم اكتبي رقم السند لتأكيد الدفع.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 20),

              _bankAccountsSection(salonId),

              const SizedBox(height: 20),

              _receiptTextField(),

              const SizedBox(height: 24),

              _confirmButton(salonId),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('صفحة الدفع'),
          centerTitle: true,
        ),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _bookingStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'حدث خطأ أثناء تحميل بيانات الحجز',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text('الحجز غير موجود'),
              );
            }

            final bookingData = snapshot.data!.data();

            final salonId = bookingData?['salonId']?.toString() ?? '';

            if (salonId.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'لا يوجد salonId داخل بيانات الحجز',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            return _paymentBody(salonId);
          },
        ),
      ),
    );
  }
}
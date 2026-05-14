import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lamsa/features/customer_dashboard/controller/payment_controller.dart';
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
  final PaymentController controller = PaymentController();

  @override
  void initState() {
    super.initState();

    controller.addListener(_controllerListener);
  }

  void _controllerListener() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    controller.removeListener(_controllerListener);
    controller.dispose();
    super.dispose();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _bookingStream() {
    return controller
        .bookingRef(widget.bookingId)
        .snapshots();
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

  Widget _bankAccountsSection(String salonId) {
    return StreamBuilder<List<BankAccount>>(
      stream: controller.bankAccountsStream(salonId),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
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
                style: TextStyle(
                  color: Colors.red,
                ),
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
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),
            ),
          );
        }

        return Column(
          children: bankAccounts.map((account) {
            return Card(
              margin: const EdgeInsets.only(
                bottom: 12,
              ),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(14),
              ),
              child: RadioListTile<String>(
                value: account.id,
                groupValue:
                controller.selectedBankAccountId,
                onChanged: (value) {
                  controller.selectBankAccount(
                    account,
                  );
                },
                title: Text(
                  account.bankName.isEmpty
                      ? 'حساب بنكي'
                      : account.bankName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Padding(
                  padding:
                  const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      if (account
                          .accountHolder.isNotEmpty)
                        _bankInfoRow(
                          title: 'صاحب الحساب',
                          value:
                          account.accountHolder,
                        ),
                      _bankInfoRow(
                        title: 'رقم الحساب',
                        value: account
                            .accountNumber
                            .toString(),
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

  Widget _receiptTextField() {
    return TextFormField(
      controller: controller.receiptController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'رقم السند',
        hintText: 'اكتب رقم السند هنا',
        prefixIcon:
        const Icon(Icons.receipt_long),
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(14),
        ),
      ),
      validator: (value) {
        final receiptNumber =
            value?.trim() ?? '';

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

  Widget _confirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: controller.isLoading
            ? null
            : () {
          controller
              .uploadReceiptNumber(
            context: context,
            bookingId:
            widget.bookingId,
          );
        },
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(14),
          ),
        ),
        child: controller.isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child:
          CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Text(
          'تأكيد الدفع',
          style: TextStyle(
            fontSize: 16,
            fontWeight:
            FontWeight.bold,
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
          key: controller.formKey,
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'الحسابات البنكية',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                  FontWeight.bold,
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

              _confirmButton(),
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
        body: StreamBuilder<
            DocumentSnapshot<
                Map<String, dynamic>>>(
          stream: _bookingStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child:
                CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'حدث خطأ أثناء تحميل بيانات الحجز',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
              );
            }

            if (!snapshot.hasData ||
                !snapshot.data!.exists) {
              return const Center(
                child: Text(
                  'الحجز غير موجود',
                ),
              );
            }

            final bookingData =
            snapshot.data!.data();

            final salonId = bookingData?[
            'salonId']
                ?.toString() ??
                '';

            if (salonId.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'لا يوجد salonId داخل بيانات الحجز',
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ),
              );
            }

            return _paymentBody(
              salonId,
            );
          },
        ),
      ),
    );
  }
}
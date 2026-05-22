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
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_controllerListener);
    controller.dispose();
    super.dispose();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _bookingStream() {
    return controller.bookingRef(widget.bookingId).snapshots();
  }

  Widget _paymentBody(String salonId) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PaymentHeader(),

              const SizedBox(height: 20),

              const _SectionTitle(
                title: 'اختاري الحساب البنكي',
                icon: Icons.account_balance,
              ),

              const SizedBox(height: 12),

              _bankAccountsSection(salonId),

              const SizedBox(height: 22),

              const _SectionTitle(
                title: 'رقم السند',
                icon: Icons.receipt_long,
              ),

              const SizedBox(height: 12),

              _receiptTextField(),

              const SizedBox(height: 16),

              const _NoteCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bankAccountsSection(String salonId) {
    return StreamBuilder<List<BankAccount>>(
      stream: controller.bankAccountsStream(salonId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return const _MessageCard(
            icon: Icons.error_outline,
            message: 'حدث خطأ أثناء تحميل الحسابات البنكية',
            isError: true,
          );
        }

        final bankAccounts = snapshot.data ?? [];

        if (bankAccounts.isEmpty) {
          return const _MessageCard(
            icon: Icons.account_balance_wallet_outlined,
            message: 'لا توجد حسابات بنكية لهذا الصالون حالياً',
          );
        }

        return Column(
          children: bankAccounts.map((account) {
            final isSelected = controller.selectedBankAccountId == account.id;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => controller.selectBankAccount(account),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: account.id,
                        groupValue: controller.selectedBankAccountId,
                        onChanged: (_) => controller.selectBankAccount(account),
                      ),

                      const SizedBox(width: 6),

                      CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.12),
                        child: Icon(
                          Icons.account_balance,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.bankName.isEmpty
                                  ? 'حساب بنكي'
                                  : account.bankName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            const SizedBox(height: 8),

                            if (account.accountHolder.isNotEmpty)
                              _BankInfoText(
                                title: 'صاحب الحساب',
                                value: account.accountHolder,
                              ),

                            _BankInfoText(
                              title: 'رقم الحساب',
                              value: account.accountNumber.toString(),
                            ),
                          ],
                        ),
                      ),

                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
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
      textDirection: TextDirection.ltr,
      decoration: const InputDecoration(
        labelText: 'رقم السند',
        hintText: 'اكتبي رقم السند هنا',
        prefixIcon: Icon(Icons.receipt_long),
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

  Widget _confirmButton() {
    return ElevatedButton(
      onPressed: controller.isLoading
          ? null
          : () {
        controller.uploadReceiptNumber(
          context: context,
          bookingId: widget.bookingId,
        );
      },
      child: controller.isLoading
          ? const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      )
          : const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'تأكيد الدفع',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _bookingStream(),
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

          return Scaffold(
            appBar: AppBar(
              title: const Text('صفحة الدفع'),
            ),
            bottomNavigationBar: isLoading ||
                snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data?.exists != true
                ? null
                : Padding(
              padding: const EdgeInsets.all(16),
              child: _confirmButton(),
            ),
            body: Builder(
              builder: (context) {
                if (isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const _MessageCard(
                    icon: Icons.error_outline,
                    message: 'حدث خطأ أثناء تحميل بيانات الحجز',
                    isError: true,
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const _MessageCard(
                    icon: Icons.search_off,
                    message: 'الحجز غير موجود',
                  );
                }

                final bookingData = snapshot.data!.data();
                final salonId = bookingData?['salonId']?.toString() ?? '';

                if (salonId.isEmpty) {
                  return const _MessageCard(
                    icon: Icons.warning_amber_rounded,
                    message: 'لا يوجد salonId داخل بيانات الحجز',
                    isError: true,
                  );
                }

                return _paymentBody(salonId);
              },
            ),
          );
        },
      ),
    );
  }
}

class _PaymentHeader extends StatelessWidget {
  const _PaymentHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.72),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.payments_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'حوّلي المبلغ إلى أحد حسابات الصالون، ثم اكتبي رقم السند لتأكيد الدفع.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _BankInfoText extends StatelessWidget {
  final String title;
  final String value;

  const _BankInfoText({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$title: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'سيتم مراجعة الدفع من قبل الصالون، وبعد القبول ستتحدث حالة الحجز.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool isError;

  const _MessageCard({
    required this.icon,
    required this.message,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 44,
                  color: isError
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
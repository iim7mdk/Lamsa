import 'package:flutter/material.dart';
import 'package:lamsa/features/auth/auth_service.dart';
import 'package:lamsa/features/owner_dashboard/model/salon_model.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  final AuthService _authService = AuthService();
  late Future<SalonModel?> _salonFuture;

  @override
  void initState() {
    super.initState();
    _salonFuture = _authService.getSalonData();
  }

  void _refreshSalonData() {
    setState(() {
      _salonFuture = _authService.getSalonData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF7FA),
        body: SafeArea(
          child: FutureBuilder<SalonModel?>(
            future: _salonFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text('حدث خطأ أثناء تحميل البيانات'));
              }

              final salonData = snapshot.data;

              if (salonData == null) {
                return _EmptySalon(onAddSalon: () {
                  Navigator.pushNamed(context, '/addSalon');
                });
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _ProfileHeader(
                      salonName: salonData.salonName,
                      email: _authService.currentUserEmail,
                    ),

                    const SizedBox(height: 16),

                    _SectionCard(
                      title: 'معلومات الصالون',
                      icon: Icons.storefront,
                      children: [
                        _EditableInfoTile(
                          icon: Icons.person,
                          title: 'اسم الصالون',
                          value: salonData.salonName,
                          onEdit: () => _showEditDialog(
                            context: context,
                            fieldName: 'salonName',
                            currentValue: salonData.salonName,
                            dialogTitle: 'تعديل اسم الصالون',
                          ),
                        ),
                        _EditableInfoTile(
                          icon: Icons.phone,
                          title: 'رقم الجوال',
                          value: salonData.phone,
                          onEdit: () => _showEditDialog(
                            context: context,
                            fieldName: 'phone',
                            currentValue: salonData.phone,
                            dialogTitle: 'تعديل رقم الجوال',
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        _InfoTile(
                          icon: Icons.email,
                          title: 'الإيميل',
                          value: _authService.currentUserEmail,
                        ),
                        _EditableInfoTile(
                          icon: Icons.location_on,
                          title: 'الموقع',
                          value: salonData.location,
                          onEdit: () => _showEditDialog(
                            context: context,
                            fieldName: 'location',
                            currentValue: salonData.location,
                            dialogTitle: 'تعديل الموقع',
                          ),
                        ),
                        _EditableInfoTile(
                          icon: Icons.access_time,
                          title: 'ساعات العمل',
                          value: salonData.workingHours,
                          onEdit: () => _showEditDialog(
                            context: context,
                            fieldName: 'workingHours',
                            currentValue: salonData.workingHours,
                            dialogTitle: 'تعديل ساعات العمل',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _SectionCard(
                      title: 'الخدمات',
                      icon: Icons.spa,
                      actionText: 'إضافة خدمة',
                      onAction: () async {
                        final result =
                        await Navigator.pushNamed(context, '/addService');
                        if (result == true) _refreshSalonData();
                      },
                      children: [
                        if (salonData.services.isEmpty)
                          const _EmptySectionText(text: 'لا توجد خدمات')
                        else
                          ...salonData.services.map((service) {
                            return _ServiceCard(
                              name: service.name,
                              price: service.price,
                              onEdit: () {
                                _showServiceEditDialog(
                                  context: context,
                                  serviceId: service.id,
                                  currentName: service.name,
                                  currentPrice: service.price.toString(),
                                );
                              },
                            );
                          }),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _SectionCard(
                      title: 'الحسابات البنكية',
                      icon: Icons.account_balance,
                      actionText: 'إضافة حساب بنكي',
                      onAction: () async {
                        final result =
                        await Navigator.pushNamed(context, '/addBank');
                        if (result == true) _refreshSalonData();
                      },
                      children: [
                        if (salonData.bankAccounts.isEmpty)
                          const _EmptySectionText(text: 'لا توجد حسابات بنكية')
                        else
                          ...salonData.bankAccounts.map((bank) {
                            return _BankCard(
                              bankName: bank.bankName,
                              accountNumber: bank.accountNumber.toString(),
                              accountHolder: bank.accountHolder,
                              onEdit: () {
                                _showBankAccountEditDialog(
                                  context: context,
                                  bankAccountId: bank.id,
                                  currentBankName: bank.bankName,
                                  currentAccountNumber:
                                  bank.accountNumber.toString(),
                                  currentAccountHolder: bank.accountHolder,
                                );
                              },
                            );
                          }),
                      ],
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await _authService.signOut();
                          if (!context.mounted) return;

                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/decide',
                                (route) => false,
                          );
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('تسجيل الخروج'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showEditDialog({
    required BuildContext context,
    required String fieldName,
    required String currentValue,
    required String dialogTitle,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(dialogTitle),
          content: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              labelText: dialogTitle,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newValue = controller.text.trim();

                if (newValue.isNotEmpty && newValue != currentValue) {
                  await _authService.updateSalonField(
                    fieldName: fieldName,
                    newValue: newValue,
                  );

                  if (!mounted) return;
                  _refreshSalonData();
                }

                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text('تحديث'),
            ),
          ],
        );
      },
    );
  }

  void _showServiceEditDialog({
    required BuildContext context,
    required String serviceId,
    required String currentName,
    required String currentPrice,
  }) {
    final nameController = TextEditingController(text: currentName);
    final priceController = TextEditingController(text: currentPrice);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل الخدمة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الخدمة',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'السعر',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                final newPrice = double.tryParse(priceController.text.trim());

                if (newName.isNotEmpty && newPrice != null) {
                  await _authService.updateServiceById(
                    docId: serviceId,
                    newName: newName,
                    newPrice: newPrice,
                  );

                  if (!mounted) return;
                  _refreshSalonData();
                }

                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text('تحديث'),
            ),
          ],
        );
      },
    );
  }

  void _showBankAccountEditDialog({
    required BuildContext context,
    required String bankAccountId,
    required String currentBankName,
    required String currentAccountNumber,
    required String currentAccountHolder,
  }) {
    final bankNameController = TextEditingController(text: currentBankName);
    final accountNumberController =
    TextEditingController(text: currentAccountNumber);
    final accountHolderController =
    TextEditingController(text: currentAccountHolder);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل الحساب البنكي'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: bankNameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم البنك',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: accountNumberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'رقم الحساب',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: accountHolderController,
                  decoration: const InputDecoration(
                    labelText: 'اسم صاحب الحساب',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newBankName = bankNameController.text.trim();
                final newAccountNumber =
                int.tryParse(accountNumberController.text.trim());
                final newAccountHolder = accountHolderController.text.trim();

                if (newBankName.isNotEmpty &&
                    newAccountNumber != null &&
                    newAccountHolder.isNotEmpty) {
                  await _authService.updateBankAccountById(
                    docId: bankAccountId,
                    bankName: newBankName,
                    accountNumber: newAccountNumber,
                    accountHolder: newAccountHolder,
                  );

                  if (!mounted) return;
                  _refreshSalonData();
                }

                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text('تحديث'),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.salonName,
    required this.email,
  });

  final String salonName;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.pink.shade300,
            Colors.pink.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.storefront,
              size: 42,
              color: Colors.pink.shade300,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            salonName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.actionText,
    this.onAction,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.pink.shade300),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (actionText != null)
                TextButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(actionText!),
                ),
            ],
          ),
          const Divider(),
          ...children,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.pink.shade50,
        child: Icon(icon, color: Colors.pink.shade300),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(value),
    );
  }
}

class _EditableInfoTile extends StatelessWidget {
  const _EditableInfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onEdit,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.pink.shade50,
        child: Icon(icon, color: Colors.pink.shade300),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(value),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: onEdit,
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.name,
    required this.price,
    required this.onEdit,
  });

  final String name;
  final num price;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.pink.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.spa),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('السعر: $price ريال'),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onEdit,
        ),
      ),
    );
  }
}

class _BankCard extends StatelessWidget {
  const _BankCard({
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    required this.onEdit,
  });

  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isSpecial = bankName.trim() == 'العمقي';

    return Card(
      elevation: 0,
      color: isSpecial ? const Color(0xFF168B54) : Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(
          Icons.account_balance,
          color: isSpecial ? Colors.white : Colors.pink.shade300,
        ),
        title: Text(
          bankName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSpecial ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          'رقم الحساب: $accountNumber\nاسم صاحب الحساب: $accountHolder',
          style: TextStyle(
            color: isSpecial ? Colors.white70 : Colors.black87,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.edit,
            color: isSpecial ? Colors.white : null,
          ),
          onPressed: onEdit,
        ),
      ),
    );
  }
}

class _EmptySectionText extends StatelessWidget {
  const _EmptySectionText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Text(
        text,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}

class _EmptySalon extends StatelessWidget {
  const _EmptySalon({required this.onAddSalon});

  final VoidCallback onAddSalon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_mall_directory, size: 80, color: Colors.pink.shade100),
          const SizedBox(height: 12),
          const Text(
            'لم يتم العثور على بيانات الصالون',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAddSalon,
            icon: const Icon(Icons.add),
            label: const Text('إضافة بيانات الصالون'),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:lamsa/features/auth/auth_service.dart';
import 'package:lamsa/features/owner_dashboard/model/salon_model.dart';
import 'widgets/profle_info_row.dart';

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
    return FutureBuilder<SalonModel?>(
      future: _salonFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('حدث خطأ أثناء تحميل البيانات'));
        }

        final salonData = snapshot.data;

        if (!snapshot.hasData || salonData == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('لم يتم العثور على بيانات الصالون'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/addSalon');
                  },
                  child: const Text('إضافة بيانات الصالون'),
                ),
              ],
            ),
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildEditableRow(
                          context: context,
                          icon: Icons.person_2,
                          title: "اسم الصالون",
                          value: salonData.salonName,
                          fieldName: "salonName",
                          dialogTitle: "تعديل اسم الصالون",
                        ),

                        const Divider(),

                        _buildEditableRow(
                          context: context,
                          icon: Icons.phone,
                          title: "رقم الجوال",
                          value: salonData.phone,
                          fieldName: "phone",
                          dialogTitle: "تعديل رقم الجوال",
                          keyboardType: TextInputType.phone,
                        ),

                        const Divider(),

                        Row(
                          children: [
                            Expanded(
                              child: ProfileInfoRow(
                                icon: Icons.email,
                                title: "الإيميل",
                                value: _authService.currentUserEmail,
                              ),
                            ),
                          ],
                        ),

                        const Divider(),

                        _buildEditableRow(
                          context: context,
                          icon: Icons.location_on,
                          title: "الموقع",
                          value: salonData.location,
                          fieldName: "location",
                          dialogTitle: "تعديل الموقع",
                        ),

                        const Divider(),

                        _buildEditableRow(
                          context: context,
                          icon: Icons.access_time,
                          title: "ساعات العمل",
                          value: salonData.workingHours,
                          fieldName: "workingHours",
                          dialogTitle: "تعديل ساعات العمل",
                        ),

                        const Divider(),

                        Row(
                          children: const [
                            Text(
                              "الخدمات:",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        salonData.services.isEmpty
                            ? Column(
                          children: [
                            const Text(
                              "لا توجد خدمات",
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 10),
                          ],
                        )
                            : Column(
                          children: salonData.services.asMap().entries.map((entry) {

                            final service = entry.value;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                title: Text(service.name),
                                subtitle: Text("السعر: ${service.price} ريال"),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    _showServiceEditDialog(
                                      context: context,
                                      serviceId: service.id,
                                      currentName: service.name,
                                      currentPrice: service.price.toString(),
                                    );
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 40),

                        ElevatedButton.icon(
                          onPressed: () async{
                            final result = await Navigator.pushNamed(context, '/addService');
                            if (result == true) {
                              _refreshSalonData();                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text("إضافة خدمة"),
                        ),

                        const Divider(),

                        Row(
                          children: const [
                            Text(
                              "الحسابات البنكية:",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        salonData.bankAccounts.isEmpty
                            ? Column(
                          children: [
                            const Text(
                              "لا توجد حسابات بنكية",
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 10),
                          ],
                        )
                            : Column(
                          children: salonData.bankAccounts.map((bankAccount) {
                            return Card(
                              color: bankAccount.bankName.trim() == "العمقي"
                                  ? const Color(0xFF168B54)
                                  : null,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                title: Text(
                                  bankAccount.bankName,
                                  style: TextStyle(
                                    color: bankAccount.bankName.trim() == "العمقي"
                                        ? Colors.white
                                        : null,
                                    fontWeight: bankAccount.bankName.trim() == "العمقي"
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(

                                  "رقم الحساب: ${bankAccount.accountNumber}\n"
                                      "اسم صاحب الحساب: ${bankAccount.accountHolder}",
                                  style: TextStyle(
                                    color: bankAccount.bankName.trim() == "العمقي"
                                        ? Colors.white70
                                        : null,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    _showBankAccountEditDialog(
                                      context: context,
                                      bankAccountId: bankAccount.id,
                                      currentBankName: bankAccount.bankName,
                                      currentAccountNumber: bankAccount.accountNumber.toString(),
                                      currentAccountHolder: bankAccount.accountHolder,
                                    );
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 40),

                        ElevatedButton.icon(
                          onPressed: () async{
                            final result = await Navigator.pushNamed(context, '/addBank');
                            if (result == true) {
                              _refreshSalonData();                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text("إضافة حساب بنكي"),
                        ),

                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {
                    await _authService.signOut();
                    if (!context.mounted) return;

                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/decide',
                          (route) => false,
                    );
                  },
                  child: const Text('تسجيل الخروج'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditableRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required String fieldName,
    required String dialogTitle,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Row(
      children: [
        Expanded(
          child: ProfileInfoRow(
            icon: icon,
            title: title,
            value: value,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            _showEditDialog(
              context: context,
              fieldName: fieldName,
              currentValue: value,
              dialogTitle: dialogTitle,
              keyboardType: keyboardType,
            );
          },
        ),
      ],
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(dialogTitle),
          content: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              labelText: dialogTitle,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                final newValue = controller.text.trim();

                if (newValue.isNotEmpty && newValue != currentValue) {
                  await _authService.updateSalonField(
                    fieldName: fieldName,
                    newValue: newValue,
                  );

                  if (!mounted) return;
                  _refreshSalonData();                }

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
                decoration: const InputDecoration(labelText: 'اسم الخدمة'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'السعر'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
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
                  _refreshSalonData();                }

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
  final accountNumberController = TextEditingController(text: currentAccountNumber);
  final accountHolderController = TextEditingController(text: currentAccountHolder);

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
                decoration: const InputDecoration(labelText: 'اسم البنك'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: accountNumberController,
                decoration: const InputDecoration(labelText: 'رقم الحساب'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: accountHolderController,
                decoration: const InputDecoration(labelText: 'اسم صاحب الحساب'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              final newBankName = bankNameController.text.trim();
              final newAccountNumber = int.tryParse(accountNumberController.text.trim());
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

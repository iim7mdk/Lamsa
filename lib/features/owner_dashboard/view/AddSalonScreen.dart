import 'package:flutter/material.dart';
import 'package:lamsa/features/auth/auth_service.dart';

class AddSalonScreen extends StatefulWidget {
  const AddSalonScreen({super.key});

  @override
  _AddSalonScreenState createState() => _AddSalonScreenState();
}

class _AddSalonScreenState extends State<AddSalonScreen> {
  final _salonNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _workingHoursController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة بيانات الصالون')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              TextFormField(
                controller: _salonNameController,
                decoration: const InputDecoration(labelText: 'اسم الصالون'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال اسم الصالون';
                  }
                  return null;
                },
              ),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال رقم الهاتف';
                  }
                  return null;
                },
              ),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'الموقع'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال الموقع';
                  }
                  return null;
                },
              ),

              TextFormField(
                controller: _workingHoursController,
                decoration: const InputDecoration(labelText: 'ساعات العمل'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال ساعات العمل';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      await AuthService().addSalonData(
                        salonName: _salonNameController.text.trim(),
                        phone: _phoneController.text.trim(),
                        location: _locationController.text.trim(),
                        workingHours: _workingHoursController.text.trim(),
                        services: [],
                        bankAccounts: [],
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم إضافة بيانات الصالون بنجاح')),
                      );

                      // التوجيه إلى صفحة البروفايل بعد إضافة بيانات الصالون بنجاح
                      Navigator.pushReplacementNamed(context, '/ownerProfile');

                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('حدث خطأ أثناء إضافة بيانات الصالون')),
                      );
                    }
                  }
                },
                child: const Text('حفظ'),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
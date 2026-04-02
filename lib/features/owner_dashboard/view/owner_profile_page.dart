import 'package:flutter/material.dart';
import 'package:lamsa/features/auth/auth_service.dart';
import 'package:lamsa/features/owner_dashboard/model/salon_model.dart';
import 'widgets/profle_info_row.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  _OwnerProfileScreenState createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  TextEditingController phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SalonModel?>(
      future: AuthService().getSalonData(), // استرجاع بيانات الصالون من فايربيس
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator()); // تحميل البيانات
        }

        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ أثناء تحميل البيانات'));
        }

        final salonData = snapshot.data;

        if (salonData == null) {
          return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('لم يتم العثور على بيانات الصالون'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // انتقل إلى شاشة إضافة بيانات الصالون
                      Navigator.pushNamed(context, '/addSalon');
                    },
                    child: Text('إضافة بيانات الصالون'),
                  ),
                ],
              ),
          );
        }

        // تحديث الـ TextEditingController بالقيم الحالية
        phoneController.text = salonData.phone;

        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 100),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ProfileInfoRow(
                          icon: Icons.person_2,
                          title: "اسم الصالون",
                          value: salonData.salonName,
                        ),

                        const Divider(),

                        // تعديل رقم الجوال
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ProfileInfoRow(
                              icon: Icons.phone,
                              title: "رقم الجوال",
                              value: salonData.phone,
                            ),
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                _showPhoneEditDialog(context, salonData);
                              },
                            ),
                          ],
                        ),

                        const Divider(),

                        ProfileInfoRow(
                          icon: Icons.email,
                          title: "الإيميل",
                          value: salonData.email,
                        ),

                        const Divider(),

                        ProfileInfoRow(
                          icon: Icons.location_on,
                          title: "الموقع",
                          value: salonData.location,
                        ),

                        const Divider(),

                        ProfileInfoRow(
                          icon: Icons.access_time,
                          title: "ساعات العمل",
                          value: salonData.workingHours,
                        ),

                        const Divider(),

                        // عرض الخدمات
                        Text("الخدمات:"),
                        ...salonData.services.map((service) => ListTile(
                          title: Text(service.name),
                          subtitle: Text("السعر: ${service.price} ريال"),
                        )).toList(),

                        SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); // يغلق القائمة
                    await AuthService().signOut();
                    if (!context.mounted) return;

                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/decide',
                          (route) => false,
                    );
                  },
                  child: Text('تسجيل الخروج'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // طريقة لعرض مربع حوار لتعديل رقم الجوال
  // طريقة لعرض مربع حوار لتعديل رقم الجوال
  void _showPhoneEditDialog(BuildContext context, SalonModel salonData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('تعديل رقم الجوال'),
          content: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'رقم الجوال',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // إغلاق مربع الحوار
              },
              child: Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                final newPhone = phoneController.text;
                if (newPhone != salonData.phone) {
                  await AuthService().updateSalonPhone(newPhone); // تحديث رقم الجوال في Firebase

                  // بعد تحديث Firebase، نعيد تحميل البيانات من Firebase
                  setState(() {});  // إعادة تحميل البيانات من Firebase لعرض التغييرات في واجهة المستخدم
                }
                Navigator.pop(context); // إغلاق مربع الحوار
              },
              child: Text('تحديث'),
            ),
          ],
        );
      },
    );
  }
}
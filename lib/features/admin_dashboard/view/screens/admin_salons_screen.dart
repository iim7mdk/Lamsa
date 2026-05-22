import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminSalonsScreen extends StatelessWidget {
  const AdminSalonsScreen({super.key});

  Future<void> deleteSalon(String salonId) async {
    await FirebaseFirestore.instance.collection('salons').doc(salonId).delete();
  }

  Future<void> approveSalon(String salonId) async {
    await FirebaseFirestore.instance.collection('salons').doc(salonId).update({
      'status': 'approved',
      'isVerified': true,
      'verifiedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectSalon(String salonId) async {
    await FirebaseFirestore.instance.collection('salons').doc(salonId).update({
      'status': 'rejected',
      'isVerified': false,
      'rejectedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addSalonDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final locationController = TextEditingController();
    final workingHoursController = TextEditingController();
    final ownerUidController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('إضافة صالون'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم الصالون'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'الجوال'),
                ),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'الموقع'),
                ),
                TextField(
                  controller: workingHoursController,
                  decoration: const InputDecoration(labelText: 'ساعات العمل'),
                ),
                TextField(
                  controller: ownerUidController,
                  decoration: const InputDecoration(labelText: 'Owner UID'),
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
                final ownerUid = ownerUidController.text.trim();

                await FirebaseFirestore.instance.collection('salons').doc(ownerUid).set({
                  'salonName': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'location': locationController.text.trim(),
                  'workingHours': workingHoursController.text.trim(),
                  'ownerUid': ownerUid,
                  'status': 'approved',
                  'isVerified': true,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text('إضافة'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => addSalonDialog(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('salons').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ:\n${snapshot.error}'));
          }

          final salons = snapshot.data?.docs ?? [];

          if (salons.isEmpty) {
            return const Center(child: Text('لا توجد صوالين'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: salons.length,
            itemBuilder: (context, index) {
              final doc = salons[index];
              final data = doc.data();
              final salonId = doc.id;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(data['salonName'] ?? 'بدون اسم'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الجوال: ${data['phone'] ?? '-'}'),
                      Text('الموقع: ${data['location'] ?? '-'}'),
                      Text('الحالة: ${data['status'] ?? 'pending'}'),
                      Text('موثق: ${data['isVerified'] == true ? 'نعم' : 'لا'}'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'approve') await approveSalon(salonId);
                      if (value == 'reject') await rejectSalon(salonId);
                      if (value == 'delete') await deleteSalon(salonId);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'approve',
                        child: Text('اعتماد'),
                      ),
                      PopupMenuItem(
                        value: 'reject',
                        child: Text('رفض'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('حذف'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
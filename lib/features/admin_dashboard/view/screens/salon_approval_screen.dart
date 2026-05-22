import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SalonApprovalScreen extends StatelessWidget {
  const SalonApprovalScreen({super.key});

  Future<void> approveSalon(String salonId, String ownerUid) async {
    final firestore = FirebaseFirestore.instance;

    await firestore.collection('salons').doc(salonId).update({
      'status': 'approved',
      'isVerified': true,
      'verifiedAt': FieldValue.serverTimestamp(),
    });

    await firestore.collection('users').doc(ownerUid).update({
      'ownerStatus': 'approved',
    });
  }

  Future<void> rejectSalon(String salonId, String ownerUid) async {
    final firestore = FirebaseFirestore.instance;

    await firestore.collection('salons').doc(salonId).update({
      'status': 'rejected',
      'isVerified': false,
      'rejectedAt': FieldValue.serverTimestamp(),
    });

    await firestore.collection('users').doc(ownerUid).update({
      'ownerStatus': 'rejected',
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('salons').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ:\n${snapshot.error}'));
        }

        final salons = snapshot.data?.docs.where((doc) {
          final data = doc.data();
          return data['status'] == null ||
              data['status'] == 'pending' ||
              data['isVerified'] != true;
        }).toList() ?? [];

        if (salons.isEmpty) {
          return const Center(child: Text('لا توجد صوالين بانتظار الاعتماد'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: salons.length,
          itemBuilder: (context, index) {
            final doc = salons[index];
            final data = doc.data();

            final salonId = doc.id;
            final ownerUid = data['ownerUid'] ?? salonId;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('اسم الصالون: ${data['salonName'] ?? 'غير متوفر'}'),
                    Text('الجوال: ${data['phone'] ?? 'غير متوفر'}'),
                    Text('الموقع: ${data['location'] ?? 'غير متوفر'}'),
                    Text('الحالة: ${data['status'] ?? 'pending'}'),
                    Text('موثق: ${data['isVerified'] == true ? 'نعم' : 'لا'}'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await approveSalon(salonId, ownerUid);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم اعتماد الصالون')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              minimumSize: const Size(0, 45),
                            ),
                            child: const Text(
                              'اعتماد',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await rejectSalon(salonId, ownerUid);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم رفض الصالون')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              minimumSize: const Size(0, 45),
                            ),
                            child: const Text(
                              'رفض',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
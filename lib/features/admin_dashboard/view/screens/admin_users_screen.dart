import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  Future<void> deleteUserDoc(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
  }

  Future<void> makeAdmin(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'role': 'admin',
    });
  }

  Future<void> makeCustomer(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'role': 'customer',
    });
  }

  Future<void> makeOwner(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'role': 'owner',
      'ownerStatus': 'pending',
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ:\n${snapshot.error}'));
        }

        final users = snapshot.data?.docs ?? [];

        if (users.isEmpty) {
          return const Center(child: Text('لا يوجد مستخدمين'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final doc = users[index];
            final data = doc.data();
            final uid = doc.id;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(data['name'] ?? 'بدون اسم'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['email'] ?? ''),
                    Text('الدور: ${data['role'] ?? 'غير محدد'}'),
                    Text('حالة المالك: ${data['ownerStatus'] ?? '-'}'),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'admin') await makeAdmin(uid);
                    if (value == 'customer') await makeCustomer(uid);
                    if (value == 'owner') await makeOwner(uid);
                    if (value == 'delete') await deleteUserDoc(uid);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'admin',
                      child: Text('جعله Admin'),
                    ),
                    PopupMenuItem(
                      value: 'customer',
                      child: Text('جعله Customer'),
                    ),
                    PopupMenuItem(
                      value: 'owner',
                      child: Text('جعله Owner'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('حذف المستخدم من Firestore'),
                    ),
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
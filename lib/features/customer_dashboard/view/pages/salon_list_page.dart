import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // استيراد Firebase
import 'package:lamsa/features/owner_dashboard/model/bank_account_model.dart';
import 'package:lamsa/features/owner_dashboard/model/salon_model.dart';
import 'package:lamsa/features/owner_dashboard/model/service_model.dart';
import '../widgets/salon_card.dart';

class SalonListPage extends StatelessWidget {
  const SalonListPage({super.key});

  // هذه دالة لجلب بيانات الصالونات من Firebase
  Future<List<SalonModel>> _getSalonsFromFirestore() async {
    try{
      final querySnapshot = await FirebaseFirestore.instance.collection('salons').get();

      // print('Number of salons in Firestore: ${querySnapshot.docs.length}');  // طباعة عدد الصالونات

      return Future.wait(querySnapshot.docs.map((doc) async {
        final data = doc.data();

        // جلب الخدمات ككولكشن
        final servicesQuerySnapshot = await FirebaseFirestore.instance
            .collection('salons')
            .doc(doc.id)
            .collection('services')
            .get();

        final bankAccountsQuerySnapshot = await FirebaseFirestore.instance
            .collection('salons')
            .doc(doc.id)
            .collection('bank_accounts')
            .get();

        final List<Service> servicesList = servicesQuerySnapshot.docs
            .map((serviceDoc) => Service.fromMap(
          serviceDoc.id,
          serviceDoc.data(),
        ))
            .toList();

        // جلب الحسابات البنكية ككولكشن
        final List<BankAccount> bankAccountsList = bankAccountsQuerySnapshot.docs
            .map((accountDoc) => BankAccount.fromMap(
          accountDoc.id,
          accountDoc.data(),
        ))
            .toList();

        // print('Number of bank accounts for salon ${doc.id}: ${bankAccountsQuerySnapshot.docs.length}'); // طباعة عدد الحسابات البنكية




        return SalonModel(
          id: doc.id,
          salonName: data['salonName']?.toString() ?? '',
          phone: data['phone']?.toString() ?? '',
          email: data['email']?.toString() ?? '',
          location: data['location']?.toString() ?? '',
          workingHours: data['workingHours']?.toString() ?? '',
          ownerUid: data['ownerUid']?.toString() ?? '',
          services: servicesList,
          bankAccounts: [],
          // description: data['description'],
        );
      }).toList());
    } catch(e){
      print('Error loading salons data: $e');  // طباعة الخطأ
      throw Exception('حدث خطأ أثناء تحميل البيانات');
    }

  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SalonModel>>(
      future: _getSalonsFromFirestore(), // جلب البيانات من Firestore
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator()); // تحميل البيانات
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('حدث خطأ أثناء تحميل البيانات\n${snapshot.error}'),
          );
        }

        if (snapshot.data == null || snapshot.data!.isEmpty) {
          return Center(child: Text('لا توجد صالونات حالياً'));
        }

        final salons = snapshot.data!;
        // print('Loaded salons: ${salons.length}');

        return ListView.builder(
          itemCount: salons.length,
          itemBuilder: (context, index) {
            return SalonCard(salon: salons[index]);
          },
        );
      },
    );
  }
}
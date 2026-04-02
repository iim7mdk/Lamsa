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

      print('Number of salons in Firestore: ${querySnapshot.docs.length}');  // طباعة عدد الصالونات

      return Future.wait(querySnapshot.docs.map((doc) async {

        // استخراج البيانات من الوثيقة (Document) في Firestore
        var data = doc.data();

        // جلب الخدمات ككولكشن
        var servicesQuerySnapshot = await FirebaseFirestore.instance
            .collection('salons')
            .doc(doc.id)
            .collection('services')
            .get();

        print('Number of services for salon ${doc.id}: ${servicesQuerySnapshot.docs.length}'); // طباعة عدد الخدمات


        var servicesList = servicesQuerySnapshot.docs.map((serviceDoc) {
          var serviceData = serviceDoc.data();
          print('Service data: $serviceData'); // طباعة بيانات الخدمة
          return Service.fromMap(serviceData);
        }).toList();

        // جلب الحسابات البنكية ككولكشن
        var bankAccountsQuerySnapshot = await FirebaseFirestore.instance
            .collection('salons')
            .doc(doc.id)
            .collection('bank_accounts')
            .get();

        print('Number of bank accounts for salon ${doc.id}: ${bankAccountsQuerySnapshot.docs.length}'); // طباعة عدد الحسابات البنكية


        var bankAccountsList = bankAccountsQuerySnapshot.docs.map((accountDoc) {
          var accountData = accountDoc.data();
          print('Bank account data: $accountData'); // طباعة بيانات الحساب البنكي
          return BankAccount.fromMap(accountData);
        }).toList();

        return SalonModel(
          salonName: data['salonName'],
          phone: data['phone'],
          email: data['email'],
          location: data['location'],
          workingHours: data['workingHours'],
          ownerUid: data['ownerUid'],
          services: servicesList,
          bankAccounts: bankAccountsList,
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
          return Center(child: Text('حدث خطأ أثناء تحميل البيانات'));
        }

        if (snapshot.data == null || snapshot.data!.isEmpty) {
          return Center(child: Text('لا توجد صالونات حالياً'));
        }

        final salons = snapshot.data!;
        print('Loaded salons: ${salons.length}'); // طباعة عدد الصالونات المحملة

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
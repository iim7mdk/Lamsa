import 'package:lamsa/features/owner_dashboard/model/bank_account_model.dart';
import 'package:lamsa/features/owner_dashboard/model/service_model.dart';

class SalonModel {
  final String id;
  final String salonName;
  final String phone;
  final String email;
  final String location;
  final String workingHours;
  final String ownerUid;
  final List<Service> services;
  final List<BankAccount> bankAccounts;

  SalonModel({
    required this.id,
    required this.salonName,
    required this.phone,
    required this.email,
    required this.location,
    required this.workingHours,
    required this.ownerUid,
    required this.services,
    required this.bankAccounts,  // إضافة الحسابات البنكية هنا
  });

  // ملاحظة: هنا يتم إضافة الخدمات بشكل منفصل باستخدام كولكشن داخل Firestore
  factory SalonModel.fromMap(Map<String, dynamic> map, String id) {


    return SalonModel(
      id: id,
      salonName: map['salonName'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      location: map['location'] ?? '',
      workingHours: map['workingHours'] ?? '',
      ownerUid: map['ownerUid'] ?? '',
      services: [],
      bankAccounts: [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'salonName': salonName,
      'phone': phone,
      'email': email,
      'location': location,
      'workingHours': workingHours,
      'ownerUid': ownerUid,
      // 'services' ليست ضرورية هنا لأننا نقرأها من كولكشن Firestore
    };
  }
}
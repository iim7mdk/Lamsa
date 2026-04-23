import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String customerId;
  final String salonId;
  final List<String> serviceIds;
  final double totalPrice;
  final String? bankReceiptNumber;
  final DateTime appointmentAt;
  final String status;
  final DateTime createdAt;

  const BookingModel({
    required this.id,
    required this.customerId,
    required this.salonId,
    required this.serviceIds,
    required this.totalPrice,
    this.bankReceiptNumber,
    required this.appointmentAt,
    required this.status,
    required this.createdAt,
  });

  factory BookingModel.fromMap(String id, Map<String, dynamic> map) {
    return BookingModel(
      id: id,
      customerId: map['customerId'] as String? ?? '',
      salonId: map['salonId'] as String? ?? '',
      serviceIds: List<String>.from(map['serviceIds'] ?? const []),
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      bankReceiptNumber: map['bankReceiptNumber'] as String?,
      appointmentAt: (map['appointmentAt'] as Timestamp).toDate(),
      status: map['status'] as String? ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'salonId': salonId,
      'serviceIds': serviceIds,
      'totalPrice': totalPrice,
      'bankReceiptNumber': bankReceiptNumber,
      'appointmentAt': Timestamp.fromDate(appointmentAt),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
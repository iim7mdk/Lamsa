import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String customerId;
  final String customerName;
  final int customerPhone;
  final String salonId;
  final List<String> selectedServices;
  final double totalPrice;
  final String? bankReceiptNumber;
  final DateTime appointmentAt;
  final String status;
  final String? paymentStatus;
  final String? couponCode;
  final double discountAmount;
  final double finalPrice;
  final DateTime createdAt;

  const BookingModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.salonId,
    required this.selectedServices,
    required this.totalPrice,
    this.bankReceiptNumber,
    this.paymentStatus,
    required this.appointmentAt,
    required this.status,
    this.couponCode,
    this.discountAmount = 0,
    required this.finalPrice,
    required this.createdAt,
  });

  factory BookingModel.fromMap(String id, Map<String, dynamic> map) {
    return BookingModel(
      id: id,
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerPhone: map['customerPhone'] as int? ?? 0,
      salonId: map['salonId'] as String? ?? '',
      selectedServices: List<String>.from(map['selectedServices'] ?? const []),
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      bankReceiptNumber: map['bankReceiptNumber'] as String?,
      paymentStatus: map['paymentStatus'] as String?,
      appointmentAt: (map['appointmentAt'] as Timestamp).toDate(),
      status: map['status'] as String? ?? 'pending',
      couponCode: map['couponCode'] as String?,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
      finalPrice: (map['finalPrice'] as num?)?.toDouble() ??
          (map['totalPrice'] as num?)?.toDouble() ??
          0.0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'salonId': salonId,
      'selectedServices': selectedServices,
      'totalPrice': totalPrice,
      'bankReceiptNumber': bankReceiptNumber,
      'paymentStatus': paymentStatus,
      'appointmentAt': Timestamp.fromDate(appointmentAt),
      'status': status,
      'couponCode': couponCode,
      'discountAmount': discountAmount,
      'finalPrice': finalPrice,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

}
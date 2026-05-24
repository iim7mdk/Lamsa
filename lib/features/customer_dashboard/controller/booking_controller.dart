import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lamsa/features/customer_dashboard/model/booking_model.dart';
import 'package:lamsa/features/owner_dashboard/model/service_model.dart';
import 'package:lamsa/features/customer_dashboard/service/booking_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lamsa/features/customer_dashboard/service/coupon_service.dart';


class BookingController {
  final BookingService _service;
  BookingController(this._service);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  Stream<QuerySnapshot<Map<String, dynamic>>> getMyBookings(
      String userId,
      ) {
    return _firestore
        .collection('bookings')
        .where('customerId', isEqualTo: userId)
        .where(
      'status',
      whereIn: ['pending', 'accepted', 'rejected', 'unpaid'],
    )
        .snapshots();
  }

  Future<BookingExtraData> loadExtraData(
      Map<String, dynamic> bookingData,
      ) async {
    final salonId = bookingData['salonId']?.toString() ?? '';

    final serviceIds = stringList(
      bookingData['selectedServices'],
    );

    if (salonId.isEmpty) {
      return const BookingExtraData(
        salonName: 'صالون غير معروف',
        serviceNames: [],
      );
    }

    String salonName = 'صالون';

    try {
      final salonDoc = await _firestore
          .collection('salons')
          .doc(salonId)
          .get();

      final salonData = salonDoc.data();

      salonName =
          salonData?['title']?.toString() ??
              salonData?['name']?.toString() ??
              salonData?['salonName']?.toString() ??
              'صالون';
    } catch (_) {
      salonName = 'تعذر تحميل اسم الصالون';
    }

    final List<String> serviceNames = [];

    for (final serviceId in serviceIds) {
      try {
        final serviceDoc = await _firestore
            .collection('salons')
            .doc(salonId)
            .collection('services')
            .doc(serviceId)
            .get();

        final serviceData = serviceDoc.data();

        final serviceName =
            serviceData?['name']?.toString() ??
                serviceData?['title']?.toString() ??
                serviceData?['serviceName']?.toString() ??
                serviceId;

        serviceNames.add(serviceName);
      } catch (_) {
        serviceNames.add(serviceId);
      }
    }

    return BookingExtraData(
      salonName: salonName,
      serviceNames: serviceNames,
    );
  }

  Future<void> deleteExpiredUnpaidBookings() async {
    final expiredTime = DateTime.now().subtract(
      const Duration(minutes: 30),
    );

    final query = await _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'unpaid')
        .get();

    for (final doc in query.docs) {
      final data = doc.data();

      final createdAt = data['createdAt'];
      final salonId = data['salonId']?.toString() ?? '';
      final appointmentAtValue = data['appointmentAt'];

      if (createdAt is Timestamp) {
        final createdDate = createdAt.toDate();

        if (createdDate.isBefore(expiredTime)) {
          if (appointmentAtValue is Timestamp && salonId.isNotEmpty) {
            await _service.releaseSlot(
              salonId: salonId,
              appointmentAt: appointmentAtValue.toDate(),
            );
          }

          await doc.reference.delete();
        }
      }
    }
  }

  DateTime? toDate(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  List<String> stringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }

    return [];
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String formatTime(DateTime date) {
    final period = date.hour >= 12 ? 'م' : 'ص';

    int hour = date.hour % 12;

    if (hour == 0) {
      hour = 12;
    }

    final minute = date.minute
        .toString()
        .padLeft(2, '0');

    return '$hour:$minute $period';
  }

  String formatPrice(dynamic value) {
    double price = 0;

    if (value is num) {
      price = value.toDouble();
    } else {
      price = double.tryParse(
        value?.toString() ?? '',
      ) ??
          0;
    }

    final hasDecimals = price % 1 != 0;

    return '${price.toStringAsFixed(
      hasDecimals ? 2 : 0,
    )} ر.س';
  }



  String getBookingStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد المراجعة';
      case 'accepted':
        return 'تم القبول';
      case 'rejected':
        return 'مرفوض';
      default:
        return 'غير مدفوع'; // أو أي حالة أخرى إذا كانت موجودة
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange; // قيد المراجعة
      case 'accepted':
        return Colors.green; // تم القبول
      case 'rejected':
        return Colors.red; // مرفوض
      default:
        return Colors.grey; // غير مدفوع أو أي حالة أخرى
    }
  }

  Future updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    final bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
      throw Exception('الحجز غير موجود');
    }

    final data = bookingDoc.data()!;
    final salonId = data['salonId']?.toString() ?? '';
    final appointmentAtValue = data['appointmentAt'];

    await bookingRef.update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (status == 'rejected' || status == 'cancelled') {
      if (appointmentAtValue is Timestamp && salonId.isNotEmpty) {
        await _service.releaseSlot(
          salonId: salonId,
          appointmentAt: appointmentAtValue.toDate(),
        );
      }
    }
  }

  Future<String> confirmBooking({
    required String customerId,
    required String customerName,
    required int customerPhone,
    required String salonId,
    required List<String> selectedServices,
    required double totalPrice,
    required DateTime? selectedDate,
    required String? selectedTime,
    required String status,
    required String? couponCode,
    required double discountAmount,
    required double finalPrice,
    required dynamic createdAt,
  }) async {
    if (selectedServices.isEmpty) {
      throw Exception('اختاري خدمة واحدة على الأقل');
    }

    if (selectedDate == null) {
      throw Exception('اختاري تاريخ الحجز');
    }

    if (selectedTime == null) {
      throw Exception('اختاري وقت الحجز');
    }

    final appointmentAt = combineDateAndTime(selectedDate, selectedTime);

    final booking = BookingModel(
      id: '',
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      salonId: salonId,
      selectedServices: selectedServices,
      totalPrice: totalPrice,
      bankReceiptNumber: null,
      appointmentAt: appointmentAt,
      status: status,
      couponCode: couponCode,
      discountAmount: discountAmount,
      finalPrice: finalPrice,
      createdAt: createdAt,
    );

    final bookingId = await _service.createBooking(booking);

    return bookingId;
  }

  Future<String> createBookingAndValidate({
    required String salonId,
    required List<String> selectedServices,
    required double totalPrice,
    required DateTime? selectedDate,
    required String? selectedTime,
    String? couponCode,
    double discountAmount = 0,
    double? finalPrice,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'يجب تسجيل الدخول قبل إنشاء الحجز',
      );
    }

    final userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    final userData = userDoc.data();

    final customerName =
        userData?['name']?.toString() ??
            'غير معروف';

    final customerPhone = int.tryParse(
      userData?['phone']?.toString() ?? '',
    ) ??
        0;

    final bookingId = await confirmBooking(
      customerId: user.uid,
      customerName: customerName,
      customerPhone: customerPhone,
      salonId: salonId,
      selectedServices: selectedServices,
      totalPrice: totalPrice,
      selectedDate: selectedDate,
      selectedTime: selectedTime,
      status: 'pending',
      couponCode: couponCode,
      discountAmount: discountAmount,
      finalPrice: finalPrice ?? totalPrice,
      createdAt: DateTime.now(),
    );

    return bookingId;
  }

  double calculateTotalPrice(List<Service> services) {
    return services.fold(
      0,
          (sum, service) => sum + service.price,
    );
  }

  Future<void> uploadReceiptNumber({
    required String bookingId,
    required String receiptNumber,
    required String bankAccountId,
    required String bankName,
    required String accountNumber,
    required String accountHolder,
  }) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'paymentMethod': 'Bank Accounts',
        'paymentStatus': 'pending',
        'bankReceiptNumber': receiptNumber,
        'selectedBankAccountId': bankAccountId,
        'selectedBankName': bankName,
        'selectedAccountNumber': accountNumber,
        'selectedAccountHolder': accountHolder,
        'receiptUploadedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('تم تأكيد الدفع بنجاح');
    } catch (e) {
      print('حدث خطأ أثناء رفع رقم السند: $e');
    }
  }

  Future<List<String>> getBookedSlots({
    required String salonId,
    required DateTime selectedDate,
  }) async {
    return _service.getBookedSlots(
      salonId: salonId,
      selectedDate: selectedDate,
    );
  }

  DateTime combineDateAndTime(DateTime date, String time) {
    final parts = time.split(' ');
    final clock = parts[0];
    final period = parts[1];

    final hourMinute = clock.split(':');
    int hour = int.parse(hourMinute[0]);
    final minute = int.parse(hourMinute[1]);

    if (period == 'م' && hour != 12) {
      hour += 12;
    } else if (period == 'ص' && hour == 12) {
      hour = 0;
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  List<String> getAvailableTimes({
    required List<String> availableTimes,
    required DateTime? selectedDate,
    required List<String> bookedSlots,
  }) {
    if (selectedDate == null) return availableTimes;

    return availableTimes.where((time) {
      final appointmentAt = combineDateAndTime(selectedDate, time);
      final slotKey = _service.slotKeyFromDateTime(appointmentAt);

      return !bookedSlots.contains(slotKey);
    }).toList();
  }

  final CouponService _couponService = CouponService();

  Future<AppliedCoupon> applyCoupon({
    required String code,
    required String salonId,
    required double totalPrice,
  }) async {
    return _couponService.validateCoupon(
      code: code,
      salonId: salonId,
      totalPrice: totalPrice,
    );
  }

}

class BookingExtraData {
  final String salonName;
  final List<String> serviceNames;

  const BookingExtraData({
    required this.salonName,
    required this.serviceNames,
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lamsa/features/customer_dashboard/model/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String slotKeyFromDateTime(DateTime appointmentAt) {
    final year = appointmentAt.year.toString();
    final month = appointmentAt.month.toString().padLeft(2, '0');
    final day = appointmentAt.day.toString().padLeft(2, '0');
    final hour = appointmentAt.hour.toString().padLeft(2, '0');
    final minute = appointmentAt.minute.toString().padLeft(2, '0');

    return '${year}${month}${day}_${hour}${minute}';
  }

  Future<String> createBooking(BookingModel booking) async {
    final slotKey = slotKeyFromDateTime(booking.appointmentAt);

    final bookingRef = _firestore.collection('bookings').doc();

    final slotRef = _firestore
        .collection('salons')
        .doc(booking.salonId)
        .collection('booked_slots')
        .doc(slotKey);

    await _firestore.runTransaction((transaction) async {
      final slotSnapshot = await transaction.get(slotRef);

      if (slotSnapshot.exists) {
        throw Exception('هذا الموعد محجوز بالفعل، اختاري وقتًا آخر');
      }

      transaction.set(slotRef, {
        'bookingId': bookingRef.id,
        'salonId': booking.salonId,
        'appointmentAt': Timestamp.fromDate(booking.appointmentAt),
        'status': booking.status,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.set(bookingRef, {
        ...booking.toMap(),
        'slotKey': slotKey,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return bookingRef.id;
  }

  Future<List<String>> getBookedSlots({
    required String salonId,
    required DateTime selectedDate,
  }) async {
    final startOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection('salons')
        .doc(salonId)
        .collection('booked_slots')
        .where(
      'appointmentAt',
      isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
    )
        .where(
      'appointmentAt',
      isLessThan: Timestamp.fromDate(endOfDay),
    )
        .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Future<void> releaseSlot({
    required String salonId,
    required DateTime appointmentAt,
  }) async {
    final slotKey = slotKeyFromDateTime(appointmentAt);

    await _firestore
        .collection('salons')
        .doc(salonId)
        .collection('booked_slots')
        .doc(slotKey)
        .delete();
  }
}
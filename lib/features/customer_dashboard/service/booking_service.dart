import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lamsa/features/customer_dashboard/model/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createBooking(BookingModel booking) async {
    await _firestore.collection('bookings').add(booking.toMap());
  }
}
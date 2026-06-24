import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _commentsRef(String salonId) {
    return _db.collection('salons').doc(salonId).collection('comments');
  }

  CollectionReference<Map<String, dynamic>> _ratingsRef(String salonId) {
    return _db.collection('salons').doc(salonId).collection('ratings');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> commentsStream(String salonId) {
    return _commentsRef(salonId)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> ratingsStream(String salonId) {
    return _ratingsRef(salonId).snapshots();
  }

  Future<String> _currentUserName() async {
    final user = _auth.currentUser;
    if (user == null) return 'مستخدم';

    final authName = user.displayName?.trim();
    if (authName != null && authName.isNotEmpty) return authName;

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final data = userDoc.data();

    return data?['name']?.toString() ??
        data?['fullName']?.toString() ??
        user.email ??
        'مستخدم';
  }

  Future<void> addComment({
    required String salonId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول لإضافة تعليق');
    }

    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      throw Exception('اكتبي التعليق أولاً');
    }

    final userName = await _currentUserName();

    await _commentsRef(salonId).add({
      'salonId': salonId,
      'userId': user.uid,
      'userName': userName,
      'text': cleanText,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?>
  getEligibleBookingForRating(String salonId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final bookingsSnapshot = await _db
        .collection('bookings')
        .where('customerId', isEqualTo: user.uid)
        .get();

    final now = DateTime.now();

    for (final doc in bookingsSnapshot.docs) {
      final data = doc.data();

      final bookingSalonId = data['salonId']?.toString();
      final status = data['status']?.toString();
      final appointmentTimestamp = data['appointmentAt'];

      if (bookingSalonId != salonId) continue;
      if (status != 'accepted') continue;
      if (appointmentTimestamp is! Timestamp) continue;

      final appointmentAt = appointmentTimestamp.toDate();

      if (appointmentAt.isAfter(now)) continue;

      final ratingDoc = await _ratingsRef(salonId).doc(doc.id).get();

      if (!ratingDoc.exists) {
        return doc;
      }
    }

    return null;
  }

  Future<void> addRating({
    required String salonId,
    required String bookingId,
    required int rating,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('يجب تسجيل الدخول لإضافة تقييم');
    }

    if (rating < 1 || rating > 5) {
      throw Exception('التقييم يجب أن يكون من 1 إلى 5');
    }

    final userName = await _currentUserName();

    final bookingRef = _db.collection('bookings').doc(bookingId);
    final ratingRef = _ratingsRef(salonId).doc(bookingId);

    await _db.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingRef);

      if (!bookingSnapshot.exists) {
        throw Exception('الحجز غير موجود');
      }

      final bookingData = bookingSnapshot.data() as Map<String, dynamic>;

      final appointmentTimestamp = bookingData['appointmentAt'];

      if (bookingData['customerId'] != user.uid) {
        throw Exception('لا يمكنك تقييم حجز ليس لك');
      }

      if (bookingData['salonId'] != salonId) {
        throw Exception('هذا الحجز لا يخص هذا الصالون');
      }

      if (bookingData['status'] != 'accepted') {
        throw Exception('لا يمكن التقييم إلا بعد قبول الحجز');
      }

      if (appointmentTimestamp is! Timestamp) {
        throw Exception('وقت الحجز غير صحيح');
      }

      final appointmentAt = appointmentTimestamp.toDate();

      if (appointmentAt.isAfter(DateTime.now())) {
        throw Exception('لا يمكنك التقييم قبل انتهاء موعد الحجز');
      }

      final oldRating = await transaction.get(ratingRef);

      if (oldRating.exists) {
        throw Exception('تم تقييم هذا الحجز مسبقاً');
      }

      transaction.set(ratingRef, {
        'salonId': salonId,
        'bookingId': bookingId,
        'userId': user.uid,
        'userName': userName,
        'rating': rating,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> deleteComment({
    required String salonId,
    required String commentId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('يجب تسجيل الدخول لحذف التعليق');
    }

    await _commentsRef(salonId).doc(commentId).delete();
  }

}
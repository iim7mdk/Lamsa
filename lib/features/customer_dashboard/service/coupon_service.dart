import 'package:cloud_firestore/cloud_firestore.dart';

class AppliedCoupon {
  final String code;
  final String discountType;
  final double discountValue;
  final double discountAmount;
  final double finalPrice;

  const AppliedCoupon({
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
    required this.finalPrice,
  });
}

class CouponService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AppliedCoupon> validateCoupon({
    required String code,
    required String salonId,
    required double totalPrice,
  }) async {
    final couponCode = code.trim().toUpperCase();

    if (couponCode.isEmpty) {
      throw Exception('اكتبي كود الخصم');
    }

    final couponDoc = await _firestore
        .collection('coupons')
        .doc(couponCode)
        .get();

    if (!couponDoc.exists) {
      throw Exception('كود الخصم غير صحيح');
    }

    final data = couponDoc.data()!;

    final isActive = data['isActive'] == true;
    if (!isActive) {
      throw Exception('كود الخصم غير مفعل');
    }

    final couponSalonId = data['salonId']?.toString() ?? 'all';
    if (couponSalonId != 'all' && couponSalonId != salonId) {
      throw Exception('هذا الكوبون غير متاح لهذا الصالون');
    }

    final expiresAt = data['expiresAt'];
    if (expiresAt is Timestamp) {
      if (expiresAt.toDate().isBefore(DateTime.now())) {
        throw Exception('انتهت صلاحية كود الخصم');
      }
    }

    final minOrderAmount = (data['minOrderAmount'] as num?)?.toDouble() ?? 0;
    if (totalPrice < minOrderAmount) {
      throw Exception('الحد الأدنى لاستخدام الكوبون هو $minOrderAmount ر.س');
    }

    final usageLimit = (data['usageLimit'] as num?)?.toInt() ?? 0;
    final usedCount = (data['usedCount'] as num?)?.toInt() ?? 0;

    if (usageLimit > 0 && usedCount >= usageLimit) {
      throw Exception('تم استخدام هذا الكوبون بالكامل');
    }

    final discountType = data['discountType']?.toString() ?? 'percent';
    final discountValue = (data['discountValue'] as num?)?.toDouble() ?? 0;
    final maxDiscountAmount =
        (data['maxDiscountAmount'] as num?)?.toDouble() ?? 0;

    double discountAmount = 0;

    if (discountType == 'percent') {
      discountAmount = totalPrice * discountValue / 100;
    } else if (discountType == 'fixed') {
      discountAmount = discountValue;
    } else {
      throw Exception('نوع الخصم غير صحيح');
    }

    if (maxDiscountAmount > 0 && discountAmount > maxDiscountAmount) {
      discountAmount = maxDiscountAmount;
    }

    if (discountAmount > totalPrice) {
      discountAmount = totalPrice;
    }

    final finalPrice = totalPrice - discountAmount;

    return AppliedCoupon(
      code: couponCode,
      discountType: discountType,
      discountValue: discountValue,
      discountAmount: discountAmount,
      finalPrice: finalPrice,
    );
  }

  Future<void> increaseCouponUsage(String code) async {
    final couponCode = code.trim().toUpperCase();

    await _firestore.collection('coupons').doc(couponCode).update({
      'usedCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lamsa/features/customer_dashboard/model/booking_model.dart';


class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({
    super.key,
    required this.salonId,
  });

  final String salonId;

  static const String bookingsCollection = 'bookings'; // اسم كولكشن الحجوزات
  static const String usersCollection = 'users';      // اسم كولكشن العملاء

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final Map<String, Future<_CustomerInfo>> _customerFutures = {};

  Stream<List<BookingModel>> get _bookingsStream {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection(OwnerDashboardScreen.bookingsCollection)
        .where('salonId', isEqualTo: widget.salonId)
        .orderBy('appointmentAt', descending: false);

    // إذا تريدي عرض الطلبات الجديدة فقط، استخدمي هذا بدلًا من عرض كل الحالات:
    // query = query.where('status', isEqualTo: 'pending');

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<_CustomerInfo> _getCustomerInfo(String customerId) {
    debugPrint('CUSTOMER ID FROM BOOKING: $customerId');

    if (customerId.trim().isEmpty) {
      return Future.value(
        const _CustomerInfo(
          name: 'غير معروف',
          phone: 'غير متوفر',
        ),
      );
    }

    return _customerFutures.putIfAbsent(customerId, () async {
      final doc = await FirebaseFirestore.instance
          .collection(OwnerDashboardScreen.usersCollection)
          .doc(customerId)
          .get();

      // debugPrint('USER DOC EXISTS: ${doc.exists}');
      // debugPrint('USER DOC DATA: ${doc.data()}');

      if (!doc.exists) {
        return _CustomerInfo(
          name: 'مستخدم غير موجود',
          phone: 'غير متوفر',
        );
      }

      return _CustomerInfo.fromMap(doc.data(), customerId);
    });
  }

  Future<void> _updateBookingStatus({
    required BuildContext context,
    required String bookingId,
    required String status,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection(OwnerDashboardScreen.bookingsCollection)
          .doc(bookingId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'accepted' ? 'تم قبول الحجز' : 'تم رفض الحجز',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر تحديث الحجز: $e'),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _formatTime(DateTime date) {
    final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${hour12.toString().padLeft(2, '0')}:$minute $period';
  }

  String _receiptText(String? receipt) {
    final value = receipt?.trim();

    if (value == null || value.isEmpty) {
      return 'غير متوفر';
    }

    return value;
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      case 'pending':
        return 'بانتظار المراجعة';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'مرحبًا أيها المالك 👋',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: StreamBuilder<List<BookingModel>>(
                  stream: _bookingsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'حدث خطأ أثناء تحميل الحجوزات:\n${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final bookings = snapshot.data ?? const <BookingModel>[];

                    return Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.pink.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'عدد طلبات الحجز: ${bookings.length}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        if (bookings.isEmpty)
                          const Expanded(
                            child: Center(
                              child: Text(
                                'لا توجد طلبات حجز حاليًا',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.builder(
                              itemCount: bookings.length,
                              itemBuilder: (context, index) {
                                final booking = bookings[index];

                                return FutureBuilder<_CustomerInfo>(
                                  future: _getCustomerInfo(booking.customerId),
                                  builder: (context, customerSnapshot) {
                                    if (customerSnapshot.connectionState == ConnectionState.waiting) {
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Text(
                                            'الاسم: جاري التحميل...',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      );
                                    }
                                    if (customerSnapshot.hasError) {
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Text(
                                            'خطأ في تحميل بيانات العميل:\n${customerSnapshot.error}',
                                            style: const TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      );
                                    }
                                    final customer = customerSnapshot.data ??
                                        const _CustomerInfo(
                                          name: 'غير معروف',
                                          phone: 'غير متوفر',
                                        );

                                    final isPending =
                                        booking.status == 'pending';

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'الاسم: ${customer.name}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),

                                            const SizedBox(height: 6),

                                            Text(
                                              'التاريخ: ${_formatDate(booking.appointmentAt)}',
                                            ),
                                            Text(
                                              'الوقت: ${_formatTime(booking.appointmentAt)}',
                                            ),

                                            const SizedBox(height: 6),

                                            Text(
                                              'رقم الإيصال البنكي: ${_receiptText(booking.bankReceiptNumber)}',
                                              style: const TextStyle(
                                                color: Colors.blue,
                                              ),
                                            ),

                                            // const SizedBox(height: 12),
                                            //
                                            // Text(
                                            //   'رقم الجوال: ${customer.phone}',
                                            //   style: const TextStyle(
                                            //     color: Colors.blue,
                                            //   ),
                                            // ),

                                            const SizedBox(height: 12),

                                            Text(
                                              'الحالة: ${_statusLabel(booking.status)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),

                                            const SizedBox(height: 12),

                                            Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment.start,
                                              children: [
                                                ElevatedButton(
                                                  onPressed: isPending
                                                      ? () {
                                                    _updateBookingStatus(
                                                      context: context,
                                                      bookingId:
                                                      booking.id,
                                                      status: 'accepted',
                                                    );
                                                  }
                                                      : null,
                                                  style:
                                                  ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                    Colors.green,
                                                  ),
                                                  child: const Text(
                                                    'قبول',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),

                                                const SizedBox(width: 10),

                                                ElevatedButton(
                                                  onPressed: isPending
                                                      ? () {
                                                    _updateBookingStatus(
                                                      context: context,
                                                      bookingId:
                                                      booking.id,
                                                      status: 'rejected',
                                                    );
                                                  }
                                                      : null,
                                                  style:
                                                  ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                  ),
                                                  child: const Text(
                                                    'رفض',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerInfo {
  final String name;
  final String phone;

  const _CustomerInfo({
    required this.name,
    required this.phone,
  });

  factory _CustomerInfo.fromMap(
      Map<String, dynamic>? map,
      String fallbackId,
      ) {
    if (map == null) {
      return _CustomerInfo(
        name: fallbackId,
        phone: 'غير متوفر',
      );
    }

    return _CustomerInfo(
      name: map['name'] as String? ??
          map['fullName'] as String? ??
          map['username'] as String? ??
          fallbackId,
      phone: map['phone'] as String? ??
          map['phoneNumber'] as String? ??
          'غير متوفر',
    );
  }
}
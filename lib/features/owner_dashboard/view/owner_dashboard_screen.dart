import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lamsa/features/customer_dashboard/model/booking_model.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({
    super.key,
    required this.salonId,
  });

  final String salonId;

  static const String bookingsCollection = 'bookings';
  static const String usersCollection = 'users';

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final Map<String, Future<_CustomerInfo>> _customerFutures = {};

  Stream<List<BookingModel>> get _bookingsStream {
    return FirebaseFirestore.instance
        .collection(OwnerDashboardScreen.bookingsCollection)
        .where('salonId', isEqualTo: widget.salonId)
        .where('status', isEqualTo: 'pending')
        .orderBy('appointmentAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<_CustomerInfo> _getCustomerInfo(String customerId) {
    if (customerId.trim().isEmpty) {
      return Future.value(
        const _CustomerInfo(name: 'غير معروف', phone: 'غير متوفر'),
      );
    }

    return _customerFutures.putIfAbsent(customerId, () async {
      final doc = await FirebaseFirestore.instance
          .collection(OwnerDashboardScreen.usersCollection)
          .doc(customerId)
          .get();

      if (!doc.exists) {
        return const _CustomerInfo(
          name: 'مستخدم غير موجود',
          phone: 'غير متوفر',
        );
      }

      return _CustomerInfo.fromMap(doc.data(), customerId);
    });
  }

  Future<void> _updateBookingStatus({
    required BuildContext context,
    required BookingModel booking,
    required String status,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': booking.customerId,
        'bookingId': booking.id,
        'title': status == 'accepted' ? 'تم قبول الحجز' : 'تم رفض الحجز',
        'body': status == 'accepted'
            ? 'تم قبول حجزك بنجاح 🎉'
            : 'نعتذر، تم رفض حجزك',
        'status': status,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection(OwnerDashboardScreen.bookingsCollection)
          .doc(booking.id)
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
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر تحديث الحجز: $e'),
          behavior: SnackBarBehavior.floating,
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
    if (value == null || value.isEmpty) return 'غير متوفر';
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF7FA),
        body: SafeArea(
          child: StreamBuilder<List<BookingModel>>(
            stream: _bookingsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'حدث خطأ أثناء تحميل الحجوزات:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final bookings = snapshot.data ?? const <BookingModel>[];

              return Column(
                children: [
                  _HeaderCard(count: bookings.length),
                  const SizedBox(height: 12),

                  Expanded(
                    child: bookings.isEmpty
                        ? const _EmptyBookings()
                        : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: bookings.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final booking = bookings[index];

                        return FutureBuilder<_CustomerInfo>(
                          future: _getCustomerInfo(booking.customerId),
                          builder: (context, customerSnapshot) {
                            if (customerSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const _LoadingBookingCard();
                            }

                            final customer = customerSnapshot.data ??
                                const _CustomerInfo(
                                  name: 'غير معروف',
                                  phone: 'غير متوفر',
                                );

                            return _BookingCard(
                              booking: booking,
                              customer: customer,
                              date: _formatDate(booking.appointmentAt),
                              time: _formatTime(booking.appointmentAt),
                              receipt:
                              _receiptText(booking.bankReceiptNumber),
                              onAccept: () {
                                _updateBookingStatus(
                                  context: context,
                                  booking: booking,
                                  status: 'accepted',
                                );
                              },
                              onReject: () {
                                _updateBookingStatus(
                                  context: context,
                                  booking: booking,
                                  status: 'rejected',
                                );
                              },
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
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.pink.shade300,
            Colors.pink.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.85),
            child: Icon(
              Icons.storefront,
              color: Colors.pink.shade400,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مرحبًا أيها المالك 👋',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'طلبات بانتظار المراجعة: $count',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.customer,
    required this.date,
    required this.time,
    required this.receipt,
    required this.onAccept,
    required this.onReject,
  });

  final BookingModel booking;
  final _CustomerInfo customer;
  final String date;
  final String time;
  final String receipt;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.pink.shade50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.pink.shade50,
                child: Icon(Icons.person, color: Colors.pink.shade300),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  customer.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'قيد المراجعة',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Text(
            'الخدمات',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: booking.selectedServices.map((service) {
              return Chip(
                label: Text(service),
                backgroundColor: Colors.pink.shade50,
                side: BorderSide.none,
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          _InfoRow(icon: Icons.calendar_today, title: 'التاريخ', value: date),
          _InfoRow(icon: Icons.access_time, title: 'الوقت', value: time),
          _InfoRow(
            icon: Icons.payments,
            title: 'السعر الإجمالي',
            value: '${booking.totalPrice} ريال',
          ),
          _InfoRow(
            icon: Icons.receipt_long,
            title: 'رقم الإيصال البنكي',
            value: receipt,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text(
                    'قبول',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text(
                    'رفض',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(icon, size: 19, color: Colors.pink.shade300),
          const SizedBox(width: 8),
          Text(
            '$title: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBookingCard extends StatelessWidget {
  const _LoadingBookingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyBookings extends StatelessWidget {
  const _EmptyBookings();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 72,
            color: Colors.pink.shade100,
          ),
          const SizedBox(height: 12),
          const Text(
            'لا توجد طلبات حجز حاليًا',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
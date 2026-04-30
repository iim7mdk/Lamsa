import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _myBookingsStream(String userId) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('customerId', isEqualTo: userId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // appBar: AppBar(
        //   title: const Text('حجوزاتي'),
        //   centerTitle: true,
        //   automaticallyImplyLeading: false,
        // ),
        body: user == null
            ? const Center(
          child: Text(
            'يجب تسجيل الدخول لعرض الحجوزات',
            style: TextStyle(fontSize: 16),
          ),
        )
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _myBookingsStream(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'حدث خطأ أثناء تحميل الحجوزات:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            }

            final docs = [...(snapshot.data?.docs ?? [])];

            docs.sort((a, b) {
              final aDate = _toDate(a.data()['createdAt']) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final bDate = _toDate(b.data()['createdAt']) ??
                  DateTime.fromMillisecondsSinceEpoch(0);

              return bDate.compareTo(aDate);
            });

            if (docs.isEmpty) {
              return const _EmptyBookingsView();
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (context, index) {
                return const SizedBox(height: 12);
              },
              itemBuilder: (context, index) {
                final doc = docs[index];

                return _BookingCard(
                  bookingId: doc.id,
                  data: doc.data(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _BookingCard extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> data;

  const _BookingCard({
    required this.bookingId,
    required this.data,
  });

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  late Future<_BookingExtraData> _extraDataFuture;

  @override
  void initState() {
    super.initState();
    _extraDataFuture = _loadExtraData();
  }

  Future<_BookingExtraData> _loadExtraData() async {
    final salonId = widget.data['salonId']?.toString() ?? '';
    final serviceIds = _stringList(widget.data['serviceIds']);

    if (salonId.isEmpty) {
      return const _BookingExtraData(
        salonName: 'صالون غير معروف',
        serviceNames: [],
      );
    }

    final firestore = FirebaseFirestore.instance;

    String salonName = 'صالون';

    try {
      final salonDoc = await firestore.collection('salons').doc(salonId).get();

      final salonData = salonDoc.data();

      salonName = salonData?['title']?.toString() ??
          salonData?['name']?.toString() ??
          salonData?['salonName']?.toString() ??
          'صالون';
    } catch (_) {
      salonName = 'تعذر تحميل اسم الصالون';
    }

    final List<String> serviceNames = [];

    for (final serviceId in serviceIds) {
      try {
        final serviceDoc = await firestore
            .collection('salons')
            .doc(salonId)
            .collection('services')
            .doc(serviceId)
            .get();

        final serviceData = serviceDoc.data();

        final serviceName = serviceData?['name']?.toString() ??
            serviceData?['title']?.toString() ??
            serviceData?['serviceName']?.toString() ??
            serviceId;

        serviceNames.add(serviceName);
      } catch (_) {
        serviceNames.add(serviceId);
      }
    }

    return _BookingExtraData(
      salonName: salonName,
      serviceNames: serviceNames,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointmentAt = _toDate(widget.data['appointmentAt']);
    final createdAt = _toDate(widget.data['createdAt']);

    final totalPrice = _formatPrice(widget.data['totalPrice']);

    final bookingStatus = widget.data['status']?.toString() ?? 'pending';
    final paymentStatus = widget.data['paymentStatus']?.toString() ?? '';

    final bankReceiptNumber =
        widget.data['bankReceiptNumber']?.toString() ?? '';

    final selectedBankName =
        widget.data['selectedBankName']?.toString() ?? '';

    return FutureBuilder<_BookingExtraData>(
      future: _extraDataFuture,
      builder: (context, snapshot) {
        final extraData = snapshot.data;

        final salonName = extraData?.salonName ?? 'جاري تحميل الصالون...';

        final servicesText = snapshot.connectionState == ConnectionState.waiting
            ? 'جاري تحميل الخدمات...'
            : (extraData?.serviceNames.isNotEmpty == true
            ? extraData!.serviceNames.join('، ')
            : 'لا توجد خدمات');

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  salonName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                _InfoRow(
                  title: 'الخدمات',
                  value: servicesText,
                ),

                _InfoRow(
                  title: 'التاريخ',
                  value: appointmentAt == null
                      ? 'غير محدد'
                      : _formatDate(appointmentAt),
                ),

                _InfoRow(
                  title: 'الوقت',
                  value: appointmentAt == null
                      ? 'غير محدد'
                      : _formatTime(appointmentAt),
                ),

                _InfoRow(
                  title: 'الإجمالي',
                  value: totalPrice,
                ),

                _InfoRow(
                  title: 'حالة الحجز',
                  value: _bookingStatusText(bookingStatus),
                ),

                if (paymentStatus.isNotEmpty)
                  _InfoRow(
                    title: 'حالة الدفع',
                    value: _paymentStatusText(paymentStatus),
                  ),

                if (bankReceiptNumber.isNotEmpty)
                  _InfoRow(
                    title: 'رقم السند',
                    value: bankReceiptNumber,
                  ),

                if (selectedBankName.isNotEmpty)
                  _InfoRow(
                    title: 'البنك',
                    value: selectedBankName,
                  ),

                if (createdAt != null)
                  _InfoRow(
                    title: 'تاريخ إنشاء الحجز',
                    value: _formatDate(createdAt),
                  ),

                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'رقم الحجز: ${widget.bookingId}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const _InfoRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBookingsView extends StatelessWidget {
  const _EmptyBookingsView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 70,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'لا توجد حجوزات',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingExtraData {
  final String salonName;
  final List<String> serviceNames;

  const _BookingExtraData({
    required this.salonName,
    required this.serviceNames,
  });
}

DateTime? _toDate(dynamic value) {
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

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }

  return [];
}

String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

String _formatTime(DateTime date) {
  final period = date.hour >= 12 ? 'م' : 'ص';
  int hour = date.hour % 12;

  if (hour == 0) {
    hour = 12;
  }

  final minute = date.minute.toString().padLeft(2, '0');

  return '$hour:$minute $period';
}

String _formatPrice(dynamic value) {
  double price = 0;

  if (value is num) {
    price = value.toDouble();
  } else {
    price = double.tryParse(value?.toString() ?? '') ?? 0;
  }

  final hasDecimals = price % 1 != 0;

  return '${price.toStringAsFixed(hasDecimals ? 2 : 0)} ر.س';
}

String _bookingStatusText(String status) {
  switch (status) {
    case 'pending':
      return 'بانتظار تأكيد الصالون';
    case 'confirmed':
      return 'تم التأكيد';
    case 'completed':
      return 'مكتمل';
    case 'cancelled':
      return 'ملغي';
    default:
      return status;
  }
}

String _paymentStatusText(String status) {
  switch (status) {
    case 'pending':
      return 'قيد المراجعة';
    case 'paid':
      return 'مدفوع';
    case 'rejected':
      return 'مرفوض';
    case 'unpaid':
      return 'غير مدفوع';
    default:
      return status;
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lamsa/features/customer_dashboard/model/booking_model.dart';

class OwnerReportsPage extends StatelessWidget {
  const OwnerReportsPage({
    super.key,
    required this.salonId,
  });

  final String salonId;

  Stream<List<BookingModel>> get _bookingsStream {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('salonId', isEqualTo: salonId)
        .snapshots()
        .map((snapshot) {
      final bookings = snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.id, doc.data());
      }).toList();

      bookings.sort((a, b) => b.appointmentAt.compareTo(a.appointmentAt));
      return bookings;
    });
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد المراجعة';
      case 'accepted':
        return 'مقبولة';
      case 'rejected':
        return 'مرفوضة';
      case 'unpaid':
        return 'غير مدفوعة';
      case 'cancelled':
        return 'ملغية';
      default:
        return status;
    }
  }

  String _formatMoney(double value) {
    final hasDecimal = value % 1 != 0;
    return '${value.toStringAsFixed(hasDecimal ? 2 : 0)} ريال';
  }

  String _mostRequestedService(List<BookingModel> bookings) {
    final Map<String, int> servicesCount = {};

    for (final booking in bookings) {
      for (final service in booking.selectedServices) {
        final serviceName = service.toString().trim();
        if (serviceName.isEmpty) continue;

        servicesCount[serviceName] = (servicesCount[serviceName] ?? 0) + 1;
      }
    }

    if (servicesCount.isEmpty) {
      return 'لا توجد بيانات';
    }

    final sortedServices = servicesCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return '${sortedServices.first.key} (${sortedServices.first.value})';
  }

  Map<String, int> _countByStatus(List<BookingModel> bookings) {
    return {
      'pending': bookings.where((b) => b.status == 'pending').length,
      'accepted': bookings.where((b) => b.status == 'accepted').length,
      'rejected': bookings.where((b) => b.status == 'rejected').length,
      'unpaid': bookings.where((b) => b.status == 'unpaid').length,
      'cancelled': bookings.where((b) => b.status == 'cancelled').length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF7FA),
        appBar: AppBar(
          title: const Text('تقارير وإحصائيات'),
          centerTitle: true,
        ),
        body: StreamBuilder<List<BookingModel>>(
          stream: _bookingsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'حدث خطأ أثناء تحميل التقارير:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            final bookings = snapshot.data ?? [];

            final statusCount = _countByStatus(bookings);

            final totalBookings = bookings.length;
            final acceptedBookings = statusCount['accepted'] ?? 0;
            final rejectedBookings = statusCount['rejected'] ?? 0;
            final pendingBookings = statusCount['pending'] ?? 0;
            final unpaidBookings = statusCount['unpaid'] ?? 0;

            final todayBookings = bookings.where((booking) {
              return _isSameDate(booking.appointmentAt, now);
            }).length;

            final upcomingBookings = bookings.where((booking) {
              return booking.appointmentAt.isAfter(now);
            }).length;

            final totalIncome = bookings
                .where((booking) => booking.status == 'accepted')
                .fold<double>(
              0,
                  (sum, booking) => sum + booking.finalPrice,
            );

            final totalDiscount = bookings.fold<double>(
              0,
                  (sum, booking) => sum + booking.discountAmount,
            );

            final mostService = _mostRequestedService(bookings);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeaderReportCard(
                  totalBookings: totalBookings,
                  totalIncome: _formatMoney(totalIncome),
                ),

                const SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: [
                    _StatCard(
                      title: 'كل الحجوزات',
                      value: '$totalBookings',
                      icon: Icons.event_note,
                      color: Colors.pink,
                    ),
                    _StatCard(
                      title: 'مقبولة',
                      value: '$acceptedBookings',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                    _StatCard(
                      title: 'مرفوضة',
                      value: '$rejectedBookings',
                      icon: Icons.cancel,
                      color: Colors.red,
                    ),
                    _StatCard(
                      title: 'قيد المراجعة',
                      value: '$pendingBookings',
                      icon: Icons.pending_actions,
                      color: Colors.orange,
                    ),
                    _StatCard(
                      title: 'غير مدفوعة',
                      value: '$unpaidBookings',
                      icon: Icons.payments_outlined,
                      color: Colors.blueGrey,
                    ),
                    _StatCard(
                      title: 'حجوزات اليوم',
                      value: '$todayBookings',
                      icon: Icons.today,
                      color: Colors.purple,
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                _InfoSection(
                  title: 'معلومات عامة',
                  children: [
                    _InfoTile(
                      icon: Icons.trending_up,
                      title: 'الحجوزات القادمة',
                      value: '$upcomingBookings',
                    ),
                    _InfoTile(
                      icon: Icons.attach_money,
                      title: 'إجمالي الدخل من الحجوزات المقبولة',
                      value: _formatMoney(totalIncome),
                    ),
                    _InfoTile(
                      icon: Icons.discount,
                      title: 'إجمالي الخصومات',
                      value: _formatMoney(totalDiscount),
                    ),
                    _InfoTile(
                      icon: Icons.star,
                      title: 'الخدمة الأكثر طلبًا',
                      value: mostService,
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                _InfoSection(
                  title: 'تفصيل الحالات',
                  children: statusCount.entries.map((entry) {
                    return _InfoTile(
                      icon: Icons.circle,
                      title: _statusText(entry.key),
                      value: '${entry.value}',
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeaderReportCard extends StatelessWidget {
  const _HeaderReportCard({
    required this.totalBookings,
    required this.totalIncome,
  });

  final int totalBookings;
  final String totalIncome;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.pink.shade300,
            Colors.pink.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
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
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.9),
            child: Icon(
              Icons.analytics,
              color: Colors.pink.shade400,
              size: 32,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تقارير الصالون',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'عدد الحجوزات: $totalBookings',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'إجمالي الدخل: $totalIncome',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(
                icon,
                color: color,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.pink.shade50,
        child: Icon(
          icon,
          color: Colors.pink.shade300,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
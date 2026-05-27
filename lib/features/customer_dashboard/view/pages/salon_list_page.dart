import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lamsa/features/owner_dashboard/model/bank_account_model.dart';
import 'package:lamsa/features/owner_dashboard/model/salon_model.dart';
import 'package:lamsa/features/owner_dashboard/model/service_model.dart';
import '../widgets/salon_card.dart';
import 'package:flutter/services.dart';


class SalonListPage extends StatelessWidget {
  const SalonListPage({super.key});

  Future<List<SalonModel>> _getSalonsFromFirestore() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('salons')
          .where('status', isEqualTo: 'approved')
          .where('isVerified', isEqualTo: true)
          .get();

      return Future.wait(querySnapshot.docs.map((doc) async {
        final data = doc.data();

        final servicesQuerySnapshot = await FirebaseFirestore.instance
            .collection('salons')
            .doc(doc.id)
            .collection('services')
            .get();

        final bankAccountsQuerySnapshot = await FirebaseFirestore.instance
            .collection('salons')
            .doc(doc.id)
            .collection('bank_accounts')
            .get();

        final servicesList = servicesQuerySnapshot.docs
            .map((serviceDoc) => Service.fromMap(
          serviceDoc.id,
          serviceDoc.data(),
        ))
            .toList();

        final bankAccountsList = bankAccountsQuerySnapshot.docs
            .map((accountDoc) => BankAccount.fromMap(
          accountDoc.id,
          accountDoc.data(),
        ))
            .toList();

        return SalonModel(
          id: doc.id,
          salonName: data['salonName']?.toString() ?? '',
          phone: data['phone']?.toString() ?? '',
          email: data['email']?.toString() ?? '',
          location: data['location']?.toString() ?? '',
          workingHours: data['workingHours']?.toString() ?? '',
          ownerUid: data['ownerUid']?.toString() ?? '',
          status: data['status']?.toString() ?? 'pending',
          isVerified: data['isVerified'] == true,
          services: servicesList,
          bankAccounts: bankAccountsList,
        );
      }).toList());
    } catch (e) {
      debugPrint('Error loading salons data: $e');
      throw Exception('حدث خطأ أثناء تحميل البيانات');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: FutureBuilder<List<SalonModel>>(
        future: _getSalonsFromFirestore(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _LoadingView(theme: theme);
          }

          if (snapshot.hasError) {
            return _ErrorView(
              message: snapshot.error.toString(),
            );
          }

          final salons = snapshot.data ?? [];

          if (salons.isEmpty) {
            return const _EmptyView();
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _getSalonsFromFirestore();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _HeaderCard(
                  count: salons.length,
                ),

                const SizedBox(height: 14),

                const _CouponPromoCard(),

                const SizedBox(height: 16),

                Text(
                  'الصوالين المتاحة',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                ...salons.map(
                      (salon) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SalonCard(salon: salon),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.72),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.spa,
              color: Colors.white,
              size: 34,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اختاري صالونك المفضل',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'يوجد $count صالون موثق ومتاح للحجز',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
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

class _CouponPromoCard extends StatelessWidget {
  const _CouponPromoCard();

  static const String couponCode = 'LAMSA20';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () async {
          await Clipboard.setData(
            const ClipboardData(text: couponCode),
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم نسخ كود الخصم LAMSA20'),
              ),
            );
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.secondary,
                theme.colorScheme.primary,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.20),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: -18,
                top: -18,
                child: Icon(
                  Icons.local_offer,
                  size: 90,
                  color: Colors.white.withOpacity(0.10),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.discount_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'خصم خاص لكِ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'استخدمي الكود عند الحجز واحصلي على عرض مميز',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.90),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                couponCode,
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.copy,
                                color: theme.colorScheme.primary,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({
    required this.theme,
  });

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: theme.colorScheme.primary,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 44,
                  color: Colors.red,
                ),
                const SizedBox(height: 12),
                const Text(
                  'حدث خطأ أثناء تحميل الصوالين',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.store_mall_directory_outlined,
                  size: 52,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                const Text(
                  'لا توجد صالونات حالياً',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'سيتم عرض الصوالين بعد اعتمادها من الإدارة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
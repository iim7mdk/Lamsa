import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lamsa/features/owner_dashboard/model/bank_account_model.dart';
import 'package:lamsa/features/owner_dashboard/model/salon_model.dart';
import 'package:lamsa/features/owner_dashboard/model/service_model.dart';
import '../widgets/salon_card.dart';
import 'package:flutter/services.dart';


class SalonListPage extends StatefulWidget {
  const SalonListPage({super.key});

  @override
  State<SalonListPage> createState() => _SalonListPageState();
}

class _SalonListPageState extends State<SalonListPage> {
  late Future<List<SalonModel>> _salonsFuture;

  final TextEditingController _searchController = TextEditingController();

  String _selectedLocation = 'الكل';
  String _selectedService = 'الكل';
  String _selectedSort = 'بدون ترتيب';

  @override
  void initState() {
    super.initState();
    _salonsFuture = _getSalonsFromFirestore();

    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
            .map(
              (serviceDoc) => Service.fromMap(
            serviceDoc.id,
            serviceDoc.data(),
          ),
        )
            .toList();

        final bankAccountsList = bankAccountsQuerySnapshot.docs
            .map(
              (accountDoc) => BankAccount.fromMap(
            accountDoc.id,
            accountDoc.data(),
          ),
        )
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

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _matchesFilters(
      SalonModel salon,
      String selectedLocation,
      String selectedService,
      ) {
    final searchText = _normalize(_searchController.text);

    final salonName = _normalize(salon.salonName);
    final location = _normalize(salon.location);

    final servicesText = _normalize(
      salon.services.map((service) => service.name).join(' '),
    );

    final matchesSearch = searchText.isEmpty ||
        salonName.contains(searchText) ||
        location.contains(searchText) ||
        servicesText.contains(searchText);

    final matchesLocation = selectedLocation == 'الكل' ||
        salon.location.trim() == selectedLocation;

    final matchesService = selectedService == 'الكل' ||
        salon.services.any((service) => service.name.trim() == selectedService);

    return matchesSearch && matchesLocation && matchesService;
  }

  void _sortSalons(List<SalonModel> salons) {
    if (_selectedSort == 'أبجديًا') {
      salons.sort(
            (a, b) => _normalize(a.salonName).compareTo(_normalize(b.salonName)),
      );
    } else if (_selectedSort == 'الأكثر خدمات') {
      salons.sort((a, b) => b.services.length.compareTo(a.services.length));
    } else if (_selectedSort == 'الأقل خدمات') {
      salons.sort((a, b) => a.services.length.compareTo(b.services.length));
    }
  }

  Future<void> _refreshSalons() async {
    final future = _getSalonsFromFirestore();

    setState(() {
      _salonsFuture = future;
    });

    await future;
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _selectedLocation = 'الكل';
      _selectedService = 'الكل';
      _selectedSort = 'بدون ترتيب';
    });
  }

  String _safeValue(String selectedValue, List<String> items) {
    if (items.contains(selectedValue)) {
      return selectedValue;
    }
    return 'الكل';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: FutureBuilder<List<SalonModel>>(
        future: _salonsFuture,
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

          final locations = salons
              .map((salon) => salon.location.trim())
              .where((location) => location.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

          final services = salons
              .expand((salon) => salon.services)
              .map((service) => service.name.trim())
              .where((serviceName) => serviceName.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

          final locationItems = ['الكل', ...locations];
          final serviceItems = ['الكل', ...services];

          final safeLocation = _safeValue(_selectedLocation, locationItems);
          final safeService = _safeValue(_selectedService, serviceItems);

          final filteredSalons = salons
              .where(
                (salon) => _matchesFilters(
              salon,
              safeLocation,
              safeService,
            ),
          )
              .toList();

          _sortSalons(filteredSalons);

          return RefreshIndicator(
            onRefresh: _refreshSalons,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _HeaderCard(
                  count: filteredSalons.length,
                ),

                const SizedBox(height: 14),

                const _CouponPromoCard(),

                const SizedBox(height: 16),

                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحثي باسم الصالون أو الخدمة أو الموقع',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    filled: true,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: safeLocation,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'الموقع',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        items: locationItems
                            .map(
                              (location) => DropdownMenuItem(
                            value: location,
                            child: Text(location),
                          ),
                        )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedLocation = value ?? 'الكل';
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: safeService,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'الخدمة',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        items: serviceItems
                            .map(
                              (service) => DropdownMenuItem(
                            value: service,
                            child: Text(service),
                          ),
                        )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedService = value ?? 'الكل';
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSort,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'الترتيب',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'بدون ترتيب',
                            child: Text('بدون ترتيب'),
                          ),
                          DropdownMenuItem(
                            value: 'أبجديًا',
                            child: Text('أبجديًا'),
                          ),
                          DropdownMenuItem(
                            value: 'الأكثر خدمات',
                            child: Text('الأكثر خدمات'),
                          ),
                          DropdownMenuItem(
                            value: 'الأقل خدمات',
                            child: Text('الأقل خدمات'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSort = value ?? 'بدون ترتيب';
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 10),

                    OutlinedButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('مسح'),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Text(
                  'الصوالين المتاحة',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'عدد النتائج: ${filteredSalons.length}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 10),

                if (filteredSalons.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 44,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'لا توجد نتائج مطابقة',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'جرّبي تغيير كلمة البحث أو الفلترة',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filteredSalons.map(
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
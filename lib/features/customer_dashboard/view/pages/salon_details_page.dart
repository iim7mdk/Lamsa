import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lamsa/features/customer_dashboard/view/widgets/comments_and_rating_section.dart';
import 'package:lamsa/features/owner_dashboard/model/salon_model.dart';

import 'booking_page.dart';

class SalonDetailsPage extends StatelessWidget {
  final SalonModel salon;

  const SalonDetailsPage({
    super.key,
    required this.salon,
  });

  @override
  Widget build(BuildContext context) {
    final hasServices = salon.services.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            salon.salonName.isEmpty ? 'تفاصيل الصالون' : salon.salonName,
          ),
          centerTitle: true,
        ),
        bottomNavigationBar: _BottomBookingBar(
          enabled: hasServices,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingPage(
                  salonId: salon.id,
                  salonTitle: salon.salonName,
                  services: salon.services,
                ),
              ),
            );
          },
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            _SalonHeroCard(salon: salon),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _QuickInfoCard(
                    icon: Icons.access_time,
                    title: 'ساعات العمل',
                    value: salon.workingHours.isEmpty
                        ? 'غير متوفر'
                        : salon.workingHours,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickInfoCard(
                    icon: Icons.room_service_outlined,
                    title: 'عدد الخدمات',
                    value: '${salon.services.length} خدمة',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            _SectionTitle(
              title: 'معلومات التواصل',
              subtitle: 'بيانات الصالون الأساسية',
              icon: Icons.info_outline,
            ),
            const SizedBox(height: 10),

            _DetailsCard(
              children: [
                _DetailsLine(
                  icon: Icons.location_on_outlined,
                  title: 'الموقع',
                  value: salon.location.isEmpty ? 'غير متوفر' : salon.location,
                ),
                _DetailsLine(
                  icon: Icons.phone_outlined,
                  title: 'الجوال',
                  value: salon.phone.isEmpty ? 'غير متوفر' : salon.phone,
                  canCopy: salon.phone.isNotEmpty,
                ),
                if (salon.email.isNotEmpty)
                  _DetailsLine(
                    icon: Icons.email_outlined,
                    title: 'البريد الإلكتروني',
                    value: salon.email,
                    canCopy: true,
                  ),
              ],
            ),

            const SizedBox(height: 22),

            _SectionTitle(
              title: 'الخدمات المتاحة',
              subtitle: 'اختاري الخدمة المناسبة قبل الحجز',
              icon: Icons.content_cut,
            ),
            const SizedBox(height: 10),

            if (salon.services.isEmpty)
              const _StateCard(
                icon: Icons.content_cut_outlined,
                title: 'لا توجد خدمات حالياً',
                message: 'لا يمكن الحجز حتى يضيف الصالون خدماته.',
              )
            else
              ...salon.services.map(
                    (service) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ServiceCard(service: service),
                ),
              ),

            const SizedBox(height: 22),

            _SectionTitle(
              title: 'الحسابات البنكية',
              subtitle: 'تظهر لكِ عند الدفع بالحوالة البنكية',
              icon: Icons.account_balance_outlined,
            ),
            const SizedBox(height: 10),

            if (salon.bankAccounts.isEmpty)
              const _StateCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'لا توجد حسابات بنكية',
                message: 'سيتم عرض الحساب البنكي عند إضافته من مالكة الصالون.',
              )
            else
              ...salon.bankAccounts.map(
                    (account) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BankAccountCard(account: account),
                ),
              ),

            const SizedBox(height: 22),

            CommentsAndRatingSection(
              salonId: salon.id,
            ),
          ],
        ),
      ),
    );
  }
}

class _SalonHeroCard extends StatelessWidget {
  final SalonModel salon;

  const _SalonHeroCard({
    required this.salon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.72),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -24,
            bottom: -28,
            child: Icon(
              Icons.spa,
              size: 135,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                  ),
                ),
                child: const Icon(
                  Icons.spa,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                salon.salonName.isEmpty ? 'صالون بدون اسم' : salon.salonName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    salon.isVerified ? 'صالون موثق' : 'غير موثق',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (salon.location.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white,
                        size: 17,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          salon.location,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _QuickInfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final List<Widget> children;

  const _DetailsCard({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: children,
        ),
      ),
    );
  }
}

class _DetailsLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool canCopy;

  const _DetailsLine({
    required this.icon,
    required this.title,
    required this.value,
    this.canCopy = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.35,
              ),
            ),
          ),
          if (canCopy)
            IconButton(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: value),
                );

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم النسخ')),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              tooltip: 'نسخ',
            ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final dynamic service;

  const _ServiceCard({
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final name = service.name?.toString() ?? 'خدمة بدون اسم';
    final rawPrice = service.price;
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.content_cut,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: const Text('خدمة متاحة للحجز'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            '${price.toStringAsFixed(price % 1 == 0 ? 0 : 2)} ر.س',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _BankAccountCard extends StatelessWidget {
  final dynamic account;

  const _BankAccountCard({
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bankName = account.bankName?.toString() ?? 'بنك غير محدد';
    final accountHolder = account.accountHolder?.toString() ?? '';
    final accountNumber = account.accountNumber?.toString() ?? '';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.account_balance,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bankName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (accountHolder.isNotEmpty)
                    Text(
                      accountHolder,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12.5,
                      ),
                    ),
                  if (accountNumber.isNotEmpty)
                    Text(
                      accountNumber,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12.5,
                      ),
                    ),
                ],
              ),
            ),
            if (accountNumber.isNotEmpty)
              IconButton(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: accountNumber),
                  );

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ رقم الحساب')),
                  );
                },
                icon: const Icon(Icons.copy, size: 19),
                tooltip: 'نسخ رقم الحساب',
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomBookingBar extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _BottomBookingBar({
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: enabled ? onPressed : null,
            icon: const Icon(Icons.calendar_month),
            label: Text(
              enabled ? 'احجزي الآن' : 'لا توجد خدمات للحجز',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              icon,
              size: 46,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
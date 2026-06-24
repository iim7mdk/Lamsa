import 'package:flutter/material.dart';
import 'package:lamsa/features/owner_dashboard/view/owner_bookings_report_page.dart';

class OwnerMenuPage extends StatelessWidget {
  const OwnerMenuPage({
    super.key,
    required this.salonId,
  });

  final String salonId;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 10),

          Text(
            'إدارة الصالون',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'اختاري العملية التي تريدين تنفيذها',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 20),

          _MenuButton(
            icon: Icons.event_note,
            title: 'عرض الحجوزات',
            subtitle: 'فلترة حسب المقبولة، المرفوضة، التاريخ، واليوم',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OwnerBookingsReportPage(
                    salonId: salonId,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          _MenuButton(
            icon: Icons.design_services,
            title: 'إدارة الخدمات',
            subtitle: 'يمكن ربطها لاحقًا بصفحة الخدمات',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('سيتم ربط صفحة إدارة الخدمات لاحقًا'),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          _MenuButton(
            icon: Icons.account_balance,
            title: 'إدارة الحسابات البنكية',
            subtitle: 'يمكن ربطها لاحقًا بصفحة الحسابات البنكية',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('سيتم ربط صفحة الحسابات البنكية لاحقًا'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.pink.shade50,
                child: Icon(
                  icon,
                  color: Colors.pink.shade300,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
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

                    const SizedBox(height: 5),

                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_ios, size: 17),
            ],
          ),
        ),
      ),
    );
  }
}
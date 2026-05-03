import 'package:flutter/material.dart';
import 'package:lamsa/features/owner_dashboard/view/owner_dashboard_screen.dart';
import 'package:lamsa/features/owner_dashboard/view/owner_profile_page.dart';

class OwnerNavigationScreen extends StatefulWidget {

  const OwnerNavigationScreen({
    super.key,
    required this.salonId,
  });

  final String salonId;

  @override
  State<OwnerNavigationScreen> createState() => _OwnerNavigationScreenState();
}

class _OwnerNavigationScreenState extends State<OwnerNavigationScreen> {

  int currentIndex = 0;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      OwnerDashboardScreen(
        salonId: widget.salonId,
      ),
      const OwnerProfileScreen(),
    ];
  }

  void changePage(int index){
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentIndex == 0 ? 'لوحة التحكم' : 'معلومات الصالون',
        ),
      ),
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: changePage,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [

          BottomNavigationBarItem(
            // icon: Icon(Icons.dashboard),
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
              label: "لوحة التحكم"
          ),

          BottomNavigationBarItem(
              // icon: Icon(Icons.person),
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "معلومات الصالون"
          ),

        ],
      ),
    );
  }
}
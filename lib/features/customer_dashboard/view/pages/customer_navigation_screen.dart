import 'package:flutter/material.dart';
import 'package:lamsa/features/customer_dashboard/view/pages/salon_list_page.dart';


class OwnerNavigationScreen extends StatefulWidget {
  const OwnerNavigationScreen({super.key});

  @override
  State<OwnerNavigationScreen> createState() => _OwnerNavigationScreenState();
}

class _OwnerNavigationScreenState extends State<OwnerNavigationScreen> {

  int currentIndex = 0;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = const [
      SalonListPage(),
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
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "الصفحة الرئيسية"
          ),

        ],
      ),
    );
  }
}
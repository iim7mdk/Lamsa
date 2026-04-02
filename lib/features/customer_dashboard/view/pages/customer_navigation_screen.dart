import 'package:flutter/material.dart';
import 'package:lamsa/features/customer_dashboard/view/pages/profile_page.dart';
import 'package:lamsa/features/customer_dashboard/view/pages/salon_list_page.dart';
import 'package:lamsa/features/customer_dashboard/view/pages/my_bookings.dart';


class CustomerNavigationScreen extends StatefulWidget {
  const CustomerNavigationScreen({super.key});

  @override
  State<CustomerNavigationScreen> createState() => _CustomerNavigationScreenState();
}

class _CustomerNavigationScreenState extends State<CustomerNavigationScreen> {

  int currentIndex = 0;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = const [
      SalonListPage(),
      ProfilePage(),
      MyBookingsPage()
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
          currentIndex == 0 ? 'الصفحة الرئيسية' :
          currentIndex == 1 ? ' حجوزاتي' : 'الملف الشخصي',
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
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "الصفحة الرئيسية"
          ),


          BottomNavigationBarItem(
            // icon: Icon(Icons.dashboard),
              icon: Icon(Icons.book_outlined),
              activeIcon: Icon(Icons.book),
              label: "حجوزاتي"
          ),

          BottomNavigationBarItem(
            // icon: Icon(Icons.dashboard),
              icon: Icon(Icons.person_2_outlined),
              activeIcon: Icon(Icons.person_2),
              label: "الملف الشخصي"
          ),

        ],
      ),
    );
  }
}
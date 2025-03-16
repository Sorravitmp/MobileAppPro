import 'package:flutter/material.dart';
import 'transaction_screen.dart';
import 'login_screen.dart';  // นำเข้า LoginScreen
import 'income_screen.dart';  // นำเข้า IncomeScreen
import 'profile_screen.dart';  // นำเข้า ProfileScreen
import 'summary_screen.dart';  // นำเข้า SummaryScreen

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    TransactionScreen(),
    IncomeScreen(),  // เพิ่ม IncomeScreen ในรายการหน้าจอ
    SummaryScreen(), // Add SummaryScreen to the list of screens
  ];

  void _onTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // ฟังก์ชันสำหรับการออกจากระบบ
  void _logout(BuildContext context) {
    // ตัวอย่างการนำทางไปหน้า LoginScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Expense Tracker",
          style: TextStyle(color: Colors.black), // เปลี่ยนสีฟอนต์เป็นสีดำ
        ),
        backgroundColor: Colors.grey.shade300, // เปลี่ยนสีพื้นหลังเป็นสีเทาอ่อน
        actions: [
          // เพิ่มปุ่ม Profile
          IconButton(
            icon: ImageIcon(AssetImage('assets/icons/user.png'), color: Colors.black), // เปลี่ยนสีไอคอนเป็นสีดำ
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          // เพิ่มปุ่ม Logout
          IconButton(
            icon: ImageIcon(AssetImage('assets/icons/logout.png'), color: Colors.black), // เปลี่ยนสีไอคอนเป็นสีดำ
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade300, // เปลี่ยนสีพื้นหลังเป็นสีเทาอ่อน
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _currentIndex = 0;
                    });
                  },
                  icon: ImageIcon(
                    AssetImage('assets/icons/receipt.png'),
                    color: _currentIndex == 0 ? Colors.black : Colors.grey,
                  ),
                ),
                Text(
                  'Expense',
                  style: TextStyle(
                    color: _currentIndex == 0 ? Colors.black : Colors.grey,
                  ),
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _currentIndex = 1;
                    });
                  },
                  icon: Icon(
                    Icons.attach_money,
                    color: _currentIndex == 1 ? Colors.black : Colors.grey,
                  ),
                ),
                Text(
                  'Income',
                  style: TextStyle(
                    color: _currentIndex == 1 ? Colors.black : Colors.grey,
                  ),
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _currentIndex = 2;
                    });
                  },
                  icon: Icon(
                    Icons.bar_chart,
                    color: _currentIndex == 2 ? Colors.black : Colors.grey,
                  ),
                ),
                Text(
                  'Summary',
                  style: TextStyle(
                    color: _currentIndex == 2 ? Colors.black : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
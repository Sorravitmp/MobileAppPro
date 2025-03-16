import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SummaryScreen extends StatefulWidget {
  @override
  _SummaryScreenState createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  Map<String, double> _monthlyIncome = {};
  Map<String, double> _monthlyExpense = {};

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User not logged in");
      return;
    }

    String uid = user.uid;

    QuerySnapshot incomeSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('incomes')
        .get();

    QuerySnapshot expenseSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .get();

    Map<String, double> monthlyIncome = {};
    Map<String, double> monthlyExpense = {};

    for (var doc in incomeSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('timestamp') && data['timestamp'] != null) {
        String month = DateFormat('yyyy-MM').format((data['timestamp'] as Timestamp).toDate());
        double amount = data['amount'];
        if (monthlyIncome.containsKey(month)) {
          monthlyIncome[month] = monthlyIncome[month]! + amount;
        } else {
          monthlyIncome[month] = amount;
        }
      }
    }

    for (var doc in expenseSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('date') && data['date'] != null) {
        String month = DateFormat('yyyy-MM').format((data['date'] as Timestamp).toDate());
        double amount = data['amount'];
        if (monthlyExpense.containsKey(month)) {
          monthlyExpense[month] = monthlyExpense[month]! + amount;
        } else {
          monthlyExpense[month] = amount;
        }
      }
    }

    if (mounted) {
      setState(() {
        _monthlyIncome = monthlyIncome;
        _monthlyExpense = monthlyExpense;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> sortedMonths = _monthlyIncome.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Sort months from newest to oldest

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            "Summary",
            style: TextStyle(color: Colors.black), // เปลี่ยนสีฟอนต์เป็นสีดำ
          ),
        ),
        backgroundColor: Colors.white, // เปลี่ยนสีพื้นหลังเป็นสีขาว
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: sortedMonths.length,
          itemBuilder: (context, index) {
            String month = sortedMonths[index];
            double income = _monthlyIncome[month] ?? 0.0;
            double expense = _monthlyExpense[month] ?? 0.0;
            double balance = income - expense;

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8.0),
              elevation: 4.0,
              child: ListTile(
                title: Text(
                  month,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8.0),
                    Text(
                      'Income: ฿${income.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 16.0,
                      ),
                    ),
                    Text(
                      'Expense: ฿${expense.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 16.0,
                      ),
                    ),
                    Text(
                      'Summary: ฿${balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: balance < 0 ? Colors.red : Colors.green,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.0),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
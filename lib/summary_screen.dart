import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'locale_provider.dart'; // Import LocaleProvider
import 'package:provider/provider.dart';

class SummaryScreen extends StatefulWidget {
  @override
  _SummaryScreenState createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  Map<String, double> _dailyIncome = {};
  Map<String, double> _dailyExpense = {};
  Map<String, double> _monthlyIncome = {};
  Map<String, double> _monthlyExpense = {};
  Map<String, double> _yearlyIncome = {};
  Map<String, double> _yearlyExpense = {};
  String _selectedSummaryType = 'Daily'; // Default summary type

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

    Map<String, double> dailyIncome = {};
    Map<String, double> dailyExpense = {};
    Map<String, double> monthlyIncome = {};
    Map<String, double> monthlyExpense = {};
    Map<String, double> yearlyIncome = {};
    Map<String, double> yearlyExpense = {};

    for (var doc in incomeSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('timestamp') && data['timestamp'] != null) {
        DateTime date = (data['timestamp'] as Timestamp).toDate();
        String day = DateFormat('yyyy-MM-dd').format(date);
        String month = DateFormat('yyyy-MM').format(date);
        String year = DateFormat('yyyy').format(date);
        double amount = data['amount'];

        dailyIncome[day] = (dailyIncome[day] ?? 0) + amount;
        monthlyIncome[month] = (monthlyIncome[month] ?? 0) + amount;
        yearlyIncome[year] = (yearlyIncome[year] ?? 0) + amount;
      }
    }

    for (var doc in expenseSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('date') && data['date'] != null) {
        DateTime date = (data['date'] as Timestamp).toDate();
        String day = DateFormat('yyyy-MM-dd').format(date);
        String month = DateFormat('yyyy-MM').format(date);
        String year = DateFormat('yyyy').format(date);
        double amount = data['amount'];

        dailyExpense[day] = (dailyExpense[day] ?? 0) + amount;
        monthlyExpense[month] = (monthlyExpense[month] ?? 0) + amount;
        yearlyExpense[year] = (yearlyExpense[year] ?? 0) + amount;
      }
    }

    if (mounted) {
      setState(() {
        _dailyIncome = dailyIncome;
        _dailyExpense = dailyExpense;
        _monthlyIncome = monthlyIncome;
        _monthlyExpense = monthlyExpense;
        _yearlyIncome = yearlyIncome;
        _yearlyExpense = yearlyExpense;
      });
    }
  }

  Map<String, double> _getIncomeSummary() {
    switch (_selectedSummaryType) {
      case 'Monthly':
        return _monthlyIncome;
      case 'Yearly':
        return _yearlyIncome;
      default:
        return _dailyIncome;
    }
  }

  Map<String, double> _getExpenseSummary() {
    switch (_selectedSummaryType) {
      case 'Monthly':
        return _monthlyExpense;
      case 'Yearly':
        return _yearlyExpense;
      default:
        return _dailyExpense;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    Map<String, double> incomeSummary = _getIncomeSummary();
    Map<String, double> expenseSummary = _getExpenseSummary();

    List<String> sortedKeys = incomeSummary.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Sort keys from newest to oldest

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
        child: Column(
          children: [
            // Dropdown to select summary type
            DropdownButton<String>(
              value: _selectedSummaryType,
              items: ['Daily', 'Monthly', 'Yearly'].map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSummaryType = value;
                  });
                }
              },
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: sortedKeys.length,
                itemBuilder: (context, index) {
                  String key = sortedKeys[index];
                  double income = incomeSummary[key] ?? 0.0;
                  double expense = expenseSummary[key] ?? 0.0;
                  double balance = income - expense;

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 4.0,
                    child: ListTile(
                      title: Text(
                        key,
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
                            'Income: ${localeProvider.formatAmount(income)}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 16.0,
                            ),
                          ),
                          Text(
                            'Expense: ${localeProvider.formatAmount(expense)}',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 16.0,
                            ),
                          ),
                          Text(
                            'Summary: ${localeProvider.formatAmount(balance)}',
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
          ],
        ),
      ),
    );
  }
}
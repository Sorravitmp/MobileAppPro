import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'locale_provider.dart'; // Import LocaleProvider
import 'package:provider/provider.dart';

class TransactionScreen extends StatefulWidget {
  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  DateTime? _selectedDate; // Add a variable to store the selected date
  TimeOfDay? _selectedTime; // Add a variable to store the selected time

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _selectedTime = null; // Reset time when a new date is selected
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  DateTime _getFinalDateTime() {
    if (_selectedDate == null) {
      return DateTime.now(); // Use current date and time
    }
    if (_selectedTime == null) {
      return DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, DateTime.now().hour, DateTime.now().minute);
    }
    return DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute);
  }

  void _addTransaction() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User not logged in");
      return;
    }

    String uid = user.uid;

    if (_amountController.text.isEmpty || _categoryController.text.isEmpty || _selectedDate == null) return;

    try {
      double amount = double.parse(_amountController.text);
      String category = _categoryController.text;

      Map<String, dynamic> transactionData = {
        'amount': amount,
        'category': category,
        'date': Timestamp.fromDate(_getFinalDateTime()), // Use the final date and time
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .add(transactionData);

      _amountController.clear();
      _categoryController.clear();
      setState(() {
        _selectedDate = null; // Reset the selected date
        _selectedTime = null; // Reset the selected time
      });

      print("✅ Transaction added: $transactionData");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณากรอกจำนวนเงินให้ถูกต้อง'),
          backgroundColor: Colors.redAccent.withOpacity(0.8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _editTransaction(String id, Map<String, dynamic> transaction) async {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    double baseAmount = transaction['amount'] / localeProvider.conversionRate; // Convert to base currency
    _amountController.text = baseAmount.toStringAsFixed(2); // Display the base amount
    _categoryController.text = transaction['category'];
    DateTime existingDateTime = (transaction['date'] as Timestamp).toDate();
    _selectedDate = DateTime(existingDateTime.year, existingDateTime.month, existingDateTime.day);
    _selectedTime = TimeOfDay(hour: existingDateTime.hour, minute: existingDateTime.minute);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Transaction'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: "Amount (${localeProvider.currencySymbol})",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      prefixIcon: Icon(Icons.attach_money, color: Colors.black),
                    ),
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.black),
                    onChanged: (value) {
                      // Dynamically update the amount when the user edits it
                      if (value.isNotEmpty) {
                        double enteredAmount = double.tryParse(value) ?? 0.0;
                        double convertedAmount = enteredAmount * localeProvider.conversionRate;
                        _amountController.text = (convertedAmount / localeProvider.conversionRate).toStringAsFixed(2);
                      }
                    },
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      labelText: "Category",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      prefixIcon: Icon(Icons.category, color: Colors.black),
                    ),
                    style: TextStyle(color: Colors.black),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        _selectedDate != null
                            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                            : 'Select Date',
                        style: TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: Icon(Icons.calendar_today, color: Colors.black),
                        onPressed: () => _pickDate(context),
                      ),
                    ],
                  ),
                  if (_selectedDate != null)
                    Row(
                      children: [
                        Text(
                          _selectedTime != null
                              ? _selectedTime!.format(context)
                              : 'Select Time',
                          style: TextStyle(fontSize: 16),
                        ),
                        IconButton(
                          icon: Icon(Icons.access_time, color: Colors.black),
                          onPressed: () => _pickTime(context),
                        ),
                      ],
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      double amount = double.parse(_amountController.text) * localeProvider.conversionRate; // Convert to selected currency
                      String category = _categoryController.text;

                      Map<String, dynamic> updatedTransaction = {
                        'amount': amount,
                        'category': category,
                        'date': Timestamp.fromDate(_getFinalDateTime()), // Update the date and time
                      };

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser?.uid)
                          .collection('transactions')
                          .doc(id)
                          .update(updatedTransaction);

                      Navigator.of(context).pop();
                      _amountController.clear();
                      _categoryController.clear();
                      setState(() {
                        _selectedDate = null; // Reset the selected date
                        _selectedTime = null; // Reset the selected time
                      });

                      print("✅ Transaction updated: $updatedTransaction");
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('กรุณากรอกจำนวนเงินให้ถูกต้อง'),
                          backgroundColor: Colors.redAccent.withOpacity(0.8),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteTransaction(String id) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('transactions')
        .doc(id)
        .delete();

    print("❌ Expense deleted: $id");
  }

  void _showTransactionDetail(BuildContext context, String id, Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Expense Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category: ${transaction['category']}', style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),
                Text('Amount: ${transaction['amount']}', style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),
                Text('Date: ${transaction['date'] != null ? (transaction['date'] as Timestamp).toDate().toString() : 'No date'}', style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _editTransaction(id, transaction);
              },
              child: Text('Edit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTransaction(id);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            "Expense",
            style: TextStyle(color: Colors.black), // เปลี่ยนสีฟอนต์เป็นสีดำ
          ),
        ),
        backgroundColor: Colors.white, // เปลี่ยนสีพื้นหลังเป็นสีขาว
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection('transactions')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final transactions = snapshot.data!.docs;
                Map<String, List<DocumentSnapshot>> groupedTransactions = {};

                for (var transaction in transactions) {
                  var data = transaction.data() as Map<String, dynamic>;
                  if (data.containsKey('date') && data['date'] != null) {
                    String date = DateFormat('yyyy-MM-dd').format((data['date'] as Timestamp).toDate());
                    if (groupedTransactions[date] == null) {
                      groupedTransactions[date] = [];
                    }
                    groupedTransactions[date]!.add(transaction);
                  }
                }

                return ListView(
                  children: groupedTransactions.keys.map((date) {
                    return ExpansionTile(
                      title: Row(
                        children: [
                          Text(date),
                          SizedBox(width: 8),
                          Image.asset(
                            'assets/icons/updown.png',
                            height: 20,
                            width: 20,
                          ),
                        ],
                      ),
                      children: groupedTransactions[date]!.map((transaction) {
                        var data = transaction.data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text(data['category']),
                          subtitle: Text(
                            localeProvider.formatAmount(data['amount']),
                            style: TextStyle(color: Colors.red[700]), // Set expense amount to red
                          ),
                          trailing: Text(data['date'] != null
                              ? DateFormat('HH:mm').format((data['date'] as Timestamp).toDate())
                              : 'No time'),
                          onTap: () {
                            _showTransactionDetail(context, transaction.id, data);
                          },
                        );
                      }).toList(),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _amountController.clear();
          _categoryController.clear();
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Add Transaction'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: "Amount",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.attach_money, color: Colors.black),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Colors.black),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _categoryController,
                      decoration: InputDecoration(
                        labelText: "Spend on?",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.category, color: Colors.black),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      style: TextStyle(color: Colors.black),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          _selectedDate != null
                              ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                              : 'Select Date',
                          style: TextStyle(fontSize: 16),
                        ),
                        IconButton(
                          icon: Icon(Icons.calendar_today, color: Colors.black),
                          onPressed: () => _pickDate(context),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          _selectedTime != null
                              ? _selectedTime!.format(context)
                              : 'Select Time',
                          style: TextStyle(fontSize: 16),
                        ),
                        IconButton(
                          icon: Icon(Icons.access_time, color: Colors.black),
                          onPressed: () => _pickTime(context),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      _addTransaction();
                      Navigator.of(context).pop();
                    },
                    child: Text('Save'),
                  ),
                ],
              );
            },
          );
        },
        backgroundColor: Colors.black,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

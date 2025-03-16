import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TransactionScreen extends StatefulWidget {
  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  void _addTransaction() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User not logged in");
      return;
    }

    String uid = user.uid;

    if (_amountController.text.isEmpty || _categoryController.text.isEmpty) return;

    try {
      double amount = double.parse(_amountController.text);
      String category = _categoryController.text;

      Map<String, dynamic> transactionData = {
        'amount': amount,
        'category': category,
        'date': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .add(transactionData);

      _amountController.clear();
      _categoryController.clear();

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
    _amountController.text = transaction['amount'].toString();
    _categoryController.text = transaction['category'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: "Amount",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  prefixIcon: Icon(Icons.attach_money, color: Colors.black),
                ),
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.black),
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
                  double amount = double.parse(_amountController.text);
                  String category = _categoryController.text;

                  Map<String, dynamic> updatedTransaction = {
                    'amount': amount,
                    'category': category,
                    'date': transaction['date'],
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
                          subtitle: Text(data['amount'].toString()),
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

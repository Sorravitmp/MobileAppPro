import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'locale_provider.dart'; // Import LocaleProvider
import 'package:provider/provider.dart';

class IncomeScreen extends StatefulWidget {
  @override
  _IncomeScreenState createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _sourceController = TextEditingController();
  File? _receiptImage;
  DateTime? _selectedDate; // Add a variable to store the selected date
  TimeOfDay? _selectedTime; // Add a variable to store the selected time

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _receiptImage = File(pickedFile.path);
      });
    }
  }

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

  Future<String?> _uploadImage(File image) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance.ref().child('receipts/$fileName.jpg');
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  void _addIncome() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User not logged in");
      return;
    }

    String uid = user.uid;

    if (_amountController.text.isEmpty || _sourceController.text.isEmpty) return;

    try {
      double amount = double.parse(_amountController.text);
      String source = _sourceController.text;
      String? imageUrl;

      if (_receiptImage != null) {
        imageUrl = await _uploadImage(_receiptImage!);
      }

      Map<String, dynamic> incomeData = {
        'amount': amount,
        'source': source,
        'timestamp': Timestamp.fromDate(_getFinalDateTime()), // Use the final date and time
        'receiptUrl': imageUrl,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('incomes')
          .add(incomeData);

      _amountController.clear();
      _sourceController.clear();
      setState(() {
        _receiptImage = null;
        _selectedDate = null;
        _selectedTime = null; // Reset the selected date and time
      });

      print("✅ Income added: $incomeData");
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

  void _deleteIncome(String id) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('incomes')
        .doc(id)
        .delete();

    print("❌ Income deleted: $id");
  }

  void _showIncomeDetail(BuildContext context, String id, Map<String, dynamic> income) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Income Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Source: ${income['source']}', style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),
                Text('Amount: ${income['amount']}', style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),
                Text('Date: ${income['timestamp'] != null ? income['timestamp'].toDate().toString() : 'No date'}', style: TextStyle(fontSize: 18)),
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
                _deleteIncome(id);
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
            "Income",
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
                  .collection('incomes')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final incomes = snapshot.data!.docs;
                Map<String, List<DocumentSnapshot>> groupedIncomes = {};

                for (var income in incomes) {
                  var data = income.data() as Map<String, dynamic>;
                  if (data.containsKey('timestamp')) {
                    String date = DateFormat('yyyy-MM-dd').format(data['timestamp'].toDate());
                    if (groupedIncomes[date] == null) {
                      groupedIncomes[date] = [];
                    }
                    groupedIncomes[date]!.add(income);
                  }
                }

                return ListView(
                  children: groupedIncomes.keys.map((date) {
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
                      children: groupedIncomes[date]!.map((income) {
                        var data = income.data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text(data['source']),
                          subtitle: Text(
                            localeProvider.formatAmount(data['amount']),
                            style: TextStyle(color: Colors.green[700]), // Set income amount to green
                          ),
                          trailing: Text(
                            data['timestamp'] != null
                                ? DateFormat('HH:mm').format(data['timestamp'].toDate())
                                : 'No time',
                          ),
                          onTap: () {
                            _showIncomeDetail(context, income.id, data);
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
          _sourceController.clear();
          setState(() {
            _receiptImage = null;
            _selectedDate = null; // Reset the selected date
            _selectedTime = null; // Reset the selected time
          });
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Add Income'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: "Amount (${Provider.of<LocaleProvider>(context).currencySymbol})",
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
                      controller: _sourceController,
                      decoration: InputDecoration(
                        labelText: "Source",
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
                      _addIncome();
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
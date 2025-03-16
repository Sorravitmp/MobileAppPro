import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> insertTransaction(Map<String, dynamic> transaction) async {
    try {
      transaction['date'] = FieldValue.serverTimestamp(); // ใช้ Timestamp ของ Firestore
      await _db.collection('transactions').add(transaction);
      print("Transaction added successfully");
    } catch (e) {
      print("🔥 Error adding transaction: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    try {
      QuerySnapshot querySnapshot = await _db.collection('transactions').get();
      return querySnapshot.docs.map((doc) => {
        ...doc.data() as Map<String, dynamic>,
        'id': doc.id, // ดึง ID มาด้วย
      }).toList();
    } catch (e) {
      print("🔥 Error fetching transactions: $e");
      return [];
    }
  }
}
